import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/turma.dart';
import '../../providers/providers.dart';

/// Fluxo de remarcação (regra de negócio confirmada com a cliente):
/// 1. Aluna escolhe apenas o DIA.
/// 2. App mostra os PERÍODOS disponíveis naquele dia (nunca a turma/horário).
/// 3. Aluna escolhe o período; o sistema encontra a vaga automaticamente.
class RemarcacaoScreen extends ConsumerStatefulWidget {
  final String aulaId;
  const RemarcacaoScreen({super.key, required this.aulaId});

  @override
  ConsumerState<RemarcacaoScreen> createState() => _RemarcacaoScreenState();
}

class _RemarcacaoScreenState extends ConsumerState<RemarcacaoScreen> {
  late DateTime _diaSelecionado;
  Periodo? _periodoSelecionado;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _diaSelecionado = _proximoDiaUtil(DateTime.now());
  }

  /// A escola funciona de segunda a quinta — pula sexta/sábado/domingo.
  DateTime _proximoDiaUtil(DateTime partirDe) {
    var dia = partirDe;
    while (dia.weekday > DateTime.thursday) {
      dia = dia.add(const Duration(days: 1));
    }
    return dia;
  }

  List<DateTime> _proximosDiasUteis(int quantidade) {
    final dias = <DateTime>[];
    var cursor = DateTime.now();
    while (dias.length < quantidade) {
      cursor = cursor.add(const Duration(days: 1));
      if (cursor.weekday <= DateTime.thursday) dias.add(cursor);
    }
    return dias;
  }

  Future<void> _confirmar(String alunaId) async {
    if (_periodoSelecionado == null) return;
    setState(() => _enviando = true);
    try {
      await ref.read(aulaRepositoryProvider).solicitarRemarcacao(
            alunaId: alunaId,
            aulaOriginalId: widget.aulaId,
            novaData: _diaSelecionado,
            novoPeriodo: _periodoSelecionado!,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada! Aguarde a aprovação da professora.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    final disponibilidade = ref.watch(disponibilidadeDoDiaProvider(_diaSelecionado));
    final dias = _proximosDiasUteis(4);

    return Scaffold(
      appBar: AppBar(title: const Text('Remarcar aula')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Escolha o dia', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: dias.map((dia) {
              return Expanded(
                child: _DiaChip(
                  dia: dia,
                  selecionado: _mesmoDia(dia, _diaSelecionado),
                  onTap: () => setState(() {
                    _diaSelecionado = dia;
                    _periodoSelecionado = null;
                  }),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const _LegendaVaga(),
          const SizedBox(height: 20),
          Text(
            'Períodos disponíveis · ${DateFormat('EEEE', 'pt_BR').format(_diaSelecionado)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          disponibilidade.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Erro ao verificar disponibilidade: $e'),
            data: (lista) => Column(
              children: lista.map((disp) {
                final selecionado = _periodoSelecionado == disp.periodo;
                return _PeriodoTile(
                  disponibilidade: disp,
                  selecionado: selecionado,
                  onTap: disp.temVaga
                      ? () => setState(() => _periodoSelecionado = disp.periodo)
                      : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_periodoSelecionado == null || _enviando || usuario == null)
                ? null
                : () => _confirmar(usuario.id),
            child: _enviando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirmar solicitação'),
          ),
          const SizedBox(height: 8),
          const Text(
            'A professora precisa aprovar antes da confirmação final',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Chip de dia no seletor, com um pontinho que indica se aquele dia tem
/// alguma vaga (verde), está lotado (vermelho) ou ainda está carregando.
class _DiaChip extends ConsumerWidget {
  final DateTime dia;
  final bool selecionado;
  final VoidCallback onTap;

  const _DiaChip({
    required this.dia,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disp = ref.watch(disponibilidadeDoDiaProvider(dia));
    final bool? temVaga = disp.maybeWhen(
      data: (lista) => lista.any((d) => d.temVaga),
      orElse: () => null,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.pinkAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionado ? AppColors.pinkAccent : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('E', 'pt_BR').format(dia),
              style: TextStyle(
                fontSize: 10,
                color: selecionado ? Colors.white70 : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${dia.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selecionado ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            _PontoVaga(temVaga: temVaga, selecionado: selecionado),
          ],
        ),
      ),
    );
  }
}

class _PontoVaga extends StatelessWidget {
  final bool? temVaga;
  final bool selecionado;
  const _PontoVaga({required this.temVaga, required this.selecionado});

  @override
  Widget build(BuildContext context) {
    final Color cor;
    if (temVaga == null) {
      cor = selecionado ? Colors.white54 : AppColors.border;
    } else if (temVaga) {
      cor = AppColors.successText;
    } else {
      cor = AppColors.dangerText;
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
    );
  }
}

/// Legenda dos pontinhos de disponibilidade dos dias.
class _LegendaVaga extends StatelessWidget {
  const _LegendaVaga();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _item(AppColors.successText, 'com vaga'),
        const SizedBox(width: 14),
        _item(AppColors.dangerText, 'lotado'),
      ],
    );
  }

  Widget _item(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(texto,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _PeriodoTile extends StatelessWidget {
  final DisponibilidadePeriodo disponibilidade;
  final bool selecionado;
  final VoidCallback? onTap;

  const _PeriodoTile({
    required this.disponibilidade,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final temVaga = disponibilidade.temVaga;
    return Opacity(
      opacity: temVaga ? 1 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.pinkLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selecionado ? AppColors.pinkAccent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(disponibilidade.periodo.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Icon(
                    temVaga ? Icons.check : Icons.close,
                    size: 16,
                    color: temVaga ? AppColors.successText : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    temVaga ? '${disponibilidade.vagasDisponiveis} vagas' : 'Sem vagas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: temVaga ? AppColors.successText : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
