import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../domain/entities/pagamento.dart';
import '../../providers/providers.dart';
import '../shared/widgets/app_card.dart';

class AlunaHomeScreen extends ConsumerWidget {
  const AlunaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final mesReferencia = DateTime.now();
    final aulasAsync = ref.watch(
      aulasDaAlunaProvider((alunaId: usuario.id, mes: mesReferencia)),
    );
    final pagamentosAsync = ref.watch(pagamentosDaAlunaProvider(usuario.id));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.pinkLight,
              child: Text(
                _iniciais(usuario.nome),
                style: const TextStyle(color: AppColors.pinkText, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_saudacao(),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(usuario.nome.split(' ').first,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), label: 'Pagamentos'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        onDestinationSelected: (i) {
          if (i == 2) context.push('/aluna/pagamentos');
          // TODO: índices 1 (Agenda) e 3 (Perfil) — telas ainda a criar.
        },
      ),
      body: aulasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro ao carregar aulas: $e')),
        data: (aulas) => _Conteudo(
          aulas: aulas,
          limiteMensal: usuario.aulasPorMes,
          pagamentosAsync: pagamentosAsync,
        ),
      ),
    );
  }

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia,';
    if (h < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}

class _Conteudo extends ConsumerWidget {
  final List<Aula> aulas;
  final int limiteMensal;
  final AsyncValue<List<Pagamento>> pagamentosAsync;

  const _Conteudo({
    required this.aulas,
    required this.limiteMensal,
    required this.pagamentosAsync,
  });

  /// Aulas que "consomem" o limite do mês: exclui as canceladas, as
  /// remarcadas (que geram uma nova aula já contada) e as aulas extra
  /// (essas são pagas à parte, não entram no limite do plano).
  int _aulasUsadasNoMes() => aulas
      .where((a) =>
          a.origem != OrigemAula.extra &&
          a.status != StatusAula.cancelada &&
          a.status != StatusAula.remarcada)
      .length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aulasAtivas =
        aulas.where((a) => a.status != StatusAula.cancelada).toList();
    final proxima = aulasAtivas
        .where((a) =>
            a.status == StatusAula.agendada && a.data.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final usadas = _aulasUsadasNoMes();
    final atingiuLimite = usadas >= limiteMensal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // ---- Aviso de limite mensal atingido ----
        if (atingiuLimite) ...[
          _AvisoLimite(limiteMensal: limiteMensal),
          const SizedBox(height: 12),
        ],
        // ---- Hero: próxima aula ----
        _CardProximaAula(proxima: proxima.isEmpty ? null : proxima.first),
        const SizedBox(height: 12),
        // ---- Indicadores ----
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCard(
                background: AppColors.lilacLight,
                labelColor: AppColors.lilacText,
                label: 'Aulas no mês',
                icone: Icons.event_available_outlined,
                valor: '$usadas',
                complemento: 'de $limiteMensal',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CardProximoPagamento(pagamentosAsync: pagamentosAsync),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ações rápidas',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: proxima.isEmpty
                    ? null
                    : () => context.go('/aluna/remarcar/${proxima.first.id}'),
                icon: const Icon(Icons.event_repeat, size: 18),
                label: const Text('Remarcar aula'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/aluna/aula-extra'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Aula extra'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Card de destaque com a próxima aula (ou um estado vazio elegante).
class _CardProximaAula extends StatelessWidget {
  final Aula? proxima;
  const _CardProximaAula({required this.proxima});

  @override
  Widget build(BuildContext context) {
    if (proxima == null) {
      return TintedCard(
        background: AppColors.pinkLight,
        child: Row(
          children: [
            _IconeCirculo(
              icone: Icons.event_busy_outlined,
              cor: AppColors.pinkText,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Você não tem aulas agendadas no momento.',
                style: TextStyle(fontSize: 13.5, color: AppColors.pinkText),
              ),
            ),
          ],
        ),
      );
    }

    final data = proxima!.data;
    return TintedCard(
      background: AppColors.pinkLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('PRÓXIMA AULA',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pinkText,
                      letterSpacing: 0.8)),
              const Spacer(),
              _IconeCirculo(
                icone: Icons.content_cut,
                cor: AppColors.pinkText,
                tamanho: 34,
                tamanhoIcone: 17,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _capitalizar(DateFormat("EEEE", 'pt_BR').format(data)),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat("d 'de' MMMM", 'pt_BR').format(data)} · '
            '${DateFormat("HH:mm").format(data)} · ${proxima!.periodo.label}',
            style: const TextStyle(fontSize: 13, color: AppColors.pinkText),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Aviso exibido quando a aluna atinge o limite de aulas do mês.
/// Apenas informa (não bloqueia): as próximas aulas entram como aula extra
/// e a cobrança fica pendente para a professora.
class _AvisoLimite extends StatelessWidget {
  final int limiteMensal;
  const _AvisoLimite({required this.limiteMensal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningText.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.warningText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você já usou suas $limiteMensal aulas deste mês',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Novas aulas entram como aula extra (com custo, combinado com a professora).',
                  style: TextStyle(fontSize: 12, color: AppColors.warningText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de indicador simples (número em destaque + rótulo).
class _StatCard extends StatelessWidget {
  final Color background;
  final Color labelColor;
  final String label;
  final IconData icone;
  final String valor;
  final String complemento;

  const _StatCard({
    required this.background,
    required this.labelColor,
    required this.label,
    required this.icone,
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
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: labelColor,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(valor,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              if (complemento.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(complemento,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Indicador do próximo pagamento pendente/atrasado (dado real).
class _CardProximoPagamento extends StatelessWidget {
  final AsyncValue<List<Pagamento>> pagamentosAsync;
  const _CardProximoPagamento({required this.pagamentosAsync});

  @override
  Widget build(BuildContext context) {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    return TintedCard(
      background: AppColors.lilacLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card_outlined,
                  size: 16, color: AppColors.lilacText),
              SizedBox(width: 6),
              Expanded(
                child: Text('Próximo pagamento',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lilacText,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          pagamentosAsync.when(
            loading: () => const Text('—', style: TextStyle(fontSize: 22)),
            error: (e, st) => const Text('—', style: TextStyle(fontSize: 22)),
            data: (lista) {
              final pendentes = lista
                  .where((p) => p.status != StatusPagamento.pago)
                  .toList()
                ..sort((a, b) => a.vencimento.compareTo(b.vencimento));

              if (pendentes.isEmpty) {
                return const Text('Em dia',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successText));
              }

              final p = pendentes.first;
              final atrasado = p.status == StatusPagamento.atrasado;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(moeda.format(p.valor),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${atrasado ? 'Venceu' : 'Vence'} '
                    '${DateFormat("dd/MM").format(p.vencimento)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: atrasado
                            ? AppColors.dangerText
                            : AppColors.textSecondary),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconeCirculo extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final double tamanho;
  final double tamanhoIcone;

  const _IconeCirculo({
    required this.icone,
    required this.cor,
    this.tamanho = 44,
    this.tamanhoIcone = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icone, size: tamanhoIcone, color: cor),
    );
  }
}
