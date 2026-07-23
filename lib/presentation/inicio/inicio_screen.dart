import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Tela de início (boas-vindas) do aplicativo.
///
/// É a primeira tela exibida quando o app abre e o usuário ainda não está
/// logado. Apresenta a marca "Danda Reis — Corte e Costura", um resumo do
/// que o app faz e um botão que leva ao login. Visual premium (inspiração
/// Apple HIG): muito espaço em branco, sombras suaves, degradê discreto e
/// uma animação de entrada escalonada. Não usa pacotes externos.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cria uma animação de fade + subida que começa e termina dentro de um
  /// intervalo do controller, permitindo o efeito escalonado entre elementos.
  Animation<double> _intervalo(double inicio, double fim) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(inicio, fim, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Fundo em degradê suave
          const _FundoDecorativo(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  _Surge(
                    animacao: _intervalo(0.0, 0.5),
                    child: Center(child: _Logo()),
                  ),
                  const SizedBox(height: 28),
                  // Nome do app
                  _Surge(
                    animacao: _intervalo(0.12, 0.6),
                    child: Column(
                      children: [
                        Text(
                          'Danda Reis',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'CORTE E COSTURA',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.pinkText,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tagline
                  _Surge(
                    animacao: _intervalo(0.22, 0.7),
                    child: Text(
                      'Tudo o que você precisa da sua escola\nde costura, em um só lugar.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Destaques
                  _Surge(
                    animacao: _intervalo(0.34, 0.82),
                    child: const _CartaoDestaques(),
                  ),
                  const Spacer(flex: 2),
                  // Botão principal
                  _Surge(
                    animacao: _intervalo(0.5, 1.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Entrar'),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Acesse com o e-mail cadastrado na escola',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo circular com o ícone de tesoura e uma sombra rosada suave.
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.pinkAccent.withOpacity(0.20),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.content_cut,
        size: 46,
        color: AppColors.pinkText,
      ),
    );
  }
}

/// Cartão com os principais recursos do app, para dar contexto na primeira
/// abertura sem parecer um formulário.
class _CartaoDestaques extends StatelessWidget {
  const _CartaoDestaques();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.pinkAccent.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          _LinhaDestaque(
            icone: Icons.event_available_outlined,
            titulo: 'Aulas e remarcações',
            descricao: 'Veja sua agenda e remarque com poucos toques.',
          ),
          _Divisoria(),
          _LinhaDestaque(
            icone: Icons.credit_card_outlined,
            titulo: 'Pagamentos',
            descricao: 'Acompanhe o que está pago, pendente ou atrasado.',
          ),
          _Divisoria(),
          _LinhaDestaque(
            icone: Icons.campaign_outlined,
            titulo: 'Avisos',
            descricao: 'Receba os comunicados da professora na hora.',
          ),
        ],
      ),
    );
  }
}

class _LinhaDestaque extends StatelessWidget {
  const _LinhaDestaque({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.pinkLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 22, color: AppColors.pinkText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divisoria extends StatelessWidget {
  const _Divisoria();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }
}

/// Envolve um filho com a animação de fade + subida controlada por [animacao].
class _Surge extends StatelessWidget {
  const _Surge({required this.animacao, required this.child});

  final Animation<double> animacao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, filho) {
        return Opacity(
          opacity: animacao.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animacao.value) * 22),
            child: filho,
          ),
        );
      },
      child: child,
    );
  }
}

/// Fundo em degradê com dois "brilhos" circulares bem suaves, dando
/// profundidade sem poluir a tela.
class _FundoDecorativo extends StatelessWidget {
  const _FundoDecorativo();

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Brilho(
              cor: AppColors.pinkAccent.withOpacity(0.10),
              tamanho: 240,
            ),
          ),
          Positioned(
            bottom: -70,
            left: -70,
            child: _Brilho(
              cor: AppColors.lilacText.withOpacity(0.08),
              tamanho: 220,
            ),
          ),
        ],
      ),
    );
  }
}

class _Brilho extends StatelessWidget {
  const _Brilho({required this.cor, required this.tamanho});

  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [cor, cor.withOpacity(0)],
        ),
      ),
    );
  }
}
