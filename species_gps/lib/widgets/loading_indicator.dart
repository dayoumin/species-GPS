import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimensions.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.isFullScreen = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primaryBlue,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!isFullScreen) {
      return content;
    }

    return Container(
      color: AppColors.background.withOpacity(0.8),
      child: Center(child: content),
    );
  }
}