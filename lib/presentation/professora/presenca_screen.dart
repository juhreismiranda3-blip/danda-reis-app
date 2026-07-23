import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

/// Tela para a professora marcar Presente / Faltou depois de cada aula.
/// Mostra as aulas agendadas do dia atual, de todas as alunas.
class PresencaScreen extends ConsumerWidget {
  const PresencaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = DateTime.now();
    final aulasDoMes =
        ref.watch(todasAsAulasDoMesProvider(DateTime(hoje.year, hoje.month)));

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
          }).toList()
            ..sort((a, b) => a.periodo.index.compareTo(b.periodo.index));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _capitalizar(
                    DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(hoje)),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                aulasDeHoje.isEmpty
                    ? 'Sem aulas para marcar'
                    : '${aulasDeHoje.length} aula${aulasDeHoje.length > 1 ? 's' : ''} para marcar',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (aulasDeHoje.isEmpty)
                const _VazioPresenca()
              else
                ...aulasDeHoje.map((a) => _AulaPresencaTile(aula: a)),
            ],
          );
        },
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _AulaPresencaTile extends ConsumerWidget {
  final Aula aula;
  const _AulaPresencaTile({required this.aula});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.pinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    size: 18, color: AppColors.pinkText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO: substituir por nome real (buscar Usuario por alunaId).
                    Text(aula.alunaId,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(aula.periodo.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BotaoPresenca(
                  label: 'Presente',
                  icone: Icons.check,
                  corTexto: AppColors.successText,
                  corFundo: AppColors.successBg,
                  onTap: () => ref
                      .read(aulaRepositoryProvider)
                      .marcarPresenca(aula.id, StatusAula.concluida),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BotaoPresenca(
                  label: 'Faltou',
                  icone: Icons.close,
                  corTexto: AppColors.dangerText,
                  corFundo: AppColors.dangerBg,
                  onTap: () => ref
                      .read(aulaRepositoryProvider)
                      .marcarPresenca(aula.id, StatusAula.falta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotaoPresenca extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color corTexto;
  final Color corFundo;
  final VoidCallback onTap;

  const _BotaoPresenca({
    required this.label,
    required this.icone,
    required this.corTexto,
    required this.corFundo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: corFundo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 17, color: corTexto),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: corTexto)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VazioPresenca extends StatelessWidget {
  const _VazioPresenca();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_outlined,
              size: 28, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('Nenhuma aula agendada para hoje.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
