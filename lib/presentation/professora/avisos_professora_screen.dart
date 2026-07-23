import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AvisosProfessoraScreen extends ConsumerStatefulWidget {
  const AvisosProfessoraScreen({super.key});

  @override
  ConsumerState<AvisosProfessoraScreen> createState() =>
      _AvisosProfessoraScreenState();
}

class _AvisosProfessoraScreenState
    extends ConsumerState<AvisosProfessoraScreen> {
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_tituloController.text.trim().isEmpty ||
        _mensagemController.text.trim().isEmpty) {
      return;
    }
    setState(() => _enviando = true);
    try {
      await ref.read(avisoRepositoryProvider).enviarAviso(
            titulo: _tituloController.text.trim(),
            mensagem: _mensagemController.text.trim(),
          );
      _tituloController.clear();
      _mensagemController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aviso enviado para todas as alunas.')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avisosAsync = ref.watch(avisosRecentesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card de composição
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.pinkLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_outlined,
                          size: 20, color: AppColors.pinkText),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Novo aviso',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mensagemController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mensagem'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: const Text('Enviar para todas'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Enviados recentemente',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          avisosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Erro: $e'),
            data: (avisos) {
              if (avisos.isEmpty) {
                return const _VazioAvisos();
              }
              return Column(
                children: avisos.map((a) => _AvisoCard(
                      titulo: a.titulo,
                      mensagem: a.mensagem,
                      criadoEm: a.criadoEm,
                    )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final DateTime criadoEm;

  const _AvisoCard({
    required this.titulo,
    required this.mensagem,
    required this.criadoEm,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.lilacLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_outlined,
                size: 17, color: AppColors.lilacText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(mensagem,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(DateFormat('dd/MM/yyyy · HH:mm').format(criadoEm),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VazioAvisos extends StatelessWidget {
  const _VazioAvisos();

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
          Icon(Icons.inbox_outlined, size: 26, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('Nenhum aviso enviado ainda.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
