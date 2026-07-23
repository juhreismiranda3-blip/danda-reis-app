import '../entities/aula.dart';
import '../entities/turma.dart';

abstract class AulaRepository {
  /// Aulas do mês corrente de uma aluna específica (área da aluna).
  Stream<List<Aula>> aulasDaAluna(String alunaId, {required DateTime mesReferencia});

  /// Todas as aulas do mês, de todas as alunas (painel da professora).
  Stream<List<Aula>> todasAsAulas({required DateTime mesReferencia});

  Future<void> marcarPresenca(String aulaId, StatusAula status);

  /// Cria a solicitação de remarcação (fica pendente até a professora aprovar).
  /// A vaga é reservada provisoriamente neste momento.
  Future<SolicitacaoRemarcacao> solicitarRemarcacao({
    required String alunaId,
    required String aulaOriginalId,
    required DateTime novaData,
    required Periodo novoPeriodo,
  });

  Future<void> aprovarRemarcacao(String solicitacaoId);
  Future<void> recusarRemarcacao(String solicitacaoId);

  Stream<List<SolicitacaoRemarcacao>> solicitacoesPendentes();

  /// Compra de aula extra — separada do saldo do pacote principal.
  Future<Aula> comprarAulaExtra({
    required String alunaId,
    required DateTime data,
    required Periodo periodo,
  });
}
