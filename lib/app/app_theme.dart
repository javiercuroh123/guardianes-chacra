import 'package:flutter/material.dart';

/// Estilo visual central: colores, tipografía y forma de los botones viven
/// solo aquí. Para cambiar el aspecto del juego se toca este archivo.
abstract final class AppTheme {
  // Paleta andina: verde de chacra, amarillo maíz, terracota y crema.
  static const chacra = Color(0xFF2E7D32); // primario
  static const _maiz = Color(0xFFF9A825); // secundario
  static const _terracota = Color(0xFFA84A20); // terciario
  static const _crema = Color(0xFFFFF8E1); // fondo de tarjetas y pantallas
  static const _tierraOscura = Color(0xFF3E2723); // texto sobre crema y maíz

  static final ThemeData light = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: chacra,
      primary: chacra,
      onPrimary: Colors.white,
      secondary: _maiz,
      onSecondary: _tierraOscura,
      tertiary: _terracota,
      onTertiary: Colors.white,
      surface: _crema,
      onSurface: _tierraOscura,
    );
    final base = ThemeData(colorScheme: scheme);
    final text = base.textTheme;
    const bold = FontWeight.w800;
    const buttonShape = StadiumBorder();
    // 48 dp de alto: el mínimo cómodo para tocar con el pulgar.
    const buttonSize = Size(200, 48);
    const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);

    return base.copyWith(
      scaffoldBackgroundColor: _crema,
      textTheme: text.copyWith(
        displayMedium: text.displayMedium?.copyWith(fontWeight: bold),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: bold),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: chacra,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: const BorderSide(color: chacra, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        color: _crema,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      extensions: const [
        GameColors(
          hud: Color(0xE61B1B1B),
          onHud: Colors.white,
          overlayScrim: Color(0x99000000),
          star: Color(0xFFC77700),
          starEmpty: Color(0xFFBCAAA4),
          valleySky: Color(0xFF9ED8F5),
          valleyMountain: Color(0xFF8D6E63),
          valleyGrass: Color(0xFF8BC34A),
          valleyPath: Color(0xFFD7B47A),
          locked: Color(0xFF757575),
        ),
      ],
    );
  }
}

/// Colores propios del juego que Material no tiene. Se leen con
/// `GameColors.of(context)`.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const new({
    required this.hud,
    required this.onHud,
    required this.overlayScrim,
    required this.star,
    required this.starEmpty,
    required this.valleySky,
    required this.valleyMountain,
    required this.valleyGrass,
    required this.valleyPath,
    required this.locked,
  });

  /// Fondo de los chips y botones del HUD (sobre el mapa).
  final Color hud;
  final Color onHud;

  /// Velo que oscurece la partida detrás de pausa, victoria y derrota.
  final Color overlayScrim;

  final Color star;
  final Color starEmpty;
  final Color valleySky;
  final Color valleyMountain;
  final Color valleyGrass;
  final Color valleyPath;
  final Color locked;

  static GameColors of(BuildContext context) =>
      Theme.of(context).extension<GameColors>()!;

  @override
  GameColors copyWith({
    Color? hud,
    Color? onHud,
    Color? overlayScrim,
    Color? star,
    Color? starEmpty,
    Color? valleySky,
    Color? valleyMountain,
    Color? valleyGrass,
    Color? valleyPath,
    Color? locked,
  }) => GameColors(
    hud: hud ?? this.hud,
    onHud: onHud ?? this.onHud,
    overlayScrim: overlayScrim ?? this.overlayScrim,
    star: star ?? this.star,
    starEmpty: starEmpty ?? this.starEmpty,
    valleySky: valleySky ?? this.valleySky,
    valleyMountain: valleyMountain ?? this.valleyMountain,
    valleyGrass: valleyGrass ?? this.valleyGrass,
    valleyPath: valleyPath ?? this.valleyPath,
    locked: locked ?? this.locked,
  );

  @override
  GameColors lerp(GameColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      hud: mix(hud, other.hud),
      onHud: mix(onHud, other.onHud),
      overlayScrim: mix(overlayScrim, other.overlayScrim),
      star: mix(star, other.star),
      starEmpty: mix(starEmpty, other.starEmpty),
      valleySky: mix(valleySky, other.valleySky),
      valleyMountain: mix(valleyMountain, other.valleyMountain),
      valleyGrass: mix(valleyGrass, other.valleyGrass),
      valleyPath: mix(valleyPath, other.valleyPath),
      locked: mix(locked, other.locked),
    );
  }
}
