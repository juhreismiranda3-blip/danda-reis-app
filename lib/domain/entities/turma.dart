enum Periodo { manha, tarde, noite }
enum DiaSemana { segunda, terca, quarta, quinta }

extension PeriodoLabel on Periodo {
  String get label => switch (this) {
        Periodo.manha => 'Manhã',
        Periodo.tarde => 'Tarde',
        Periodo.noite => 'Noite',
      };
}

extension DiaSemanaLabel on DiaSemana {
  String get label => switch (this) {
        DiaSemana.segunda => 'Segunda',
        DiaSemana.terca => 'Terça',
        DiaSemana.quarta => 'Quarta',
        DiaSemana.quinta => 'Quinta',
      };

  /// Índice compatível com DateTime.weekday (1 = segunda ... 7 = domingo)
  int get weekday => switch (this) {
        DiaSemana.segunda => DateTime.monday,
        DiaSemana.terca => DateTime.tuesday,
        DiaSemana.quarta => DateTime.wednesday,
        DiaSemana.quinta => DateTime.thursday,
      };
}

/// Uma turma é definida por dia da semana + período + horário,
/// com uma capacidade máxima de alunas (regra de negócio central).
class Turma {
  final String id;
  final String nome; // ex: "Turma Segunda Manhã"
  final DiaSemana diaSemana;
  final Periodo periodo;
  final String horarioInicio; // "09:00"
  final String horarioFim; // "11:00"
  final int capacidadeMaxima;

  const Turma({
    required this.id,
    required this.nome,
    required this.diaSemana,
    required this.periodo,
    required this.horarioInicio,
    required this.horarioFim,
    required this.capacidadeMaxima,
  });
}

/// Disponibilidade de um período específico num dia (usado no fluxo
/// de remarcação: a aluna só vê isso, nunca a turma/horário exato).
class DisponibilidadePeriodo {
  final Periodo periodo;
  final int vagasDisponiveis;

  const DisponibilidadePeriodo({
    required this.periodo,
    required this.vagasDisponiveis,
  });

  bool get temVaga => vagasDisponiveis > 0;
}
