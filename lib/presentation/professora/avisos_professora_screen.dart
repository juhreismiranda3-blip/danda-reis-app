import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class AvisosProfessoraScreen extends ConsumerStatefulWidget {
  const AvisosProfessoraScreen({super.key});

  @override
  ConsumerState<AvisosProfessoraScreen> createState() => _AvisosProfessoraScreenState();
}

class _AvisosProfessoraScreenState extends ConsumerState<AvisosProfessoraScreen> {
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (_tituloController.text.trim().isEmpty || _mensagemController.text.trim().isEmpty) return;
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
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar aviso'),
          ),
          const SizedBox(height: 24),
          const Text('Enviados recentemente',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          avisosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Erro: $e'),
            data: (avisos) => Column(
              children: avisos.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(a.mensagem, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(a.criadoEm),
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
