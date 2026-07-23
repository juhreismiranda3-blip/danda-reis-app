import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

class ProfessoraDashboardScreen extends ConsumerWidget {
  const ProfessoraDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitacoesAsync = ref.watch(solicitacoesPendentesProvider);
    final pagamentosPendentesAsync = ref.watch(pagamentosPendentesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Presença'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Relatórios'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 1:
              context.push('/professora/presenca');
            case 2:
              context.push('/professora/avisos');
            case 3:
              context.push('/professora/relatorios');
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Solicitações de remarcação',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          solicitacoesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Erro: $e'),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nenhuma solicitação pendente.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                );
              }
              return Column(
                children: lista.map((s) => _SolicitacaoTile(solicitacao: s)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Pagamentos pendentes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          pagamentosPendentesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Erro: $e'),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nenhum pagamento pendente.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                );
              }
              return Column(
                children: lista.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('R\$ ${p.valor.toStringAsFixed(2)} · ${p.alunaId}',
                          style: const TextStyle(fontSize: 13)),
                      TextButton(
                        onPressed: () => ref.read(pagamentoRepositoryProvider).darBaixaManual(p.id),
                        child: const Text('Dar baixa'),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          // TODO: seções de "Alunas cadastradas" e "Turmas e ocupação"
          // seguem o mesmo padrão de card usado aqui.
        ],
      ),
    );
  }
}

class _SolicitacaoTile extends ConsumerWidget {
  final SolicitacaoRemarcacao solicitacao;
  const _SolicitacaoTile({required this.solicitacao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: substituir pelo nome real (buscar Usuario por alunaId).
                Text(solicitacao.alunaId, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                Text(
                  '${DateFormat("EEEE", 'pt_BR').format(solicitacao.novaData)} · ${solicitacao.novoPeriodo.label}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _AcaoIcone(
                icone: Icons.check,
                corFundo: AppColors.successBg,
                corIcone: AppColors.successText,
                onTap: () => ref.read(aulaRepositoryProvider).aprovarRemarcacao(solicitacao.id),
              ),
              const SizedBox(width: 6),
              _AcaoIcone(
                icone: Icons.close,
                corFundo: AppColors.dangerBg,
                corIcone: AppColors.dangerText,
                onTap: () => ref.read(aulaRepositoryProvider).recusarRemarcacao(solicitacao.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcaoIcone extends StatelessWidget {
  final IconData icone;
  final Color corFundo;
  final Color corIcone;
  final VoidCallback onTap;

  const _AcaoIcone({
    required this.icone,
    required this.corFundo,
    required this.corIcone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: corFundo, shape: BoxShape.circle),
        child: Icon(icone, size: 15, color: corIcone),
      ),
    );
  }
}
