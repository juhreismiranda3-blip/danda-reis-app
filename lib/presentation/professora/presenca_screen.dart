import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

/// Tela para a professora marcar Presente / Faltou depois de cada aula.
/// Mostra as aulas do dia atual, de todas as alunas.
class PresencaScreen extends ConsumerWidget {
  const PresencaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = DateTime.now();
    final aulasDoMes = ref.watch(todasAsAulasDoMesProvider(DateTime(hoje.year, hoje.month)));

    return Scaffold(
      appBar: AppBar(title: const Text('Presença de hoje')),
      body: aulasDoMes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (aulas) {
          final aulasDeHoje = aulas.where((a) {
            return a.data.year == hoje.year &&
                a.data.month == hoje.month &&
                a.data.day == hoje.day &&
                a.status == StatusAula.agendada;
          }).toList();

          if (aulasDeHoje.isEmpty) {
            return const Center(
              child: Text('Nenhuma aula agendada para hoje.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: aulasDeHoje.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _AulaPresencaTile(aula: aulasDeHoje[i]),
          );
        },
      ),
    );
  }
}

class _AulaPresencaTile extends ConsumerWidget {
  final Aula aula;
  const _AulaPresencaTile({required this.aula});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // TODO: substituir por nome real (buscar Usuario por alunaId).
              Text(aula.alunaId, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              Text(aula.periodo.label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => ref
                    .read(aulaRepositoryProvider)
                    .marcarPresenca(aula.id, StatusAula.concluida),
                icon: const Icon(Icons.check, size: 16, color: AppColors.successText),
                label: const Text('Presente', style: TextStyle(color: AppColors.successText, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () => ref
                    .read(aulaRepositoryProvider)
                    .marcarPresenca(aula.id, StatusAula.falta),
                icon: const Icon(Icons.close, size: 16, color: AppColors.dangerText),
                label: const Text('Faltou', style: TextStyle(color: AppColors.dangerText, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
