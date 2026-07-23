import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrarComEmailSenha() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ref.read(authRepositoryProvider).loginComEmailSenha(
            _emailController.text.trim(),
            _senhaController.text,
          );
      // A navegação acontece sozinha via redirect do GoRouter, que reage
      // à mudança de usuarioAtualProvider.
    } catch (e) {
      setState(() => _erro = 'E-mail ou senha incorretos.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ref.read(authRepositoryProvider).loginComGoogle();
    } catch (e) {
      setState(() => _erro = 'Não foi possível entrar com o Google.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lilacLight,
              AppColors.background,
              AppColors.pinkLight,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Voltar para a tela de início
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    onPressed: () => context.go('/inicio'),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppColors.pinkText,
                    tooltip: 'Voltar',
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pinkAccent.withOpacity(0.20),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.content_cut,
                            size: 34, color: AppColors.pinkText),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Danda Reis',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CORTE E COSTURA',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.pinkText,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Cartão de acesso
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.pinkAccent.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bem-vinda de volta',
                                style: textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              'Entre para ver suas aulas e pagamentos.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.mail_outline, size: 20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _senhaController,
                              obscureText: !_senhaVisivel,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  _carregando ? null : _entrarComEmailSenha(),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _senhaVisivel = !_senhaVisivel),
                                  icon: Icon(
                                    _senhaVisivel
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            if (_erro != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _erro!,
                                  style: const TextStyle(
                                      color: AppColors.dangerText, fontSize: 12.5),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _carregando ? null : _entrarComEmailSenha,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: _carregando
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('ou',
                                      style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textMuted)),
                                ),
                                const Expanded(
                                    child: Divider(color: AppColors.border)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _carregando ? null : _entrarComGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 26),
                                label: const Text('Entrar com Google'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Use o e-mail cadastrado na escola.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
