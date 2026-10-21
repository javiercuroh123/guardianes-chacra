import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_icon_view.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_llama.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_toggle.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:rive/rive.dart' as rive;

/// Música, efectos, vibración, números de daño e idioma, en un panel de dos
/// columnas sobre el valle, con la llama al lado. Donde la ley lo exige
/// (por ejemplo, en Europa), también las opciones de privacidad de los
/// anuncios; en debug, "Desarrollo: todo desbloqueado".
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final withRive = ref.watch(riveFileProvider) != null;

    final sound = _Section(
      title: l10n.settingsSoundSection,
      children: [
        _ToggleRow(
          toggleKey: const ValueKey('settings-music'),
          icon: RiveIcon.music,
          label: l10n.settingsMusic,
          value: settings.music,
          onChanged: (on) => controller.music = on,
        ),
        _ToggleRow(
          toggleKey: const ValueKey('settings-effects'),
          icon: RiveIcon.sound,
          label: l10n.settingsEffects,
          value: settings.effects,
          onChanged: (on) => controller.effects = on,
        ),
        _ToggleRow(
          toggleKey: const ValueKey('settings-vibration'),
          icon: RiveIcon.vibration,
          label: l10n.settingsVibration,
          value: settings.vibration,
          onChanged: (on) => controller.vibration = on,
        ),
      ],
    );
    const languages = AppLanguage.values;
    final display = _Section(
      title: l10n.settingsDisplaySection,
      children: [
        _ToggleRow(
          toggleKey: const ValueKey('settings-damage-numbers'),
          icon: RiveIcon.damage,
          label: l10n.settingsDamageNumbers,
          value: settings.damageNumbers,
          onChanged: (on) => controller.damageNumbers = on,
        ),
        _Row(icon: RiveIcon.language, label: l10n.settingsLanguage),
        RiveSegmented(
          key: const ValueKey('settings-language'),
          labels: [
            for (final language in languages)
              switch (language) {
                AppLanguage.system => l10n.languageSystem,
                AppLanguage.es => l10n.languageEs,
                AppLanguage.en => l10n.languageEn,
              },
          ],
          selected: languages.indexOf(settings.language),
          onChanged: (index) => controller.language = languages[index],
        ),
        if (devToolsEnabled)
          _ToggleRow(
            toggleKey: const ValueKey('settings-dev-unlock'),
            icon: RiveIcon.lock,
            label: 'Desarrollo: todo desbloqueado',
            value: ref.watch(devOptionsProvider).unlockAll,
            onChanged: (on) =>
                ref.read(devOptionsProvider.notifier).unlockAll = on,
          ),
      ],
    );

    return Scaffold(
      backgroundColor: RiveValley.sky,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final frame = ValleyFrame.of(size);
          final llama = math.min(size.height * 0.5, size.width * 0.16);
          return Stack(
            fit: StackFit.expand,
            children: [
              RiveValley(
                fit: frame.cover ? rive.Fit.cover : rive.Fit.fitWidth,
                alignment: frame.cover
                    ? Alignment.center
                    : Alignment.bottomCenter,
              ),
              if (withRive)
                Positioned(
                  left: size.width * 0.02,
                  bottom: size.height * 0.04,
                  child: RiveLlama(mood: LlamaMood.happy, height: llama),
                ),
              SafeArea(
                minimum: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _Header(title: l10n.menuSettings),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: withRive ? llama * RiveLlama.aspect : 0,
                        ),
                        child: Center(
                          child: RivePanel(
                            padding: const EdgeInsets.fromLTRB(26, 18, 26, 14),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: sound),
                                        const SizedBox(width: 28),
                                        Expanded(child: display),
                                      ],
                                    ),
                                    _PrivacyOptions(
                                      ads: ref.watch(adsServiceProvider),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Volver (redondo) y el cartel del título.
class _Header extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: RiveButton.round(
            key: const ValueKey('settings-back'),
            label: AppLocalizations.of(context).back,
            icon: RiveIcon.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: FittedBox(child: RiveTitleSign(title: title, width: 200)),
        ),
      ],
    ),
  );
}

/// Una columna: la cinta con su título y las filas.
class _Section extends StatelessWidget {
  const new({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    // Cada columna en su propio nodo: TalkBack lee una entera y después la
    // otra, en vez de ir de fila en fila saltando entre las dos.
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.star.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.onHud, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: Semantics(
                container: true,
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onHud,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          for (final child in children) ...[const SizedBox(height: 8), child],
        ],
      ),
    );
  }
}

/// El azulejo del ícono y el nombre del ajuste.
class _Row extends StatelessWidget {
  const new({required this.icon, required this.label, this.trailing});

  final RiveIcon icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final trailing = this.trailing;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.hud,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.onHud.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: RiveIconView(icon, size: 30),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          // Si hay interruptor, ya lleva el nombre: TalkBack no lo lee dos
          // veces. Si no, el nombre va solo (no pegado al título).
          child: Semantics(
            container: trailing == null,
            excludeSemantics: trailing != null,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: colors.onHud, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Una fila con interruptor: tocarlo cambia el ajuste.
class _ToggleRow extends StatelessWidget {
  const new({
    required this.toggleKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key toggleKey;
  final RiveIcon icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _Row(
    icon: icon,
    label: label,
    trailing: RiveToggle(
      key: toggleKey,
      value: value,
      label: label,
      onChanged: onChanged,
    ),
  );
}

/// "Opciones de privacidad": solo aparece si el formulario de
/// consentimiento de Google lo pide para este jugador.
class _PrivacyOptions extends StatelessWidget {
  const new({required this.ads});

  final AdsService ads;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    return ValueListenableBuilder<AdsStatus>(
      valueListenable: ads.status,
      builder: (context, status, _) => !status.privacyOptionsRequired
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Tooltip(
                message: l10n.settingsPrivacySubtitle,
                child: TextButton.icon(
                  key: const ValueKey('settings-privacy'),
                  onPressed: ads.showPrivacyOptions,
                  icon: const RiveIconView(RiveIcon.shield, size: 24),
                  label: Text(
                    l10n.settingsPrivacy,
                    style: TextStyle(
                      color: colors.onHud,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
