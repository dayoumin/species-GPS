import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - 바다를 연상시키는 블루 계열
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color primaryLight = Color(0xFF4A90E2);
  static const Color primaryDark = Color(0xFF003D7A);
  
  // Secondary Colors - 자연을 연상시키는 그린 계열
  static const Color secondaryGreen = Color(0xFF00A651);
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF2E7D32);
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentYellow = Color(0xFFFFC107);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  static const Color divider = Color(0xFFECF0F1);
  
  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);
  
  // GPS Status Colors
  static const Color gpsActive = Color(0xFF27AE60);
  static const Color gpsInactive = Color(0xFFE74C3C);
  static const Color gpsSearching = Color(0xFFF39C12);
  
  // Gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [primaryBlue, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [secondaryGreen, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}