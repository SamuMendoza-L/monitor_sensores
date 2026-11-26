import 'package:flutter/material.dart';

/// Paleta de colores extraída de /refDiseño/paletadecolores.png
class AppColors {
  AppColors._();

  // ── Paleta principal ──
  static const Color primaryDark   = Color(0xFF22577A);
  static const Color primary       = Color(0xFF38A3A5);
  static const Color accent        = Color(0xFF57CC99);
  static const Color light         = Color(0xFF80ED99);
  static const Color surfaceLight  = Color(0xFFC7F9CC);

  // ── Derivados de uso ──
  static const Color scaffoldBg    = Color(0xFFF4F6F8);
  static const Color cardBg        = Colors.white;
  static const Color textPrimary   = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6F767E);
  static const Color divider       = Color(0xFFE6E8EC);

  // ── Estados ──
  static const Color danger        = Color(0xFFE53935);
  static const Color dangerLight   = Color(0xFFFFEBEE);
  static const Color warning       = Color(0xFFFFA726);
  static const Color warningLight  = Color(0xFFFFF8E1);
}
