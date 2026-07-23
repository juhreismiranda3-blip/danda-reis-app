enum StatusPagamento { pago, pendente, atrasado }

extension StatusPagamentoCalculo on StatusPagamento {
  static StatusPagamento calcular({
    required bool foiPago,
    required DateTime vencimento,
  }) {
    if (foiPago) return StatusPagamento.pago;
    return DateTime.now().isAfter(vencimento)
        ? StatusPagamento.atrasado
        : StatusPagamento.pendente;
  }
}

class Pagamento {
  final String id;
  final String alunaId;
  final double valor;
  final DateTime vencimento;
  final DateTime? pagoEm;
  final String? observacao;

  /// Descrição amigável (ex.: "Mensalidade de julho").
  final String? descricao;

  /// Parte do [valor] que veio de aulas extras somadas a esta mensalidade,
  /// e quantas aulas extras estão inclusas — usado no detalhamento do recibo.
  final double valorAulasExtras;
  final int qtdAulasExtras;

  const Pagamento({
    required this.id,
    required this.alunaId,
    required this.valor,
    required this.vencimento,
    this.pagoEm,
    this.observacao,
    this.descricao,
    this.valorAulasExtras = 0,
    this.qtdAulasExtras = 0,
  });

  /// Valor da mensalidade em si, sem as aulas extras somadas.
  double get valorBase => valor - valorAulasExtras;

  StatusPagamento get status => StatusPagamentoCalculo.calcular(
        foiPago: pagoEm != null,
        vencimento: vencimento,
      );
}
