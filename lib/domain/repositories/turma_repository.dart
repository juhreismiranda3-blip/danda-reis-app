import '../entities/turma.dart';

abstract class TurmaRepository {
  Stream<List<Turma>> get todasTurmas;

  Future<void> criarTurma(Turma turma);
  Future<void> atualizarTurma(Turma turma);
  Future<void> removerTurma(String turmaId);

  /// Regra de negócio central do fluxo de remarcação: dado um dia,
  /// retorna quantas vagas existem em cada período (manhã/tarde/noite),
  /// considerando a capacidade máxima de cada turma menos as aulas já
  /// confirmadas naquele dia+período.
  Future<List<DisponibilidadePeriodo>> disponibilidadePorDia(DateTime dia);

  /// Encontra automaticamente uma turma com vaga para o dia+período
  /// escolhidos. A aluna nunca escolhe a turma diretamente — isso é
  /// decisão de UX confirmada com a cliente.
  Future<Turma?> encontrarTurmaComVaga({
    required DateTime dia,
    required Periodo periodo,
  });
}
