import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/turma.dart';
import '../../providers/providers.dart';

/// Cadastros da professora: alunas (cria a conta de login via Cloud
/// Function) e turmas (dia, período, horário e capacidade).
class CadastrosScreen extends StatelessWidget {
  const CadastrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cadastros'),
          bottom: const TabBar(
            labelColor: AppColors.pinkText,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.pinkAccent,
            tabs: [
              Tab(text: 'Alunas'),
              Tab(text: 'Turmas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AlunasTab(), _TurmasTab()],
        ),
      ),
    );
  }
}

// ============================ ALUNAS ============================

class _AlunasTab extends ConsumerStatefulWidget {
  const _AlunasTab();

  @override
  ConsumerState<_AlunasTab> createState() => _AlunasTabState();
}

class _AlunasTabState extends ConsumerState<_AlunasTab> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  Turma? _turma;
  int _aulasPorMes = 4;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_nome.text.trim().isEmpty || _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e e-mail.')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final conta = await ref.read(authRepositoryProvider).criarContaAluna(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            telefone: _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
            turmaId: _turma?.id,
            diaFixo: _turma?.diaSemana.name,
            periodoFixo: _turma?.periodo.name,
            aulasPorMes: _aulasPorMes,
          );
      if (!mounted) return;
      _nome.clear();
      _email.clear();
      _telefone.clear();
      setState(() => _turma = null);
      _mostrarSucesso(conta.linkDefinirSenha);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarSucesso(String? link) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aluna cadastrada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A conta foi criada. Envie o link abaixo para a aluna definir '
              'a senha e entrar no app.',
              style: TextStyle(fontSize: 13),
            ),
            if (link != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lilacLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(link,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.lilacText)),
              ),
            ],
          ],
        ),
        actions: [
          if (link != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado!')),
                );
              },
              child: const Text('Copiar link'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final turmasAsync = ref.watch(turmasProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nova aluna',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Cria o login da aluna e o perfil dela no app.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nome,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome completo'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _telefone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Telefone (opcional)'),
        ),
        const SizedBox(height: 12),
        turmasAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, st) => Text('Erro ao carregar turmas: $e'),
          data: (turmas) => DropdownButtonFormField<Turma>(
            value: _turma,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Turma fixa'),
            items: turmas
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        '${t.nome} · ${t.diaSemana.label} ${t.periodo.label}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (t) => setState(() => _turma = t),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Aulas por mês',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            _Stepper(
              valor: _aulasPorMes,
              onChanged: (v) => setState(() => _aulasPorMes = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _salvando ? null : _cadastrar,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15)),
            child: _salvando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Cadastrar aluna'),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _botao(Icons.remove, () => onChanged((valor - 1).clamp(1, 31))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$valor',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        _botao(Icons.add, () => onChanged((valor + 1).clamp(1, 31))),
      ],
    );
  }

  Widget _botao(IconData icone, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.pinkLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 18, color: AppColors.pinkText),
      ),
    );
  }
}

// ============================ TURMAS ============================

class _TurmasTab extends ConsumerWidget {
  const _TurmasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turmasAsync = ref.watch(turmasProvider);

    return Stack(
      children: [
        turmasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Erro: $e')),
          data: (turmas) {
            if (turmas.isEmpty) {
              return const Center(
                child: Text('Nenhuma turma cadastrada ainda.',
                    style: TextStyle(color: AppColors.textMuted)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: turmas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TurmaCard(turma: turmas[i]),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.pinkAccent,
            foregroundColor: Colors.white,
            onPressed: () => _abrirFormTurma(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nova turma'),
          ),
        ),
      ],
    );
  }

  void _abrirFormTurma(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FormTurma(),
    );
  }
}

class _TurmaCard extends StatelessWidget {
  final Turma turma;
  const _TurmaCard({required this.turma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lilacLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined,
                size: 20, color: AppColors.lilacText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(turma.nome,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${turma.diaSemana.label} · ${turma.periodo.label} · '
                  '${turma.horarioInicio}–${turma.horarioFim}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${turma.capacidadeMaxima}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('vagas',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormTurma extends ConsumerStatefulWidget {
  const _FormTurma();

  @override
  ConsumerState<_FormTurma> createState() => _FormTurmaState();
}

class _FormTurmaState extends ConsumerState<_FormTurma> {
  final _nome = TextEditingController();
  final _inicio = TextEditingController(text: '09:00');
  final _fim = TextEditingController(text: '11:00');
  DiaSemana _dia = DiaSemana.segunda;
  Periodo _periodo = Periodo.manha;
  int _capacidade = 6;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _inicio.dispose();
    _fim.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome para a turma.')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(turmaRepositoryProvider).criarTurma(Turma(
            id: '',
            nome: _nome.text.trim(),
            diaSemana: _dia,
            periodo: _periodo,
            horarioInicio: _inicio.text.trim(),
            horarioFim: _fim.text.trim(),
            capacidadeMaxima: _capacidade,
          ));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turma criada!')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Text('Nova turma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _nome,
              decoration: const InputDecoration(
                  labelText: 'Nome (ex: Turma Segunda Manhã)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DiaSemana>(
                    value: _dia,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Dia'),
                    items: DiaSemana.values
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text(d.label)))
                        .toList(),
                    onChanged: (d) => setState(() => _dia = d!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Periodo>(
                    value: _periodo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Período'),
                    items: Periodo.values
                        .map((p) => DropdownMenuItem(
                            value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: (p) => setState(() => _periodo = p!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inicio,
                    decoration: const InputDecoration(labelText: 'Início'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _fim,
                    decoration: const InputDecoration(labelText: 'Fim'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Capacidade',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                _Stepper(
                  valor: _capacidade,
                  onChanged: (v) => setState(() => _capacidade = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _salvando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Criar turma'),
            ),
          ],
        ),
      ),
    );
  }
}
