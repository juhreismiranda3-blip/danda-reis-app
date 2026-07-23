import 'turma.dart';

/// Máquina de estados da aula — decisão de arquitetura tomada com a
/// cliente para evitar inconsistências (ex: uma aula não pode estar
/// "com falta" e "remarcada" ao mesmo tempo).
///
///   agendada -> concluida
///   agendada -> falta
///   agendada -> remarcada (gera uma nova aula "agendada" vinculada)
///   agendada -> cancelada
enum StatusAula { agendada, concluida, falta, remarcada, cancelada }

enum OrigemAula { pacote, extra, remarcacao }

/// Confirmação de presença que a aluna dá ~1 dia antes da aula.
/// Se ela recusa, a vaga é liberada e ofertada às demais alunas.
enum ConfirmacaoAula { pendente, confirmada, recusada }

class Aula {
  final String id;
  final String alunaId;
  final String turmaId;
  final DateTime data;
  final Periodo periodo;
  final StatusAula status;
  final OrigemAula origem;
  final ConfirmacaoAula confirmacao;

  /// Se esta aula é resultado de uma remarcação, aponta para a aula original.
  final String? aulaOriginalId;

  const Aula({
    required this.id,
    required this.alunaId,
    required this.turmaId,
    required this.data,
    required this.periodo,
    required this.status,
    required this.origem,
    this.confirmacao = ConfirmacaoAula.pendente,
    this.aulaOriginalId,
  });

  Aula copyWith({StatusAula? status, ConfirmacaoAula? confirmacao}) => Aula(
        id: id,
        alunaId: alunaId,
        turmaId: turmaId,
        data: data,
        periodo: periodo,
        status: status ?? this.status,
        origem: origem,
        confirmacao: confirmacao ?? this.confirmacao,
        aulaOriginalId: aulaOriginalId,
      );
}

/// Uma vaga que foi liberada (a aluna original recusou a aula) e está sendo
/// ofertada às demais alunas — a primeira que aceitar fica com ela.
class OfertaVaga {
  final String id;
  final String turmaId;
  final DateTime data;
  final Periodo periodo;
  final String origemAlunaId; // quem liberou a vaga
  final bool aberta;

  const OfertaVaga({
    required this.id,
    required this.turmaId,
    required this.data,
    required this.periodo,
    required this.origemAlunaId,
    required this.aberta,
  });
}

/// Uma solicitação de remarcação pendente de aprovação da professora.
/// Existe como coleção própria porque tem seu próprio ciclo de vida
/// (pendente -> aprovada | recusada | expirada).
enum StatusRemarcacao { pendente, aprovada, recusada, expirada }

class SolicitacaoRemarcacao {
  final String id;
  final String alunaId;
  final String aulaOriginalId;
  final DateTime novaData;
  final Periodo novoPeriodo;
  final StatusRemarcacao status;
  final DateTime criadaEm;
  final DateTime expiraEm;

  const SolicitacaoRemarcacao({
    required this.id,
    required this.alunaId,
    required this.aulaOriginalId,
    required this.novaData,
    required this.novoPeriodo,
    required this.status,
    required this.criadaEm,
    required this.expiraEm,
  });
}
