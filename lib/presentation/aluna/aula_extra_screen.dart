import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/turma.dart';
import '../../providers/providers.dart';

/// Fluxo: escolher data com vaga -> escolher período -> confirmar.
/// O valor da aula extra é somado à mensalidade pendente da aluna (não é
/// cobrança avulsa) e a aula é confirmada quando a professora dá baixa.
class AulaExtraScreen extends ConsumerStatefulWidget {
  const AulaExtraScreen({super.key});

  @override
  ConsumerState<AulaExtraScreen> createState() => _AulaExtraScreenState();
}

class _AulaExtraScreenState extends ConsumerState<AulaExtraScreen> {
  static const valorAulaExtra = 40.0; // TODO: buscar de configuração/pacote

  DateTime? _dataEscolhida;
  Periodo? _periodoEscolhido;
  bool _enviando = false;

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 60)),
      initialDate: agora,
      selectableDayPredicate: (d) => d.weekday <= DateTime.thursday,
    );
    if (data != null) {
      setState(() {
        _dataEscolhida = data;
        _periodoEscolhido = null;
      });
    }
  }

  Future<void> _confirmarCompra(String alunaId) async {
    if (_dataEscolhida == null || _periodoEscolhido == null) return;
    setState(() => _enviando = true);
    try {
      final aula = await ref.read(aulaRepositoryProvider).comprarAulaExtra(
            alunaId: alunaId,
            data: _dataEscolhida!,
            periodo: _periodoEscolhido!,
          );
      await ref.read(pagamentoRepositoryProvider).incluirAulaExtraNaMensalidade(
            alunaId: alunaId,
            valorAula: valorAulaExtra,
            aulaExtraId: aula.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aula extra reservada! O valor foi somado à sua mensalidade.'),
          ),
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

  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    final disponibilidade = _dataEscolhida == null
        ? null
        : ref.watch(disponibilidadeDoDiaProvider(_dataEscolhida!));

    return Scaffold(
      appBar: AppBar(title: const Text('Aula extra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cartão de valor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pinkLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppColors.pinkText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Valor da aula extra',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.pinkText)),
                      Text(_moeda.format(valorAulaExtra),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.warningText),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O valor é somado à sua mensalidade pendente. A vaga é '
                    'reservada assim que você confirma.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.warningText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text('Escolha a data',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _escolherData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.pinkText),
                  const SizedBox(width: 12),
                  Text(
                    _dataEscolhida == null
                        ? 'Escolher data'
                        : _capitalizar(DateFormat("EEEE, d 'de' MMMM", 'pt_BR')
                            .format(_dataEscolhida!)),
                    style: TextStyle(
                      fontSize: 14,
                      color: _dataEscolhida == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: _dataEscolhida == null
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          if (disponibilidade != null) ...[
            const SizedBox(height: 20),
            const Text('Períodos disponíveis',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            disponibilidade.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Text('Erro: $e'),
              data: (lista) => Column(
                children: lista.map((disp) {
                  return _PeriodoTile(
                    disponibilidade: disp,
                    selecionado: _periodoEscolhido == disp.periodo,
                    onTap: disp.temVaga
                        ? () => setState(() => _periodoEscolhido = disp.periodo)
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_dataEscolhida == null ||
                    _periodoEscolhido == null ||
                    _enviando ||
                    usuario == null)
                ? null
                : () => _confirmarCompra(usuario.id),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15)),
            child: _enviando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reservar aula extra'),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Icon(
                    temVaga ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: temVaga
                        ? AppColors.successText
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    temVaga
                        ? '${disponibilidade.vagasDisponiveis} vagas'
                        : 'Sem vagas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: temVaga
                          ? AppColors.successText
                          : AppColors.textMuted,
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
