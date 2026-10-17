/// Pasos (ticks) de simulación por cada segundo de juego.
///
/// 30 basta para un tower defense (una plaga rápida avanza ~0,1 casillas
/// por tick y los ataques se miden en tramos de 33 ms), cuesta la mitad que
/// 60 y, a x2, son 60 pasos por segundo. La fluidez en pantalla la da la
/// interpolación entre ticks de la capa visual.
const ticksPerSecond = 30;

/// Convierte segundos de los datos en ticks enteros (redondeando). El
/// tiempo se cuenta en ticks para no acumular errores de decimales.
int secondsToTicks(double seconds) => (seconds * ticksPerSecond).round();

/// Segundos enteros que faltan en [ticks], redondeando hacia arriba: con un
/// solo tick por delante todavía se muestra "1 s", nunca "0 s".
int ticksToWholeSeconds(int ticks) =>
    (ticks + ticksPerSecond - 1) ~/ ticksPerSecond;
