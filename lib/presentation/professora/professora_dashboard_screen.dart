import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../domain/entities/pagamento.dart';
import '../../providers/providers.dart';
import '../shared/widgets/app_card.dart';

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
            onPressed: () => context.push('/professora/cadastros'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Cadastros',
          ),
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
          const SizedBox(width: 4),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // ---- Resumo ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ResumoCard(
                  background: AppColors.pinkLight,
                  labelColor: AppColors.pinkText,
                  icone: Icons.event_repeat,
                  label: 'Remarcações',
                  valor: '${solicitacoesAsync.valueOrNull?.length ?? '—'}',
                  complemento: 'aguardando',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResumoCard(
                  background: AppColors.lilacLight,
                  labelColor: AppColors.lilacText,
                  icone: Icons.credit_card_outlined,
                  label: 'Pagamentos',
                  valor: '${pagamentosPendentesAsync.valueOrNull?.length ?? '—'}',
                  complemento: 'pendentes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ---- Solicitações de remarcação ----
          const _TituloSecao(
            icone: Icons.event_repeat,
            titulo: 'Solicitações de remarcação',
          ),
          const SizedBox(height: 10),
          solicitacoesAsync.when(
            loading: () => const _CarregandoSecao(),
            error: (e, st) => _ErroSecao(mensagem: '$e'),
            data: (lista) {
              if (lista.isEmpty) {
                return const _VazioSecao(
                  icone: Icons.check_circle_outline,
                  mensagem: 'Nenhuma solicitação pendente.',
                );
              }
              return Column(
                children:
                    lista.map((s) => _SolicitacaoCard(solicitacao: s)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ---- Pagamentos pendentes ----
          const _TituloSecao(
            icone: Icons.credit_card_outlined,
            titulo: 'Pagamentos pendentes',
          ),
          const SizedBox(height: 10),
          pagamentosPendentesAsync.when(
            loading: () => const _CarregandoSecao(),
            error: (e, st) => _ErroSecao(mensagem: '$e'),
            data: (lista) {
              if (lista.isEmpty) {
                return const _VazioSecao(
                  icone: Icons.check_circle_outline,
                  mensagem: 'Nenhum pagamento pendente.',
                );
              }
              return Column(
                children:
                    lista.map((p) => _PagamentoCard(pagamento: p)).toList(),
              );
            },
          ),
          // TODO: seções de "Alunas cadastradas" e "Turmas e ocupação"
          // seguem o mesmo padrão de card usado aqui.
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final Color background;
  final Color labelColor;
  final IconData icone;
  final String label;
  final String valor;
  final String complemento;

  const _ResumoCard({
    required this.background,
    required this.labelColor,
    required this.icone,
    required this.label,
    required this.valor,
    required this.complemento,
  });

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: labelColor),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(valor,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(complemento,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  const _TituloSecao({required this.icone, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _CartaoBase extends StatelessWidget {
  final Widget child;
  const _CartaoBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _SolicitacaoCard extends ConsumerWidget {
  final SolicitacaoRemarcacao solicitacao;
  const _SolicitacaoCard({required this.solicitacao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CartaoBase(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: substituir pelo nome real (buscar Usuario por alunaId).
                Text(solicitacao.alunaId,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${_capitalizar(DateFormat("EEEE", 'pt_BR').format(solicitacao.novaData))} · '
                  '${DateFormat("dd/MM").format(solicitacao.novaData)} · '
                  '${solicitacao.novoPeriodo.label}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AcaoIcone(
            icone: Icons.check,
            corFundo: AppColors.successBg,
            corIcone: AppColors.successText,
            onTap: () => ref
                .read(aulaRepositoryProvider)
                .aprovarRemarcacao(solicitacao.id),
          ),
          const SizedBox(width: 8),
          _AcaoIcone(
            icone: Icons.close,
            corFundo: AppColors.dangerBg,
            corIcone: AppColors.dangerText,
            onTap: () => ref
                .read(aulaRepositoryProvider)
                .recusarRemarcacao(solicitacao.id),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _PagamentoCard extends ConsumerWidget {
  final Pagamento pagamento;
  const _PagamentoCard({required this.pagamento});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final atrasado = pagamento.status == StatusPagamento.atrasado;

    return _CartaoBase(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(moeda.format(pagamento.valor),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    atrasado
                        ? StatusPill.perigo('Atrasado')
                        : StatusPill.aviso('Pendente'),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  // TODO: substituir pelo nome real (buscar Usuario por alunaId).
                  '${pagamento.alunaId} · vence '
                  '${DateFormat("dd/MM").format(pagamento.vencimento)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => ref
                .read(pagamentoRepositoryProvider)
                .darBaixaManual(pagamento.id),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.successText,
              backgroundColor: AppColors.successBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Dar baixa',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _VazioSecao extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  const _VazioSecao({required this.icone, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icone, size: 26, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(mensagem,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CarregandoSecao extends StatelessWidget {
  const _CarregandoSecao();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErroSecao extends StatelessWidget {
  final String mensagem;
  const _ErroSecao({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text('Erro: $mensagem',
          style: const TextStyle(color: AppColors.dangerText, fontSize: 13)),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: corFundo, shape: BoxShape.circle),
        child: Icon(icone, size: 19, color: corIcone),
      ),
    );
  }
}
