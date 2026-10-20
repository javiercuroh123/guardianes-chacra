import 'package:flutter/material.dart';

/// Estilo visual central: colores, tipografía y forma de los botones viven
/// solo aquí. Para cambiar el aspecto del juego se toca este archivo.
///
/// La paleta y las fuentes son las de la interfaz en Rive (artboard
/// `StyleGuide` y `docs/UI_RIVE.md`): así las pantallas que todavía son de
/// Flutter combinan con las nuevas.
abstract final class AppTheme {
  // Paleta muestreada de las referencias de la interfaz.
  /// Verde de los carteles: fondo del título hasta que llegue su escena.
  static const chacra = Color(0xFF3F7D24);
  static const _maiz = Color(0xFFFDB119); // primario: botones principales
  static const _maizClaro = Color(0xFFFEC81D); // secundario
  // Terciario: oscurecida desde #CA5233 para que el crema encima pase AA.
  static const _terracota = Color(0xFFB5452A);
  static const _crema = Color(0xFFFEF3D7); // fondo de paneles y pantallas
  static const _cremaBoton = Color(0xFFFBD7A5); // botones secundarios
  static const _texto = Color(0xFF4A1302); // texto y contornos
  static const _borde = Color(0xFFAF5212); // borde de paneles y tarjetas
  static const _madera = Color(0xFF9E430B); // carteles y barra superior

  /// Fuentes (en `assets/fonts/`, licencia OFL): Lilita One para títulos y
  /// Fredoka (variable, 300–700) para todo lo demás.
  static const titleFont = 'LilitaOne';
  static const bodyFont = 'Fredoka';

  static final ThemeData light = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _maiz,
      primary: _maiz,
      onPrimary: _texto,
      secondary: _maizClaro,
      onSecondary: _texto,
      tertiary: _terracota,
      onTertiary: _crema,
      surface: _crema,
      onSurface: _texto,
    );
    final base = ThemeData(colorScheme: scheme, fontFamily: bodyFont);
    final text = base.textTheme;
    const bold = FontWeight.w800;
    // Contorno oscuro como en los dibujos de las referencias.
    const outline = BorderSide(color: _texto, width: 2);
    const buttonShape = StadiumBorder(side: outline);
    // 48 dp de alto: el mínimo cómodo para tocar con el pulgar.
    const buttonSize = Size(200, 48);
    // El textStyle de un botón no hereda la fuente del tema: va explícita.
    const buttonText = TextStyle(
      fontFamily: bodyFont,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _crema,
      textTheme: text.copyWith(
        displayMedium: text.displayMedium?.copyWith(
          fontFamily: titleFont,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontFamily: titleFont,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _madera,
        foregroundColor: _crema,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: titleFont,
          fontSize: 24,
          color: _crema,
        ),
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
          backgroundColor: _cremaBoton,
          foregroundColor: _texto,
          side: outline,
        ),
      ),
      cardTheme: const CardThemeData(
        color: _crema,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _borde, width: 3),
        ),
      ),
      extensions: const [
        GameColors(
          hud: Color(0xF2FDEAC5),
          onHud: _texto,
          hudAccent: Color(0xFF0E6B12),
          overlayScrim: Color(0x994A1302),
          star: Color(0xFFC77700),
          starEmpty: Color(0xFFC9B79A),
          valleySky: Color(0xFF9ED8F5),
          valleyMountain: Color(0xFF8D6E63),
          valleyGrass: Color(0xFF7DBA45),
          valleyPath: Color(0xFFD7B47A),
          locked: Color(0xFF8E8A80),
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
    required this.hudAccent,
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

  /// Lo que se destaca dentro del HUD (el bono de maíz por llamar antes).
  final Color hudAccent;

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
    Color? hudAccent,
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
    hudAccent: hudAccent ?? this.hudAccent,
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
      hudAccent: mix(hudAccent, other.hudAccent),
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
