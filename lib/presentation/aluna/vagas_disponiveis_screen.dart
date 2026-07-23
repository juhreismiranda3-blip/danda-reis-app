import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/aula.dart';
import '../../providers/providers.dart';

/// Vagas que abriram porque uma aluna recusou a aula. A primeira que aceitar
/// leva; para quem aceita, conta como aula extra (somada à mensalidade).
class VagasDisponiveisScreen extends ConsumerWidget {
  const VagasDisponiveisScreen({super.key});

  // TODO: buscar de configuração (mesmo valor da aula extra).
  static const valorAulaExtra = 40.0;

  Future<void> _aceitar(
      BuildContext context, WidgetRef ref, String alunaId, OfertaVaga oferta) async {
    try {
      final aula = await ref.read(aulaRepositoryProvider).aceitarOferta(
            ofertaId: oferta.id,
            alunaId: alunaId,
          );
      await ref.read(pagamentoRepositoryProvider).incluirAulaExtraNaMensalidade(
            alunaId: alunaId,
            valorAula: valorAulaExtra,
            aulaExtraId: aula.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaga garantida! O valor foi somado à sua mensalidade.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
    if (usuario == null) return const SizedBox.shrink();

    final ofertasAsync = ref.watch(ofertasAbertasProvider);
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    return Scaffold(
      appBar: AppBar(title: const Text('Vagas abertas')),
      body: ofertasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
        data: (ofertas) {
          // Não oferece de volta a vaga que a própria aluna liberou.
          final lista =
              ofertas.where((o) => o.origemAlunaId != usuario.id).toList();
          if (lista.isEmpty) {
            return const _SemVagas();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'A primeira que aceitar fica com a vaga. Conta como aula '
                  'extra: ${moeda.format(valorAulaExtra)} somados à mensalidade.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.warningText, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              ...lista.map((o) => _OfertaCard(
                    oferta: o,
                    onAceitar: () => _aceitar(context, ref, usuario.id, o),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  final OfertaVaga oferta;
  final VoidCallback onAceitar;

  const _OfertaCard({required this.oferta, required this.onAceitar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.pinkLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_outlined,
                size: 22, color: AppColors.pinkText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalizar(
                      DateFormat("EEEE, dd/MM", 'pt_BR').format(oferta.data)),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(oferta.data)} · ${oferta.periodo.label}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAceitar,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Quero', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SemVagas extends StatelessWidget {
  const _SemVagas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_available_outlined,
                size: 34, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Nenhuma vaga aberta agora.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('Quando abrir, a gente te avisa por notificação.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
