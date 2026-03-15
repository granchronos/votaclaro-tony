import 'package:flutter/material.dart';

/// Paleta de colores VotaClaro — inspirada en la bandera peruana + legibilidad WCAG AA
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFD62B2B); // Rojo peruano
  static const Color primaryDark = Color(0xFFAA1E1E);
  static const Color primaryLight = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFFFFFFFF); // Blanco peruano

  // Accent
  static const Color accent = Color(0xFF2B7DD6); // Azul confianza
  static const Color accentLight = Color(0xFFE8F2FF);

  // Semáforo de viabilidad
  static const Color viable = Color(0xFF27AE60); // 🟢 Alta
  static const Color viableLight = Color(0xFFE8F8EF);
  static const Color doubtful = Color(0xFFF39C12); // 🟡 Media
  static const Color doubtfulLight = Color(0xFFFFF8E8);
  static const Color inviable = Color(0xFFE74C3C); // 🔴 Baja
  static const Color inviableLight = Color(0xFFFEECEB);

  // Reciclada
  static const Color recycled = Color(0xFF8E44AD); // 🔄 Propuesta reciclada
  static const Color recycledLight = Color(0xFFF4ECFD);

  // Backgrounds
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F5);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Dark mode
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkSurfaceVariant = Color(0xFF252836);
  static const Color darkBorder = Color(0xFF2D3148);

  // Partido badges (top partidos Perú 2026)
  static const Map<String, Color> partidoColors = {
    'Fuerza Popular': Color(0xFFFF6B00),
    'Perú Libre': Color(0xFFE74C3C),
    'Alianza para el Progreso': Color(0xFF3498DB),
    'Renovación Popular': Color(0xFF2ECC71),
    'Acción Popular': Color(0xFFE67E22),
    'Somos Perú': Color(0xFF9B59B6),
    'Podemos Perú': Color(0xFF1ABC9C),
    'Ahora Nación': Color(0xFFE91E63),
    'País para Todos': Color(0xFF00BCD4),
    'Perú Primero': Color(0xFF795548),
    'Cooperación Popular': Color(0xFFFF9800),
    'Partido Cívico OBRAS': Color(0xFF607D8B),
    'Fe en el Perú': Color(0xFF4CAF50),
    'Juntos por el Perú': Color(0xFFF44336),
    'Avanza País': Color(0xFF673AB7),
    'Partido Morado': Color(0xFF7C4DFF),
    'Partido Aprista Peruano': Color(0xFFD32F2F),
    'default': Color(0xFF6B7280),
  };
}
