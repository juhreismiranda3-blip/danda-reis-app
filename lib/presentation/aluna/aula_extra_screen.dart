import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/turma.dart';
import '../../providers/providers.dart';

/// Fluxo: selecionar quantidade -> ver valor -> pagar -> saldo atualizado.
/// Aqui simplificamos para 1 aula extra por vez (comprar mais de uma é
/// só repetir o fluxo) — ajustar conforme regra final de preço/pacote
/// combinada com a cliente.
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
    if (data != null) setState(() => _dataEscolhida = data);
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
      // O valor da aula extra é somado à mensalidade pendente da aluna
      // (não vira uma cobrança avulsa). A aula é confirmada quando a
      // professora dá baixa na mensalidade.
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Valor da aula extra: R\$ ${valorAulaExtra.toStringAsFixed(0)}. '
              'Ela só é confirmada depois que o pagamento é registrado.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.warningText),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _escolherData,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _dataEscolhida == null
                  ? 'Escolher data'
                  : DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_dataEscolhida!),
            ),
          ),
          const SizedBox(height: 16),
          if (disponibilidade != null)
            disponibilidade.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Erro: $e'),
              data: (lista) => Column(
                children: lista.map((disp) {
                  final selecionado = _periodoEscolhido == disp.periodo;
                  return Opacity(
                    opacity: disp.temVaga ? 1 : 0.5,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<Periodo>(
                        value: disp.periodo,
                        groupValue: _periodoEscolhido,
                        onChanged: disp.temVaga
                            ? (v) => setState(() => _periodoEscolhido = v)
                            : null,
                        title: Text(disp.periodo.label),
                        subtitle: Text(disp.temVaga ? '${disp.vagasDisponiveis} vagas' : 'Sem vagas'),
                        tileColor: selecionado ? AppColors.pinkLight : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_dataEscolhida == null ||
                    _periodoEscolhido == null ||
                    _enviando ||
                    usuario == null)
                ? null
                : () => _confirmarCompra(usuario.id),
            child: _enviando
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Solicitar aula extra'),
          ),
        ],
      ),
    );
  }
}
