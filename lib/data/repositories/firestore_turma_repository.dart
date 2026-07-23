import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/turma.dart';
import '../../domain/repositories/turma_repository.dart';

class FirestoreTurmaRepository implements TurmaRepository {
  final FirebaseFirestore _firestore;

  FirestoreTurmaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _turmasRef => _firestore.collection('turmas');
  CollectionReference get _aulasRef => _firestore.collection('aulas');

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
        final ocupadas = await _contarAulasConfirmadas(turma.id, dia);
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
    final diaSemana = _diaSemanaFromWeekday(dia.weekday);
    if (diaSemana == null) return null;

    final candidatas = await _turmasRef
        .where('diaSemana', isEqualTo: diaSemana.name)
        .where('periodo', isEqualTo: periodo.name)
        .get();

    for (final doc in candidatas.docs) {
      final turma = _turmaFromDoc(doc);
      final ocupadas = await _contarAulasConfirmadas(turma.id, dia);
      if (ocupadas < turma.capacidadeMaxima) return turma;
    }
    return null; // nenhuma turma com vaga nesse dia+período
  }

  Future<int> _contarAulasConfirmadas(String turmaId, DateTime dia) async {
    final inicioDia = DateTime(dia.year, dia.month, dia.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final snap = await _aulasRef
        .where('turmaId', isEqualTo: turmaId)
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('data', isLessThan: Timestamp.fromDate(fimDia))
        .where('status', isEqualTo: 'agendada')
        .get();
    return snap.docs.length;
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
