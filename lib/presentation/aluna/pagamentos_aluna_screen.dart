import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/pagamento.dart';
import '../../providers/providers.dart';
import '../shared/widgets/app_card.dart';

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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PagamentoTile(pagamento: pagamentos[i]),
          );
        },
      ),
    );
  }
}

class _PagamentoTile extends StatelessWidget {
  final Pagamento pagamento;
  const _PagamentoTile({required this.pagamento});

  @override
  Widget build(BuildContext context) {
    final pill = switch (pagamento.status) {
      StatusPagamento.pago => StatusPill.sucesso('Pago'),
      StatusPagamento.pendente => StatusPill.aviso('Pendente'),
      StatusPagamento.atrasado => StatusPill.perigo('Atrasado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('R\$ ${pagamento.valor.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(
                'Vencimento: ${DateFormat('dd/MM/yyyy').format(pagamento.vencimento)}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          pill,
        ],
      ),
    );
  }
}
