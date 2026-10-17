import 'package:flutter/material.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Menú principal: el título del juego y los caminos a Jugar, Bestiario y
/// Ajustes.
class TitleScreen extends StatelessWidget {
  const new({super.key});

  static const _taglineColor = Color(0xFFFFF3C4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      backgroundColor: AppTheme.chacra,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tagline,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(color: _taglineColor),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      key: const ValueKey('menu-play'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSecondary,
                      ),
                      onPressed: () => open(const LevelSelectScreen()),
                      child: Text(l10n.titlePlay),
                    ),
                    OutlinedButton(
                      key: const ValueKey('menu-bestiary'),
                      style: _outlinedOnGreen,
                      onPressed: () => open(const BestiaryScreen()),
                      child: Text(l10n.menuBestiary),
                    ),
                    OutlinedButton(
                      key: const ValueKey('menu-settings'),
                      style: _outlinedOnGreen,
                      onPressed: () => open(const SettingsScreen()),
                      child: Text(l10n.menuSettings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final ButtonStyle _outlinedOnGreen = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 2),
  );
}
