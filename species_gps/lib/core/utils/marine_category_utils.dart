import 'package:flutter/material.dart';
import '../../models/marine_category.dart';
import '../theme/app_colors.dart';

/// 해양 생물 분류군 관련 유틸리티 클래스
class MarineCategoryUtils {
  // Private constructor to prevent instantiation
  MarineCategoryUtils._();

  /// 분류군별 색상 반환
  static Color getCategoryColor(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return AppColors.primaryBlue;
      case MarineCategory.mollusk:
        return const Color(0xFFFF9800); // Orange
      case MarineCategory.cephalopod:
        return const Color(0xFF9C27B0); // Purple
      case MarineCategory.crustacean:
        return AppColors.secondaryGreen;
      case MarineCategory.echinoderm:
        return const Color(0xFF00BCD4); // Cyan
      case MarineCategory.seaweed:
        return const Color(0xFF4CAF50); // Green
      case MarineCategory.other:
        return AppColors.textSecondary;
    }
  }

  /// 분류군별 아이콘 반환
  static IconData getCategoryIcon(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return Icons.sailing;
      case MarineCategory.mollusk:
        return Icons.circle;
      case MarineCategory.cephalopod:
        return Icons.scatter_plot;
      case MarineCategory.crustacean:
        return Icons.pest_control;
      case MarineCategory.echinoderm:
        return Icons.star;
      case MarineCategory.seaweed:
        return Icons.grass;
      case MarineCategory.other:
        return Icons.more_horiz;
    }
  }

  /// 분류군별 설명 반환
  static String getCategoryDescription(MarineCategory category) {
    switch (category) {
      case MarineCategory.fish:
        return '고등어, 갈치, 참돔 등';
      case MarineCategory.mollusk:
        return '전복, 소라, 조개 등';
      case MarineCategory.cephalopod:
        return '오징어, 문어, 낙지 등';
      case MarineCategory.crustacean:
        return '새우, 게, 랍스터 등';
      case MarineCategory.echinoderm:
        return '성게, 불가사리, 해삼 등';
      case MarineCategory.seaweed:
        return '김, 미역, 다시마 등';
      case MarineCategory.other:
        return '기타 해양생물';
    }
  }
}