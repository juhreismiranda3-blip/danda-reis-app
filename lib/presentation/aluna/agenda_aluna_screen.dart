import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

/// Agenda da aluna: as próximas aulas agendadas. Para cada aula (~1 dia
/// antes ou mais) ela pode Confirmar presença ou dizer que Não vai poder —
/// nesse caso a vaga é liberada e ofertada às demais alunas.
class AgendaAlunaScreen extends ConsumerWidget {
  const AgendaAlunaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final aulasAsync = ref.watch(
      aulasDaAlunaProvider((alunaId: usuario.id, mes: DateTime.now())),
    );
    final ofertas = ref.watch(ofertasAbertasProvider).valueOrNull ?? const [];

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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (ofertas.isNotEmpty) ...[
                _BannerVagas(quantidade: ofertas.length),
                const SizedBox(height: 16),
              ],
              const Text('Próximas aulas',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              if (proximas.isEmpty)
                const _AgendaVazia()
              else
                ...proximas.map((a) => _AgendaTile(aula: a)),
            ],
          );
        },
      ),
    );
  }
}

class _BannerVagas extends StatelessWidget {
  final int quantidade;
  const _BannerVagas({required this.quantidade});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/aluna/vagas'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lilacLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 20, color: AppColors.lilacText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                quantidade == 1
                    ? 'Abriu 1 vaga! Toque para ver.'
                    : 'Abriram $quantidade vagas! Toque para ver.',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lilacText),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lilacText),
          ],
        ),
      ),
    );
  }
}

class _AgendaTile extends ConsumerWidget {
  final Aula aula;
  const _AgendaTile({required this.aula});

  Future<void> _recusar(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Não vai poder vir?'),
        content: const Text(
            'A aula será cancelada e a vaga oferecida às outras alunas. '
            'Você pode remarcar em outro dia, se preferir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, liberar vaga'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await ref.read(aulaRepositoryProvider).recusarAula(aula.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga liberada para as outras alunas.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ehExtra = aula.origem == OrigemAula.extra;
    final confirmada = aula.confirmacao == ConfirmacaoAula.confirmada;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
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
                      DateFormat('MMM', 'pt_BR')
                          .format(aula.data)
                          .toUpperCase(),
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
              if (ehExtra) const _Tag('Extra'),
            ],
          ),
          const SizedBox(height: 12),
          if (confirmada)
            Row(
              children: const [
                Icon(Icons.check_circle,
                    size: 16, color: AppColors.successText),
                SizedBox(width: 6),
                Text('Presença confirmada',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.successText)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _recusar(context, ref),
                    child: const Text('Não vou poder'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(aulaRepositoryProvider)
                        .confirmarAula(aula.id),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Tag extends StatelessWidget {
  final String texto;
  const _Tag(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lilacLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.lilacText)),
    );
  }
}

class _AgendaVazia extends StatelessWidget {
  const _AgendaVazia();

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
          Icon(Icons.calendar_today_outlined,
              size: 30, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text('Nenhuma aula agendada.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          SizedBox(height: 2),
          Text('Suas próximas aulas aparecem aqui.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
