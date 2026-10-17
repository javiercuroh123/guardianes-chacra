import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Primera pantalla: el título del juego en el idioma del dispositivo y,
/// por ahora, un botón que abre el primer nivel.
class TitleScreen extends ConsumerWidget {
  const new({super.key});

  // TODO(fase-6): colores del ThemeData central y fondo del valle.
  static const _background = Color(0xFF2E7D32);
  static const Color _titleColor = Colors.white;
  static const _taglineColor = Color(0xFFFFF3C4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // TODO(fase-6): la selección de nivel reemplaza este botón.
    final content = ref.watch(gameContentProvider);

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
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('title-play'),
                  onPressed: switch (content) {
                    AsyncData(:final value) => () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BattleScreen(levelId: value.levels.first.id),
                      ),
                    ),
                    _ => null,
                  },
                  child: Text(l10n.titlePlay),
                ),
                if (content case AsyncError(:final error))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.contentLoadError('$error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _taglineColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
