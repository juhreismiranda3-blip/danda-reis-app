import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/pagamento.dart';
import '../../providers/providers.dart';
import '../shared/widgets/app_card.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

class PagamentosAlunaScreen extends ConsumerWidget {
  const PagamentosAlunaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final pagamentosAsync = ref.watch(pagamentosDaAlunaProvider(usuario.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamentos')),
      body: pagamentosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (pagamentos) {
          if (pagamentos.isEmpty) {
            return const Center(
              child: Text('Nenhum pagamento registrado ainda.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pagamentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _PagamentoTile(
              pagamento: pagamentos[i],
              nomeAluna: usuario.nome,
            ),
          );
        },
      ),
    );
  }
}

class _PagamentoTile extends StatelessWidget {
  final Pagamento pagamento;
  final String nomeAluna;
  const _PagamentoTile({required this.pagamento, required this.nomeAluna});

  StatusPill get _pill => switch (pagamento.status) {
        StatusPagamento.pago => StatusPill.sucesso('Pago'),
        StatusPagamento.pendente => StatusPill.aviso('Pendente'),
        StatusPagamento.atrasado => StatusPill.perigo('Atrasado'),
      };

  @override
  Widget build(BuildContext context) {
    final pago = pagamento.status == StatusPagamento.pago;
    final subtitulo = pago
        ? 'Pago em ${DateFormat('dd/MM/yyyy').format(pagamento.pagoEm!)}'
        : 'Vencimento ${DateFormat('dd/MM/yyyy').format(pagamento.vencimento)}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _mostrarRecibo(context, pagamento, nomeAluna),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_moeda.format(pagamento.valor),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      _pill,
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(pagamento.descricao ?? 'Mensalidade',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                  Text(subtitulo,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                  if (pagamento.qtdAulasExtras > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Inclui ${pagamento.qtdAulasExtras} '
                      'aula${pagamento.qtdAulasExtras > 1 ? 's' : ''} extra'
                      '${pagamento.qtdAulasExtras > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.pinkText,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(
                  pago ? Icons.receipt_long : Icons.chevron_right,
                  size: pago ? 20 : 22,
                  color: pago ? AppColors.pinkText : AppColors.textMuted,
                ),
                if (pago) ...[
                  const SizedBox(height: 2),
                  const Text('recibo',
                      style: TextStyle(fontSize: 9.5, color: AppColors.pinkText)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _mostrarRecibo(BuildContext context, Pagamento p, String nomeAluna) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReciboSheet(pagamento: p, nomeAluna: nomeAluna),
  );
}

/// Recibo/comprovante do pagamento, exibido como um cartão em formato de
/// papel (com carimbo "PAGO" quando quitado e detalhamento das aulas extras).
class _ReciboSheet extends StatelessWidget {
  final Pagamento pagamento;
  final String nomeAluna;
  const _ReciboSheet({required this.pagamento, required this.nomeAluna});

  @override
  Widget build(BuildContext context) {
    final pago = pagamento.status == StatusPagamento.pago;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho da marca
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.pinkLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.content_cut,
                            size: 20, color: AppColors.pinkText),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Danda Reis',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          Text('Corte e Costura',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  color: AppColors.pinkText)),
                        ],
                      ),
                      const Spacer(),
                      Text('RECIBO',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _LinhaTracejada(),
                  const SizedBox(height: 18),

                  Text(pagamento.descricao ?? 'Mensalidade',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('Aluna: $nomeAluna',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),

                  // Detalhamento
                  _linha('Mensalidade', _moeda.format(pagamento.valorBase)),
                  if (pagamento.qtdAulasExtras > 0) ...[
                    const SizedBox(height: 8),
                    _linha(
                      'Aulas extras (${pagamento.qtdAulasExtras})',
                      _moeda.format(pagamento.valorAulasExtras),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _LinhaTracejada(),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(_moeda.format(pagamento.valor),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Situação / carimbo
                  Center(
                    child: pago
                        ? _CarimboPago(
                            pagoEm: pagamento.pagoEm!,
                          )
                        : _situacaoPendente(pagamento),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pago
                        ? 'Vencimento: ${DateFormat('dd/MM/yyyy').format(pagamento.vencimento)}'
                        : 'Aguardando pagamento',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                  if (pagamento.observacao != null) ...[
                    const SizedBox(height: 10),
                    Text(pagamento.observacao!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        Text(valor,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _situacaoPendente(Pagamento p) {
    final atrasado = p.status == StatusPagamento.atrasado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: atrasado ? AppColors.dangerBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        atrasado ? 'Pagamento atrasado' : 'Pagamento pendente',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: atrasado ? AppColors.dangerText : AppColors.warningText,
        ),
      ),
    );
  }
}

/// Carimbo estilo "PAGO" (com leve rotação) para o recibo quitado.
class _CarimboPago extends StatelessWidget {
  final DateTime pagoEm;
  const _CarimboPago({required this.pagoEm});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.successText, width: 2.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('PAGO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppColors.successText,
                )),
            Text(DateFormat('dd/MM/yyyy').format(pagoEm),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successText)),
          ],
        ),
      ),
    );
  }
}

/// Linha tracejada horizontal (estética de recibo de papel).
class _LinhaTracejada extends StatelessWidget {
  const _LinhaTracejada();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const larguraTraco = 6.0;
        const espaco = 4.0;
        final qtd = (constraints.maxWidth / (larguraTraco + espaco)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            qtd,
            (_) => Container(
              width: larguraTraco,
              height: 1,
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}
