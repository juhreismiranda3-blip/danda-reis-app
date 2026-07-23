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
    final aulasAsync = ref.watch(todasAsAulasDoMesProvider(DateTime(hoje.year, hoje.month)));
    final pagamentosPendentesAsync = ref.watch(pagamentosPendentesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: aulasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (aulas) {
          final realizadas = aulas.where((a) => a.status == StatusAula.concluida).length;
          final faltas = aulas.where((a) => a.status == StatusAula.falta).length;
          final remarcadas = aulas.where((a) => a.status == StatusAula.remarcada).length;
          final extrasVendidas = aulas.where((a) => a.origem == OrigemAula.extra).length;
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
                childAspectRatio: 1.6,
                children: [
                  _Indicador(label: 'Alunas com aula no mês', valor: '$alunasUnicas'),
                  _Indicador(label: 'Aulas realizadas', valor: '$realizadas'),
                  _Indicador(label: 'Faltas', valor: '$faltas'),
                  _Indicador(label: 'Remarcações', valor: '$remarcadas'),
                  _Indicador(label: 'Aulas extras vendidas', valor: '$extrasVendidas'),
                  pagamentosPendentesAsync.when(
                    data: (lista) => _Indicador(label: 'Pagamentos pendentes', valor: '${lista.length}'),
                    loading: () => const _Indicador(label: 'Pagamentos pendentes', valor: '—'),
                    error: (e, st) => const _Indicador(label: 'Pagamentos pendentes', valor: '—'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Aulas por status',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Realizadas', 'Faltas', 'Remarcadas', 'Extras'];
                            final i = value.toInt();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                i < labels.length ? labels[i] : '',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      _barra(0, realizadas.toDouble(), AppColors.successText),
                      _barra(1, faltas.toDouble(), AppColors.dangerText),
                      _barra(2, remarcadas.toDouble(), AppColors.pinkAccent),
                      _barra(3, extrasVendidas.toDouble(), AppColors.lilacText),
                    ],
                  ),
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
      BarChartRodData(toY: valor, color: cor, width: 22, borderRadius: BorderRadius.circular(6)),
    ]);
  }
}

class _Indicador extends StatelessWidget {
  final String label;
  final String valor;
  const _Indicador({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lilacLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lilacText, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
