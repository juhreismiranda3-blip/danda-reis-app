import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/aula.dart';
import '../../domain/entities/turma.dart';
import '../../domain/repositories/aula_repository.dart';
import '../../domain/repositories/turma_repository.dart';

class FirestoreAulaRepository implements AulaRepository {
  final FirebaseFirestore _firestore;
  final TurmaRepository _turmaRepository;

  /// Tempo que a professora tem para aprovar/recusar uma remarcação antes
  /// da vaga provisória expirar automaticamente (sugestão de melhoria
  /// combinada com a cliente).
  static const expiracaoSolicitacao = Duration(hours: 24);

  FirestoreAulaRepository({
    required TurmaRepository turmaRepository,
    FirebaseFirestore? firestore,
  })  : _turmaRepository = turmaRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _aulasRef => _firestore.collection('aulas');
  CollectionReference get _solicitacoesRef =>
      _firestore.collection('remarcacoes_pendentes');

  Aula _aulaFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Aula(
      id: doc.id,
      alunaId: data['alunaId'] as String,
      turmaId: data['turmaId'] as String,
      data: (data['data'] as Timestamp).toDate(),
      periodo: Periodo.values.byName(data['periodo'] as String),
      status: StatusAula.values.byName(data['status'] as String),
      origem: OrigemAula.values.byName(data['origem'] as String),
      aulaOriginalId: data['aulaOriginalId'] as String?,
    );
  }

  @override
  Stream<List<Aula>> aulasDaAluna(String alunaId, {required DateTime mesReferencia}) {
    final inicio = DateTime(mesReferencia.year, mesReferencia.month, 1);
    final fim = DateTime(mesReferencia.year, mesReferencia.month + 1, 1);
    return _aulasRef
        .where('alunaId', isEqualTo: alunaId)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .orderBy('data')
        .snapshots()
        .map((snap) => snap.docs.map(_aulaFromDoc).toList());
  }

  @override
  Stream<List<Aula>> todasAsAulas({required DateTime mesReferencia}) {
    final inicio = DateTime(mesReferencia.year, mesReferencia.month, 1);
    final fim = DateTime(mesReferencia.year, mesReferencia.month + 1, 1);
    return _aulasRef
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .orderBy('data')
        .snapshots()
        .map((snap) => snap.docs.map(_aulaFromDoc).toList());
  }

  @override
  Future<void> marcarPresenca(String aulaId, StatusAula status) async {
    // A máquina de estados garante que só se transiciona a partir de
    // 'agendada' — evita marcar presença numa aula já cancelada, por exemplo.
    await _firestore.runTransaction((tx) async {
      final ref = _aulasRef.doc(aulaId);
      final snap = await tx.get(ref);
      final atual = StatusAula.values.byName(snap['status'] as String);
      if (atual != StatusAula.agendada) {
        throw Exception('Só é possível marcar presença em aulas agendadas.');
      }
      tx.update(ref, {'status': status.name});
    });
  }

  @override
  Future<SolicitacaoRemarcacao> solicitarRemarcacao({
    required String alunaId,
    required String aulaOriginalId,
    required DateTime novaData,
    required Periodo novoPeriodo,
  }) async {
    // 1. Confirma que existe vaga e a reserva imediatamente, para que
    //    ela não seja "roubada" por outra aluna enquanto a professora
    //    não responde.
    final turma = await _turmaRepository.encontrarTurmaComVaga(
      dia: novaData,
      periodo: novoPeriodo,
    );
    if (turma == null) {
      throw NenhumaVagaDisponivelException(novoPeriodo);
    }

    final agora = DateTime.now();
    final docRef = _solicitacoesRef.doc();

    await _firestore.runTransaction((tx) async {
      // Reserva provisória: cria a aula já vinculada à turma encontrada,
      // porém com status 'agendada' e origem 'remarcacao' — o saldo da
      // aluna não muda até a professora aprovar (é a mesma aula perdida,
      // só movida de data).
      final novaAulaRef = _aulasRef.doc();
      tx.set(novaAulaRef, {
        'alunaId': alunaId,
        'turmaId': turma.id,
        'data': Timestamp.fromDate(novaData),
        'periodo': novoPeriodo.name,
        'status': StatusAula.agendada.name,
        'origem': OrigemAula.remarcacao.name,
        'aulaOriginalId': aulaOriginalId,
      });

      tx.set(docRef, {
        'alunaId': alunaId,
        'aulaOriginalId': aulaOriginalId,
        'novaAulaId': novaAulaRef.id,
        'novaData': Timestamp.fromDate(novaData),
        'novoPeriodo': novoPeriodo.name,
        'status': StatusRemarcacao.pendente.name,
        'criadaEm': Timestamp.fromDate(agora),
        'expiraEm': Timestamp.fromDate(agora.add(expiracaoSolicitacao)),
      });
    });

    return SolicitacaoRemarcacao(
      id: docRef.id,
      alunaId: alunaId,
      aulaOriginalId: aulaOriginalId,
      novaData: novaData,
      novoPeriodo: novoPeriodo,
      status: StatusRemarcacao.pendente,
      criadaEm: agora,
      expiraEm: agora.add(expiracaoSolicitacao),
    );

    // NOTA: a expiração automática (passo 8 do briefing) deve rodar numa
    // Cloud Function agendada (scheduled function) que varre
    // `remarcacoes_pendentes` com expiraEm < agora e status == pendente,
    // chamando a mesma lógica de `recusarRemarcacao`.
  }

  @override
  Future<void> aprovarRemarcacao(String solicitacaoId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _solicitacoesRef.doc(solicitacaoId);
      final snap = await tx.get(ref);
      final aulaOriginalId = snap['aulaOriginalId'] as String;

      tx.update(_aulasRef.doc(aulaOriginalId), {
        'status': StatusAula.remarcada.name,
      });
      tx.update(ref, {'status': StatusRemarcacao.aprovada.name});
      // A nova aula já foi criada como 'agendada' em solicitarRemarcacao —
      // aqui só finalizamos a aula original e o status da solicitação.
      // TODO: disparar notificação FCM para a aluna.
    });
  }

  @override
  Future<void> recusarRemarcacao(String solicitacaoId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _solicitacoesRef.doc(solicitacaoId);
      final snap = await tx.get(ref);
      final novaAulaId = snap['novaAulaId'] as String?;

      // Libera a vaga provisória cancelando a aula "reservada".
      if (novaAulaId != null) {
        tx.update(_aulasRef.doc(novaAulaId), {
          'status': StatusAula.cancelada.name,
        });
      }
      tx.update(ref, {'status': StatusRemarcacao.recusada.name});
    });
  }

  @override
  Stream<List<SolicitacaoRemarcacao>> solicitacoesPendentes() {
    return _solicitacoesRef
        .where('status', isEqualTo: StatusRemarcacao.pendente.name)
        .orderBy('criadaEm')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return SolicitacaoRemarcacao(
                id: doc.id,
                alunaId: data['alunaId'] as String,
                aulaOriginalId: data['aulaOriginalId'] as String,
                novaData: (data['novaData'] as Timestamp).toDate(),
                novoPeriodo: Periodo.values.byName(data['novoPeriodo'] as String),
                status: StatusRemarcacao.values.byName(data['status'] as String),
                criadaEm: (data['criadaEm'] as Timestamp).toDate(),
                expiraEm: (data['expiraEm'] as Timestamp).toDate(),
              );
            }).toList());
  }

  @override
  Future<Aula> comprarAulaExtra({
    required String alunaId,
    required DateTime data,
    required Periodo periodo,
  }) async {
    final turma = await _turmaRepository.encontrarTurmaComVaga(
      dia: data,
      periodo: periodo,
    );
    if (turma == null) {
      throw NenhumaVagaDisponivelException(periodo);
    }

    // Aula extra fica com status 'agendada' mas o pagamento correspondente
    // (coleção `aulas_extras_compradas` / `pagamentos`) começa como
    // 'pendente' — só é liberada de fato (ver PagamentoRepository, a
    // implementar) quando o pagamento é confirmado pela professora.
    final ref = await _aulasRef.add({
      'alunaId': alunaId,
      'turmaId': turma.id,
      'data': Timestamp.fromDate(data),
      'periodo': periodo.name,
      'status': StatusAula.agendada.name,
      'origem': OrigemAula.extra.name,
      'aulaOriginalId': null,
    });

    return Aula(
      id: ref.id,
      alunaId: alunaId,
      turmaId: turma.id,
      data: data,
      periodo: periodo,
      status: StatusAula.agendada,
      origem: OrigemAula.extra,
    );
  }
}

class NenhumaVagaDisponivelException implements Exception {
  final Periodo periodo;
  NenhumaVagaDisponivelException(this.periodo);

  @override
  String toString() =>
      'Não existem vagas disponíveis neste período (${periodo.label}). Escolha outro dia.';
}
