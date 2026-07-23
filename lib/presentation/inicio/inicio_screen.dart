import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Tela de início (boas-vindas) do aplicativo.
///
/// É a primeira tela exibida quando o app abre e o usuário ainda não está
/// logado. Apresenta a marca "Danda Reis — Corte e Costura" e um botão que
/// leva ao login. Visual premium, com muito espaço em branco e uma animação
/// suave de entrada, seguindo a paleta aprovada com a cliente.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

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
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _EntradaAnimada(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Logo
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pinkAccent.withOpacity(0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 44,
                      color: AppColors.pinkText,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Nome do app
                  Text(
                    'Danda Reis',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Corte e Costura',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.pinkText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Suas aulas, remarcações e pagamentos\nem um só lugar.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  // Botão principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aplica uma animação suave de fade + subida ao conteúdo da tela quando ela
/// é montada, dando um toque premium sem depender de pacotes externos.
class _EntradaAnimada extends StatelessWidget {
  const _EntradaAnimada({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, valor, filho) {
        return Opacity(
          opacity: valor.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - valor) * 24),
            child: filho,
          ),
        );
      },
      child: child,
    );
  }
}
