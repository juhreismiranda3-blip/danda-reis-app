import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

/// Agenda da aluna: as próximas aulas agendadas (da mais próxima para a
/// mais distante). Usa o mesmo provider da home (aulasDaAlunaProvider).
class AgendaAlunaScreen extends ConsumerWidget {
  const AgendaAlunaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final aulasAsync = ref.watch(
      aulasDaAlunaProvider((alunaId: usuario.id, mes: DateTime.now())),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: aulasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (aulas) {
          final agora = DateTime.now();
          final hoje = DateTime(agora.year, agora.month, agora.day);
          final proximas = aulas
              .where((a) =>
                  a.status == StatusAula.agendada && !a.data.isBefore(hoje))
              .toList()
            ..sort((a, b) => a.data.compareTo(b.data));

          if (proximas.isEmpty) {
            return const _AgendaVazia();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Próximas aulas',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ...proximas.map((a) => _AgendaTile(aula: a)),
            ],
          );
        },
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final Aula aula;
  const _AgendaTile({required this.aula});

  @override
  Widget build(BuildContext context) {
    final ehExtra = aula.origem == OrigemAula.extra;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Selo de data
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.pinkLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${aula.data.day}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pinkText,
                        height: 1)),
                Text(
                  DateFormat('MMM', 'pt_BR').format(aula.data).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pinkText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalizar(
                      DateFormat('EEEE', 'pt_BR').format(aula.data)),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(aula.data)} · ${aula.periodo.label}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (ehExtra)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lilacLight,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('Extra',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lilacText)),
            ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _AgendaVazia extends StatelessWidget {
  const _AgendaVazia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 34, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text('Nenhuma aula agendada.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Suas próximas aulas aparecem aqui.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
