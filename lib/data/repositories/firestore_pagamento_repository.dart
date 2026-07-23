import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/aula.dart';
import '../../domain/entities/pagamento.dart';
import '../../domain/repositories/pagamento_repository.dart';

class FirestorePagamentoRepository implements PagamentoRepository {
  final FirebaseFirestore _firestore;

  FirestorePagamentoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _pagamentosRef => _firestore.collection('pagamentos');
  CollectionReference get _aulasRef => _firestore.collection('aulas');

  Pagamento _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pagamento(
      id: doc.id,
      alunaId: data['alunaId'] as String,
      valor: (data['valor'] as num).toDouble(),
      vencimento: (data['vencimento'] as Timestamp).toDate(),
      pagoEm: (data['pagoEm'] as Timestamp?)?.toDate(),
      observacao: data['observacao'] as String?,
      descricao: data['descricao'] as String?,
      valorAulasExtras: (data['valorAulasExtras'] as num?)?.toDouble() ?? 0,
      qtdAulasExtras: (data['qtdAulasExtras'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Stream<List<Pagamento>> pagamentosDaAluna(String alunaId) {
    return _pagamentosRef
        .where('alunaId', isEqualTo: alunaId)
        .orderBy('vencimento', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Stream<List<Pagamento>> todosPendentesOuAtrasados() {
    // Firestore não filtra por campo calculado (status), então trazemos
    // todos sem pagoEm e deixamos o cálculo de pendente/atrasado no cliente
    // (ver Pagamento.status, que compara com a data atual).
    return _pagamentosRef
        .where('pagoEm', isNull: true)
        .orderBy('vencimento')
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> cadastrarPagamento(Pagamento pagamento) async {
    await _pagamentosRef.doc(pagamento.id).set({
      'alunaId': pagamento.alunaId,
      'valor': pagamento.valor,
      'vencimento': Timestamp.fromDate(pagamento.vencimento),
      'pagoEm': pagamento.pagoEm != null ? Timestamp.fromDate(pagamento.pagoEm!) : null,
      'observacao': pagamento.observacao,
      'descricao': pagamento.descricao,
      'valorAulasExtras': pagamento.valorAulasExtras,
      'qtdAulasExtras': pagamento.qtdAulasExtras,
    });
  }

  @override
  Future<void> incluirAulaExtraNaMensalidade({
    required String alunaId,
    required double valorAula,
    String? aulaExtraId,
  }) async {
    // Procura a mensalidade em aberto (não paga) mais próxima do vencimento.
    final abertos = await _pagamentosRef
        .where('alunaId', isEqualTo: alunaId)
        .where('pagoEm', isNull: true)
        .orderBy('vencimento')
        .limit(1)
        .get();

    if (abertos.docs.isNotEmpty) {
      // Soma o valor da aula extra à mensalidade pendente existente.
      final ref = abertos.docs.first.reference;
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>;
        final valorAtual = (data['valor'] as num).toDouble();
        final extrasAtual = (data['valorAulasExtras'] as num?)?.toDouble() ?? 0;
        final qtdAtual = (data['qtdAulasExtras'] as num?)?.toInt() ?? 0;
        tx.update(ref, {
          'valor': valorAtual + valorAula,
          'valorAulasExtras': extrasAtual + valorAula,
          'qtdAulasExtras': qtdAtual + 1,
          if (aulaExtraId != null)
            'aulasExtrasIds': FieldValue.arrayUnion([aulaExtraId]),
        });
      });
    } else {
      // Não há mensalidade em aberto: cria uma cobrança para as aulas extras,
      // com vencimento no próximo dia 10.
      final agora = DateTime.now();
      final diaDez = DateTime(agora.year, agora.month, 10);
      final venc = diaDez.isAfter(agora)
          ? diaDez
          : DateTime(agora.year, agora.month + 1, 10);
      await _pagamentosRef.add({
        'alunaId': alunaId,
        'valor': valorAula,
        'vencimento': Timestamp.fromDate(venc),
        'pagoEm': null,
        'observacao': null,
        'descricao': 'Aulas extras',
        'valorAulasExtras': valorAula,
        'qtdAulasExtras': 1,
        if (aulaExtraId != null) 'aulasExtrasIds': [aulaExtraId],
      });
    }
    // NOTA: em produção, este ajuste de cobrança deve rodar numa Cloud
    // Function (mesma observação de comprarAulaExtra), já que as regras do
    // Firestore restringem a escrita em `pagamentos` à professora.
  }

  @override
  Future<void> editarPagamento(Pagamento pagamento) => cadastrarPagamento(pagamento);

  @override
  Future<void> cancelarPagamento(String pagamentoId) =>
      _pagamentosRef.doc(pagamentoId).delete();

  @override
  Future<void> darBaixaManual(String pagamentoId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _pagamentosRef.doc(pagamentoId);
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;

      tx.update(ref, {'pagoEm': Timestamp.fromDate(DateTime.now())});

      // Se este pagamento é de uma aula extra, ela some do estado
      // "aguardando pagamento" — ver comprarAulaExtra em AulaRepository,
      // que cria a aula já como 'agendada' e o pagamento vinculado.
      final aulaExtraId = data['aulaExtraId'] as String?;
      if (aulaExtraId != null) {
        final aulaSnap = await tx.get(_aulasRef.doc(aulaExtraId));
        if (aulaSnap.exists) {
          // A aula extra já nasce 'agendada'; aqui garantimos que ela não
          // fique num limbo caso o fluxo de UI marque como pendente antes
          // do pagamento. Ajuste conforme o campo de status real usado.
          tx.update(_aulasRef.doc(aulaExtraId), {
            'status': StatusAula.agendada.name,
          });
        }
      }
    });
  }
}
