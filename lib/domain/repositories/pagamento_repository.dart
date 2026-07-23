import '../entities/pagamento.dart';

abstract class PagamentoRepository {
  Stream<List<Pagamento>> pagamentosDaAluna(String alunaId);
  Stream<List<Pagamento>> todosPendentesOuAtrasados();

  Future<void> cadastrarPagamento(Pagamento pagamento);
  Future<void> editarPagamento(Pagamento pagamento);
  Future<void> cancelarPagamento(String pagamentoId);

  /// Soma o valor de uma aula extra à mensalidade em aberto da aluna
  /// (cria uma cobrança nova se não houver mensalidade pendente).
  Future<void> incluirAulaExtraNaMensalidade({
    required String alunaId,
    required double valorAula,
    String? aulaExtraId,
  });

  /// Dá baixa manual (marca como pago). Se o pagamento estiver vinculado
  /// a uma aula extra pendente, a aula é liberada (status confirmada) —
  /// ver comprarAulaExtra em AulaRepository.
  Future<void> darBaixaManual(String pagamentoId);
}
