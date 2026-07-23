import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Card com fundo tintado (rosa ou lilás), usado para destacar informação
/// principal — ex: "Próxima aula" na tela inicial da aluna.
class TintedCard extends StatelessWidget {
  final Widget child;
  final Color background;
  final EdgeInsetsGeometry padding;

  const TintedCard({
    super.key,
    required this.child,
    required this.background,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// Selo de status (Pago / Pendente / Atrasado, Confirmada / Aguardando...).
class StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
  });

  factory StatusPill.sucesso(String label) => StatusPill(
        label: label,
        background: AppColors.successBg,
        textColor: AppColors.successText,
      );

  factory StatusPill.aviso(String label) => StatusPill(
        label: label,
        background: AppColors.warningBg,
        textColor: AppColors.warningText,
      );

  factory StatusPill.perigo(String label) => StatusPill(
        label: label,
        background: AppColors.dangerBg,
        textColor: AppColors.dangerText,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
