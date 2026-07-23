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

  const Pagamento({
    required this.id,
    required this.alunaId,
    required this.valor,
    required this.vencimento,
    this.pagoEm,
    this.observacao,
  });

  StatusPagamento get status => StatusPagamentoCalculo.calcular(
        foiPago: pagoEm != null,
        vencimento: vencimento,
      );
}
