import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';

enum ButtonSize { small, medium, large }
enum ButtonVariant { primary, secondary, outline, danger }

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.large,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final height = _getHeight();
    final textStyle = _getTextStyle();
    final colors = _getColors();

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _getIconSize(), color: colors.foreground),
                const SizedBox(width: AppDimensions.paddingXS),
              ],
              Text(text, style: textStyle.copyWith(color: colors.foreground)),
            ],
          );

    final button = variant == ButtonVariant.outline
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(isFullWidth ? double.infinity : 0, height),
              side: BorderSide(color: colors.background, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _getPadding(),
                vertical: AppDimensions.paddingS,
              ),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isFullWidth ? double.infinity : 0, height),
              backgroundColor: colors.background,
              foregroundColor: colors.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _getPadding(),
                vertical: AppDimensions.paddingS,
              ),
              elevation: variant == ButtonVariant.primary ? 2 : 0,
            ),
            child: child,
          );

    return button;
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.iconS;
      case ButtonSize.medium:
        return AppDimensions.iconM;
      case ButtonSize.large:
        return AppDimensions.iconL;
    }
  }

  double _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.paddingM;
      case ButtonSize.medium:
        return AppDimensions.paddingL;
      case ButtonSize.large:
        return AppDimensions.paddingXL;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  ({Color background, Color foreground}) _getColors() {
    switch (variant) {
      case ButtonVariant.primary:
        return (background: AppColors.primaryBlue, foreground: AppColors.white);
      case ButtonVariant.secondary:
        return (background: AppColors.secondaryGreen, foreground: AppColors.white);
      case ButtonVariant.outline:
        return (background: AppColors.primaryBlue, foreground: AppColors.primaryBlue);
      case ButtonVariant.danger:
        return (background: AppColors.error, foreground: AppColors.white);
    }
  }
}