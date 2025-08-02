import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';

enum InfoCardType { info, success, warning, error }

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? icon;
  final InfoCardType type;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
    this.type = InfoCardType.info,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Card(
      elevation: AppDimensions.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: colors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          color: colors.background.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Icon(
                          icon,
                          color: colors.iconColor,
                          size: AppDimensions.iconM,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headlineSmall,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppDimensions.paddingXXS),
                            Text(
                              subtitle!,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (content != null) ...[
                  const SizedBox(height: AppDimensions.paddingM),
                  content!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({Color background, Color iconColor, Color border}) _getColors() {
    switch (type) {
      case InfoCardType.info:
        return (
          background: AppColors.info,
          iconColor: AppColors.info,
          border: AppColors.info,
        );
      case InfoCardType.success:
        return (
          background: AppColors.success,
          iconColor: AppColors.success,
          border: AppColors.success,
        );
      case InfoCardType.warning:
        return (
          background: AppColors.warning,
          iconColor: AppColors.warning,
          border: AppColors.warning,
        );
      case InfoCardType.error:
        return (
          background: AppColors.error,
          iconColor: AppColors.error,
          border: AppColors.error,
        );
    }
  }
}