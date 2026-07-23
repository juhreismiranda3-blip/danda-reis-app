import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/aula.dart';
import '../../domain/entities/turma.dart';
import '../../domain/repositories/aula_repository.dart';
import '../../domain/repositories/turma_repository.dart';
import 'ocupacao.dart';

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
  CollectionReference get _ocupacaoRef => _firestore.collection('ocupacao');

  // ---------- Reserva atômica de vaga (anti-superlotação) ----------

  /// Dentro de uma transação, lê a ocupação de cada turma candidata e
  /// devolve a primeira que ainda tem vaga (com sua ocupação atual).
  /// Faz TODAS as leituras antes de qualquer escrita, como o Firestore exige.
  Future<(Turma, int)> _escolherTurmaComVagaTx(
    Transaction tx,
    List<Turma> candidatas,
    DateTime dia,
    Periodo periodo,
  ) async {
    final ocupacoes = <String, int>{};
    for (final turma in candidatas) {
      final snap = await tx.get(_ocupacaoRef.doc(ocupacaoDocId(turma.id, dia)));
      ocupacoes[turma.id] = _ocupadasDe(snap);
    }
    for (final turma in candidatas) {
      if (ocupacoes[turma.id]! < turma.capacidadeMaxima) {
        return (turma, ocupacoes[turma.id]!);
      }
    }
    throw NenhumaVagaDisponivelException(periodo);
  }

  int _ocupadasDe(DocumentSnapshot snap) {
    if (!snap.exists) return 0;
    final data = snap.data() as Map<String, dynamic>;
    return (data['ocupadas'] as num?)?.toInt() ?? 0;
  }

  void _gravarOcupacao(Transaction tx, String turmaId, DateTime dia, int valor) {
    tx.set(
      _ocupacaoRef.doc(ocupacaoDocId(turmaId, dia)),
      {
        'turmaId': turmaId,
        'data': Timestamp.fromDate(inicioDoDia(dia)),
        'ocupadas': valor < 0 ? 0 : valor,
      },
      SetOptions(merge: true),
    );
  }

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
      final data = snap.data() as Map<String, dynamic>;
      final atual = StatusAula.values.byName(data['status'] as String);
      if (atual != StatusAula.agendada) {
        throw Exception('Só é possível marcar presença em aulas agendadas.');
      }
      // Lê o contador antes de escrever (a aula deixa de ocupar vaga).
      final turmaId = data['turmaId'] as String;
      final dataAula = (data['data'] as Timestamp).toDate();
      final contSnap =
          await tx.get(_ocupacaoRef.doc(ocupacaoDocId(turmaId, dataAula)));
      final ocupadas = _ocupadasDe(contSnap);

      tx.update(ref, {'status': status.name});
      _gravarOcupacao(tx, turmaId, dataAula, ocupadas - 1);
    });
  }

  @override
  Future<SolicitacaoRemarcacao> solicitarRemarcacao({
    required String alunaId,
    required String aulaOriginalId,
    required DateTime novaData,
    required Periodo novoPeriodo,
  }) async {
    // 1. Reserva atômica: dentro de uma transação, escolhe uma turma com
    //    vaga, cria a aula 'agendada' (origem 'remarcacao') e incrementa o
    //    contador de ocupação — tudo de uma vez. Assim a vaga não pode ser
    //    "roubada" por outra aluna enquanto a professora não responde, e
    //    duas alunas nunca conseguem a mesma última vaga.
    final candidatas =
        await _turmaRepository.turmasDoDiaEPeriodo(novaData, novoPeriodo);
    if (candidatas.isEmpty) {
      throw NenhumaVagaDisponivelException(novoPeriodo);
    }

    final agora = DateTime.now();
    final docRef = _solicitacoesRef.doc();

    await _firestore.runTransaction((tx) async {
      final (turma, ocupadas) = await _escolherTurmaComVagaTx(
        tx,
        candidatas,
        novaData,
        novoPeriodo,
      );

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
      _gravarOcupacao(tx, turma.id, novaData, ocupadas + 1);

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

      // Lê a aula original: ao virar 'remarcada', ela libera a vaga que
      // ocupava no dia original, então decrementamos aquele contador.
      final origRef = _aulasRef.doc(aulaOriginalId);
      final origSnap = await tx.get(origRef);
      String? turmaOrig;
      DateTime? dataOrig;
      int ocupadasOrig = 0;
      var eraAgendada = false;
      if (origSnap.exists) {
        final od = origSnap.data() as Map<String, dynamic>;
        eraAgendada = (od['status'] as String) == StatusAula.agendada.name;
        turmaOrig = od['turmaId'] as String;
        dataOrig = (od['data'] as Timestamp).toDate();
        final contSnap =
            await tx.get(_ocupacaoRef.doc(ocupacaoDocId(turmaOrig, dataOrig)));
        ocupadasOrig = _ocupadasDe(contSnap);
      }

      // Escritas
      if (origSnap.exists) {
        tx.update(origRef, {'status': StatusAula.remarcada.name});
        if (eraAgendada && turmaOrig != null && dataOrig != null) {
          _gravarOcupacao(tx, turmaOrig, dataOrig, ocupadasOrig - 1);
        }
      }
      tx.update(ref, {'status': StatusRemarcacao.aprovada.name});
      // A nova aula já foi criada como 'agendada' em solicitarRemarcacao.
      // TODO: disparar notificação FCM para a aluna.
    });
  }

  @override
  Future<void> recusarRemarcacao(String solicitacaoId) async {
    await _firestore.runTransaction((tx) async {
      final ref = _solicitacoesRef.doc(solicitacaoId);
      final snap = await tx.get(ref);
      final novaAulaId = snap['novaAulaId'] as String?;

      // Lê a aula provisória para liberar a vaga (cancelar) e decrementar
      // o contador de ocupação — só se ela ainda estiver 'agendada'.
      DocumentReference? novaAulaRef;
      String? turmaNova;
      DateTime? dataNova;
      int ocupadasNova = 0;
      var podeLiberar = false;
      if (novaAulaId != null) {
        novaAulaRef = _aulasRef.doc(novaAulaId);
        final aulaSnap = await tx.get(novaAulaRef);
        if (aulaSnap.exists) {
          final ad = aulaSnap.data() as Map<String, dynamic>;
          podeLiberar = (ad['status'] as String) == StatusAula.agendada.name;
          turmaNova = ad['turmaId'] as String;
          dataNova = (ad['data'] as Timestamp).toDate();
          final contSnap =
              await tx.get(_ocupacaoRef.doc(ocupacaoDocId(turmaNova, dataNova)));
          ocupadasNova = _ocupadasDe(contSnap);
        }
      }

      // Escritas
      if (novaAulaRef != null && podeLiberar) {
        tx.update(novaAulaRef, {'status': StatusAula.cancelada.name});
        if (turmaNova != null && dataNova != null) {
          _gravarOcupacao(tx, turmaNova, dataNova, ocupadasNova - 1);
        }
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
    final candidatas = await _turmaRepository.turmasDoDiaEPeriodo(data, periodo);
    if (candidatas.isEmpty) {
      throw NenhumaVagaDisponivelException(periodo);
    }

    // Reserva atômica: escolhe turma com vaga, cria a aula 'agendada'
    // (origem 'extra') e incrementa o contador de ocupação numa transação.
    // O pagamento é somado à mensalidade da aluna (ver PagamentoRepository).
    return _firestore.runTransaction<Aula>((tx) async {
      final (turma, ocupadas) =
          await _escolherTurmaComVagaTx(tx, candidatas, data, periodo);

      final ref = _aulasRef.doc();
      tx.set(ref, {
        'alunaId': alunaId,
        'turmaId': turma.id,
        'data': Timestamp.fromDate(data),
        'periodo': periodo.name,
        'status': StatusAula.agendada.name,
        'origem': OrigemAula.extra.name,
        'aulaOriginalId': null,
      });
      _gravarOcupacao(tx, turma.id, data, ocupadas + 1);

      return Aula(
        id: ref.id,
        alunaId: alunaId,
        turmaId: turma.id,
        data: data,
        periodo: periodo,
        status: StatusAula.agendada,
        origem: OrigemAula.extra,
      );
    });
  }
}

class NenhumaVagaDisponivelException implements Exception {
  final Periodo periodo;
  NenhumaVagaDisponivelException(this.periodo);

  @override
  String toString() =>
      'Não existem vagas disponíveis neste período (${periodo.label}). Escolha outro dia.';
}
