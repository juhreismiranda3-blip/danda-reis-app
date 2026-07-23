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

  // ---- Confirmação de presença e oferta de vaga ----

  /// A aluna confirma que vai à aula.
  Future<void> confirmarAula(String aulaId);

  /// A aluna recusa a aula: ela é cancelada, a vaga é liberada e uma oferta
  /// é criada para as demais alunas (a primeira que aceitar leva).
  Future<void> recusarAula(String aulaId);

  /// Ofertas de vaga em aberto (vagas liberadas ainda não preenchidas).
  Stream<List<OfertaVaga>> ofertasAbertas();

  /// A aluna aceita uma vaga ofertada — vira uma aula extra dela (o valor é
  /// somado à mensalidade pela camada de apresentação). A primeira a aceitar
  /// leva; as demais recebem "vaga já preenchida".
  Future<Aula> aceitarOferta({
    required String ofertaId,
    required String alunaId,
  });
}
