import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_badge.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_tab.dart';
import 'package:guardianes_chacra/app/rive/rive_toggle.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_wave_bar.dart';
import 'package:rive/rive.dart' as rive;

/// El kit de componentes de Rive para probarlo en el teléfono (se abre
/// desde el panel de desarrollo, nunca en release): arriba el artboard
/// `Catalog` con cada estado quieto y abajo cada envoltorio para tocarlo.
///
/// Sus textos no van en los ARB: son para quien desarrolla.
class UiCatalogScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<UiCatalogScreen> createState() => _UiCatalogScreenState();
}

class _UiCatalogScreenState extends ConsumerState<UiCatalogScreen> {
  rive.RiveWidgetController? _catalog;
  rive.ViewModelInstance? _catalogData;

  var _enabled = true;
  var _corn = 220;
  var _dangerCorn = false;
  var _wave = 3;
  var _boss = false;
  var _stars = 0;
  var _toggle = true;
  var _language = 0;
  var _tab = 0;
  var _tooltip = false;
  var _panel = true;
  Timer? _starTimer;

  @override
  void initState() {
    super.initState();
    if (ref.read(riveFileProvider) case final file?) {
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('Catalog'),
        stateMachineSelector: rive.StateMachineSelector.byName(
          RiveUi.stateMachine,
        ),
      );
      _catalog = controller;
      _catalogData = controller.dataBind(rive.DataBind.auto());
    }
  }

  @override
  void dispose() {
    _starTimer?.cancel();
    _catalogData?.dispose();
    _catalog?.dispose();
    super.dispose();
  }

  /// Llena las tres estrellas una por una, como la victoria.
  void _winStars() {
    _starTimer?.cancel();
    setState(() => _stars = 0);
    _starTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      setState(() => _stars++);
      if (_stars >= 3) timer.cancel();
    });
  }

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final title = Theme.of(context).textTheme.titleMedium;
    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: title),
    );
    Widget row(List<Widget> children) => Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de la interfaz')),
      backgroundColor: AppTheme.chacra,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          section('Todos los estados (artboard Catalog)'),
          if (catalog == null)
            const Text('El archivo de Rive no está cargado.')
          else
            AspectRatio(
              aspectRatio: 1000 / 640,
              child: rive.RiveWidget(controller: catalog),
            ),
          section('Botones'),
          row([
            RiveButton(
              label: 'Jugar',
              icon: RiveIcon.play,
              onPressed: _enabled ? () => _say('Jugar') : null,
            ),
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: _enabled ? 'Deshabilitar' : 'Habilitar',
              icon: RiveIcon.gear,
              onPressed: () => setState(() => _enabled = !_enabled),
            ),
            RiveButton(
              label: 'Mejorar',
              icon: RiveIcon.upgrade,
              onPressed: null,
              onDenied: () => _say('No alcanza el maíz'),
            ),
            RiveButton.round(
              label: 'Pausa',
              icon: RiveIcon.pause,
              onPressed: () => _say('Pausa'),
            ),
            RiveButton.round(
              label: 'Vender',
              icon: RiveIcon.sell,
              danger: true,
              onPressed: () => _say('Vender'),
            ),
          ]),
          section('Contador y oleadas'),
          row([
            RiveCounter(
              value: _corn,
              danger: _dangerCorn,
              semanticsLabel: 'Maíz: $_corn',
              fallback: Text('🌽 $_corn'),
            ),
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: '+25',
              onPressed: () => setState(() => _corn += 25),
            ),
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: '−40',
              onPressed: () => setState(() => _corn -= 40),
            ),
            RiveToggle(
              label: 'Peligro',
              value: _dangerCorn,
              onChanged: (on) => setState(() => _dangerCorn = on),
            ),
          ]),
          const SizedBox(height: 16),
          row([
            RiveWaveBar(
              wave: _wave,
              totalWaves: 10,
              boss: _boss,
              label: 'Oleada $_wave/10',
              fallback: Text('Oleada $_wave/10'),
            ),
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: 'Siguiente',
              icon: RiveIcon.nextWave,
              onPressed: () => setState(() {
                _wave = _wave >= 10 ? 1 : _wave + 1;
                _boss = _wave == 10;
              }),
            ),
          ]),
          section('Estrellas, interruptor y etiqueta'),
          row([
            for (var i = 0; i < 3; i++) RiveStar(filled: _stars > i),
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: 'Ganar estrellas',
              icon: RiveIcon.star,
              onPressed: _winStars,
            ),
            RiveToggle(
              label: 'Interruptor',
              value: _toggle,
              onChanged: (on) => setState(() => _toggle = on),
            ),
            const RiveToggle(
              label: 'Deshabilitado',
              value: true,
              onChanged: null,
            ),
            const RiveBadge(label: '¡Nuevo!'),
          ]),
          section('Selector y pestañas'),
          row([
            RiveSegmented(
              labels: const ['Sistema', 'Español', 'English'],
              selected: _language,
              onChanged: (index) => setState(() => _language = index),
            ),
            for (final (index, label) in const [
              (0, 'Plagas'),
              (1, 'Guardianes'),
            ])
              RiveTab(
                label: label,
                icon: index == 1 ? RiveIcon.shield : null,
                selected: _tab == index,
                onTap: () => setState(() => _tab = index),
              ),
          ]),
          section('Tooltip y panel'),
          row([
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: _tooltip ? 'Ocultar tooltip' : 'Mostrar tooltip',
              onPressed: () => setState(() => _tooltip = !_tooltip),
            ),
            RiveTooltip(
              text: 'Toca otra vez para confirmar',
              visible: _tooltip,
            ),
          ]),
          const SizedBox(height: 12),
          row([
            RiveButton(
              kind: RiveButtonKind.secondary,
              label: _panel ? 'Sacar panel' : 'Poner panel',
              onPressed: () => setState(() => _panel = !_panel),
            ),
            SizedBox(
              width: 360,
              height: 200,
              child: RivePanel(
                visible: _panel,
                child: const Center(child: Text('Contenido de Flutter')),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
