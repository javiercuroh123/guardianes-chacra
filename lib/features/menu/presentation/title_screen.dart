import 'package:flutter/material.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Primera pantalla: el título del juego en el idioma del dispositivo.
class TitleScreen extends StatelessWidget {
  const new({super.key});

  // TODO(fase-6): colores del ThemeData central y fondo del valle.
  static const _background = Color(0xFF2E7D32);
  static const Color _titleColor = Colors.white;
  static const _taglineColor = Color(0xFFFFF3C4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(
                    color: _titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(color: _taglineColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
