import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../domain/entities/turma.dart';
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
    final saldoAsync = ref.watch(saldoPacoteDaAlunaProvider(usuario.id));

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
                const Text('Olá,', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(usuario.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
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
        data: (aulas) => _Conteudo(aulas: aulas, saldoAsync: saldoAsync),
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
  }
}

class _Conteudo extends ConsumerWidget {
  final List<Aula> aulas;
  final AsyncValue saldoAsync;
  const _Conteudo({required this.aulas, required this.saldoAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aulasAtivas = aulas.where((a) => a.status != StatusAula.cancelada).toList();
    final proxima = aulasAtivas
        .where((a) => a.status == StatusAula.agendada && a.data.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (proxima.isNotEmpty)
          TintedCard(
            background: AppColors.pinkLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRÓXIMA AULA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.pinkText,
                        letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(
                  DateFormat("EEEE 'às' HH:mm", 'pt_BR').format(proxima.first.data),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(proxima.first.periodo.label,
                    style: const TextStyle(fontSize: 13, color: AppColors.pinkText)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TintedCard(
                background: AppColors.lilacLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aulas restantes',
                        style: TextStyle(fontSize: 11, color: AppColors.lilacText, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    saldoAsync.when(
                      data: (saldo) => Text('${saldo.restantes} de ${saldo.totalDoPacote}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                      loading: () => const Text('—', style: TextStyle(fontSize: 20)),
                      error: (e, st) => const Text('—', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TintedCard(
                background: AppColors.lilacLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Próximo pagamento',
                        style: TextStyle(fontSize: 11, color: AppColors.lilacText, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    // TODO: substituir por dado real do PagamentoRepository
                    // (pagamentosDaAlunaProvider, primeiro pendente/atrasado).
                    const Text('Ver em Pagamentos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
