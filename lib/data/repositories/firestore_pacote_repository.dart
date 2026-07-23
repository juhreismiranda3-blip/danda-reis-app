import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pacote.dart';
import '../../domain/repositories/pacote_repository.dart';

class FirestorePacoteRepository implements PacoteRepository {
  final FirebaseFirestore _firestore;

  FirestorePacoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _pacotesRef => _firestore.collection('pacotes');
  CollectionReference get _contratadosRef =>
      _firestore.collection('pacotes_contratados');
  CollectionReference get _aulasRef => _firestore.collection('aulas');

  @override
  Stream<List<Pacote>> get todosPacotes {
    return _pacotesRef.snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Pacote(
            id: doc.id,
            nome: data['nome'] as String,
            quantidadeAulas: data['quantidadeAulas'] as int,
            valor: (data['valor'] as num).toDouble(),
          );
        }).toList());
  }

  @override
  Future<void> criarPacote(Pacote pacote) async {
    await _pacotesRef.doc(pacote.id).set({
      'nome': pacote.nome,
      'quantidadeAulas': pacote.quantidadeAulas,
      'valor': pacote.valor,
    });
  }

  @override
  Future<void> removerPacote(String pacoteId) => _pacotesRef.doc(pacoteId).delete();

  @override
  Future<void> contratarPacote({
    required String alunaId,
    required String pacoteId,
    required DateTime validoAte,
  }) async {
    await _contratadosRef.add({
      'alunaId': alunaId,
      'pacoteId': pacoteId,
      'contratadoEm': Timestamp.fromDate(DateTime.now()),
      'validoAte': Timestamp.fromDate(validoAte),
    });
    await _firestore.collection('usuarios').doc(alunaId).update({
      'pacoteAtualId': pacoteId,
    });
  }

  @override
  Stream<SaldoPacote> saldoDe(String alunaId) async* {
    // Busca o pacote contratado vigente.
    final contratados = await _contratadosRef
        .where('alunaId', isEqualTo: alunaId)
        .orderBy('contratadoEm', descending: true)
        .limit(1)
        .get();

    if (contratados.docs.isEmpty) {
      yield const SaldoPacote(totalDoPacote: 0, utilizadas: 0);
      return;
    }

    final contratado = contratados.docs.first.data() as Map<String, dynamic>;
    final pacoteDoc = await _pacotesRef.doc(contratado['pacoteId'] as String).get();
    final total = (pacoteDoc.data() as Map<String, dynamic>)['quantidadeAulas'] as int;
    final contratadoEm = (contratado['contratadoEm'] as Timestamp).toDate();
    final validoAte = (contratado['validoAte'] as Timestamp).toDate();

    // Reage em tempo real às mudanças nas aulas da aluna dentro do período.
    yield* _aulasRef
        .where('alunaId', isEqualTo: alunaId)
        .where('origem', isEqualTo: 'pacote')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(contratadoEm))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(validoAte))
        .snapshots()
        .map((snap) {
      // Conta como "utilizada" qualquer aula que não esteja mais em aberto
      // como agendada futura, ou seja: concluída, falta, ou agendada já
      // passada. Aulas remarcadas não contam duas vezes (a nova aula que
      // a substitui já está incluída na consulta).
      final utilizadas = snap.docs.where((d) {
        final status = d['status'] as String;
        return status == 'concluida' || status == 'falta';
      }).length;
      return SaldoPacote(totalDoPacote: total, utilizadas: utilizadas);
    });
  }
}
