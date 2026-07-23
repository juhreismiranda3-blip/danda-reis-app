import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../domain/entities/turma.dart';
import '../../domain/entities/usuario.dart';
import '../../providers/providers.dart';
import '../shared/widgets/app_card.dart';

/// Perfil da aluna: dados pessoais, informações do plano e histórico das
/// aulas do mês. O histórico usa as aulas já carregadas pelo mesmo provider
/// da home (aulasDaAlunaProvider).
class PerfilAlunaScreen extends ConsumerWidget {
  const PerfilAlunaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final aulasAsync = ref.watch(
      aulasDaAlunaProvider((alunaId: usuario.id, mes: DateTime.now())),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Cabecalho(usuario: usuario),
          const SizedBox(height: 16),
          _InfoPlano(usuario: usuario),
          const SizedBox(height: 24),
          const Text('Histórico do mês',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          aulasAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Erro: $e'),
            data: (aulas) {
              final historico = aulas
                  .where((a) => a.status != StatusAula.cancelada)
                  .toList()
                ..sort((a, b) => b.data.compareTo(a.data));
              if (historico.isEmpty) {
                return const _VazioHistorico();
              }
              return Column(
                children:
                    historico.map((a) => _HistoricoTile(aula: a)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(authRepositoryProvider).logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final Usuario usuario;
  const _Cabecalho({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _iniciais(usuario.nome),
              style: const TextStyle(
                  color: AppColors.pinkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.nome,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(usuario.email,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.pinkText)),
                if (usuario.telefone != null) ...[
                  const SizedBox(height: 1),
                  Text(usuario.telefone!,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}

class _InfoPlano extends StatelessWidget {
  final Usuario usuario;
  const _InfoPlano({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final aula = _turmaFixaLabel(usuario);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _LinhaInfo(
            icone: Icons.event_available_outlined,
            label: 'Aulas por mês',
            valor: '${usuario.aulasPorMes}',
          ),
          const Divider(height: 1, color: AppColors.border),
          _LinhaInfo(
            icone: Icons.schedule_outlined,
            label: 'Turma fixa',
            valor: aula ?? 'A definir',
          ),
          if (usuario.dataInicio != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _LinhaInfo(
              icone: Icons.flag_outlined,
              label: 'Início',
              valor: DateFormat('dd/MM/yyyy').format(usuario.dataInicio!),
            ),
          ],
        ],
      ),
    );
  }

  String? _turmaFixaLabel(Usuario u) {
    if (u.diaFixo == null && u.periodoFixo == null) return null;
    final dia = u.diaFixo != null
        ? DiaSemana.values.byName(u.diaFixo!).label
        : null;
    final periodo = u.periodoFixo != null
        ? Periodo.values.byName(u.periodoFixo!).label
        : null;
    return [dia, periodo].where((e) => e != null).join(' · ');
  }
}

class _LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _LinhaInfo({
    required this.icone,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.pinkText),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(valor,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  final Aula aula;
  const _HistoricoTile({required this.aula});

  @override
  Widget build(BuildContext context) {
    final pill = switch (aula.status) {
      StatusAula.concluida => StatusPill.sucesso('Concluída'),
      StatusAula.falta => StatusPill.perigo('Faltou'),
      StatusAula.remarcada => StatusPill.aviso('Remarcada'),
      _ => const StatusPill(
          label: 'Agendada',
          background: AppColors.lilacLight,
          textColor: AppColors.lilacText,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalizar(
                      DateFormat("EEE, dd/MM", 'pt_BR').format(aula.data)),
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 1),
                Text(
                  aula.origem == OrigemAula.extra
                      ? '${aula.periodo.label} · Aula extra'
                      : aula.periodo.label,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          pill,
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _VazioHistorico extends StatelessWidget {
  const _VazioHistorico();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, size: 26, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('Nenhuma aula neste mês ainda.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
