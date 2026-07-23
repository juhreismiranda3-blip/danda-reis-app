import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = DateTime.now();
    final aulasAsync =
        ref.watch(todasAsAulasDoMesProvider(DateTime(hoje.year, hoje.month)));
    final pagamentosPendentesAsync = ref.watch(pagamentosPendentesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: aulasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (aulas) {
          final realizadas =
              aulas.where((a) => a.status == StatusAula.concluida).length;
          final faltas =
              aulas.where((a) => a.status == StatusAula.falta).length;
          final remarcadas =
              aulas.where((a) => a.status == StatusAula.remarcada).length;
          final extrasVendidas =
              aulas.where((a) => a.origem == OrigemAula.extra).length;
          final alunasUnicas = aulas.map((a) => a.alunaId).toSet().length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _Indicador(
                    icone: Icons.groups_outlined,
                    label: 'Alunas no mês',
                    valor: '$alunasUnicas',
                    fundo: AppColors.pinkLight,
                    cor: AppColors.pinkText,
                  ),
                  _Indicador(
                    icone: Icons.check_circle_outline,
                    label: 'Aulas realizadas',
                    valor: '$realizadas',
                    fundo: AppColors.lilacLight,
                    cor: AppColors.lilacText,
                  ),
                  _Indicador(
                    icone: Icons.event_busy_outlined,
                    label: 'Faltas',
                    valor: '$faltas',
                    fundo: AppColors.lilacLight,
                    cor: AppColors.lilacText,
                  ),
                  _Indicador(
                    icone: Icons.event_repeat,
                    label: 'Remarcações',
                    valor: '$remarcadas',
                    fundo: AppColors.pinkLight,
                    cor: AppColors.pinkText,
                  ),
                  _Indicador(
                    icone: Icons.add_circle_outline,
                    label: 'Aulas extras',
                    valor: '$extrasVendidas',
                    fundo: AppColors.pinkLight,
                    cor: AppColors.pinkText,
                  ),
                  pagamentosPendentesAsync.when(
                    data: (lista) => _Indicador(
                      icone: Icons.credit_card_outlined,
                      label: 'Pagam. pendentes',
                      valor: '${lista.length}',
                      fundo: AppColors.lilacLight,
                      cor: AppColors.lilacText,
                    ),
                    loading: () => const _Indicador(
                      icone: Icons.credit_card_outlined,
                      label: 'Pagam. pendentes',
                      valor: '—',
                      fundo: AppColors.lilacLight,
                      cor: AppColors.lilacText,
                    ),
                    error: (e, st) => const _Indicador(
                      icone: Icons.credit_card_outlined,
                      label: 'Pagam. pendentes',
                      valor: '—',
                      fundo: AppColors.lilacLight,
                      cor: AppColors.lilacText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aulas por status',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const labels = [
                                    'Realiz.',
                                    'Faltas',
                                    'Remarc.',
                                    'Extras'
                                  ];
                                  final i = value.toInt();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      i < labels.length ? labels[i] : '',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            _barra(0, realizadas.toDouble(),
                                AppColors.successText),
                            _barra(1, faltas.toDouble(), AppColors.dangerText),
                            _barra(
                                2, remarcadas.toDouble(), AppColors.pinkAccent),
                            _barra(3, extrasVendidas.toDouble(),
                                AppColors.lilacText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BarChartGroupData _barra(int x, double valor, Color cor) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
          toY: valor,
          color: cor,
          width: 22,
          borderRadius: BorderRadius.circular(6)),
    ]);
  }
}

class _Indicador extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;
  final Color fundo;
  final Color cor;

  const _Indicador({
    required this.icone,
    required this.label,
    required this.valor,
    required this.fundo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icone, size: 18, color: cor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: cor, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
