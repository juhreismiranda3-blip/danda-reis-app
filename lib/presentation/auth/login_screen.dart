import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _erro;

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
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.pinkLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.content_cut, color: AppColors.pinkText),
                ),
                const SizedBox(height: 12),
                Text('Danda Reis', style: Theme.of(context).textTheme.headlineSmall),
                Text('Corte e costura',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 10),
                  Text(_erro!, style: const TextStyle(color: AppColors.dangerText)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _entrarComEmailSenha,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _carregando ? null : _entrarComGoogle,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Entrar com Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
