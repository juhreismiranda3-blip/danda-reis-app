import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/turma.dart';
import '../../domain/repositories/turma_repository.dart';
import 'ocupacao.dart';

class FirestoreTurmaRepository implements TurmaRepository {
  final FirebaseFirestore _firestore;

  FirestoreTurmaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _turmasRef => _firestore.collection('turmas');
  CollectionReference get _ocupacaoRef => _firestore.collection('ocupacao');

  @override
  Stream<List<Turma>> get todasTurmas {
    return _turmasRef.snapshots().map(
          (snap) => snap.docs.map(_turmaFromDoc).toList(),
        );
  }

  Turma _turmaFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Turma(
      id: doc.id,
      nome: data['nome'] as String,
      diaSemana: DiaSemana.values.byName(data['diaSemana'] as String),
      periodo: Periodo.values.byName(data['periodo'] as String),
      horarioInicio: data['horarioInicio'] as String,
      horarioFim: data['horarioFim'] as String,
      capacidadeMaxima: data['capacidadeMaxima'] as int,
    );
  }

  @override
  Future<void> criarTurma(Turma turma) async {
    await _turmasRef.doc(turma.id).set({
      'nome': turma.nome,
      'diaSemana': turma.diaSemana.name,
      'periodo': turma.periodo.name,
      'horarioInicio': turma.horarioInicio,
      'horarioFim': turma.horarioFim,
      'capacidadeMaxima': turma.capacidadeMaxima,
    });
  }

  @override
  Future<void> atualizarTurma(Turma turma) => criarTurma(turma);

  @override
  Future<void> removerTurma(String turmaId) => _turmasRef.doc(turmaId).delete();

  @override
  Future<List<DisponibilidadePeriodo>> disponibilidadePorDia(DateTime dia) async {
    final diaSemana = _diaSemanaFromWeekday(dia.weekday);
    if (diaSemana == null) {
      // Sábado/domingo: escola não funciona nesses dias (seg a qui).
      return const [];
    }

    final turmasDoDia = await _turmasRef
        .where('diaSemana', isEqualTo: diaSemana.name)
        .get();

    final resultado = <Periodo, int>{};
    for (final periodo in Periodo.values) {
      final turmasDoPeriodo = turmasDoDia.docs
          .map(_turmaFromDoc)
          .where((t) => t.periodo == periodo)
          .toList();

      var vagas = 0;
      for (final turma in turmasDoPeriodo) {
        final ocupadas = await _ocupadasNoContador(turma.id, dia);
        vagas += (turma.capacidadeMaxima - ocupadas).clamp(0, turma.capacidadeMaxima);
      }
      resultado[periodo] = vagas;
    }

    return resultado.entries
        .map((e) => DisponibilidadePeriodo(periodo: e.key, vagasDisponiveis: e.value))
        .toList();
  }

  @override
  Future<Turma?> encontrarTurmaComVaga({
    required DateTime dia,
    required Periodo periodo,
  }) async {
    final candidatas = await turmasDoDiaEPeriodo(dia, periodo);
    for (final turma in candidatas) {
      final ocupadas = await _ocupadasNoContador(turma.id, dia);
      if (ocupadas < turma.capacidadeMaxima) return turma;
    }
    return null; // nenhuma turma com vaga nesse dia+período
  }

  @override
  Future<List<Turma>> turmasDoDiaEPeriodo(DateTime dia, Periodo periodo) async {
    final diaSemana = _diaSemanaFromWeekday(dia.weekday);
    if (diaSemana == null) return const [];

    final candidatas = await _turmasRef
        .where('diaSemana', isEqualTo: diaSemana.name)
        .where('periodo', isEqualTo: periodo.name)
        .get();
    return candidatas.docs.map(_turmaFromDoc).toList();
  }

  /// Ocupação atual da turma no dia, lida do contador `ocupacao`
  /// (fonte única de verdade, mantida pela reserva transacional).
  Future<int> _ocupadasNoContador(String turmaId, DateTime dia) async {
    final snap = await _ocupacaoRef.doc(ocupacaoDocId(turmaId, dia)).get();
    if (!snap.exists) return 0;
    final data = snap.data() as Map<String, dynamic>;
    return (data['ocupadas'] as num?)?.toInt() ?? 0;
  }

  DiaSemana? _diaSemanaFromWeekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => DiaSemana.segunda,
      DateTime.tuesday => DiaSemana.terca,
      DateTime.wednesday => DiaSemana.quarta,
      DateTime.thursday => DiaSemana.quinta,
      _ => null, // sexta a domingo: escola fechada
    };
  }
}
