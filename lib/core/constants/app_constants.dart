abstract final class AppConstants {
  // Autosave debounce — evita writes excesivos a Drift mientras el usuario escribe
  static const autosaveDebounceDuration = Duration(seconds: 3);

  // Sesión de escritura: si la app está en background más de este tiempo,
  // la sesión actual se cierra automáticamente
  static const sessionPauseDuration = Duration(minutes: 5);

  // Documentos en papelera se purgan permanentemente después de este período
  static const trashRetentionDays = 30;

  // Umbral de palabras para considerar un documento "grande" (requiere lazy rendering)
  static const largeDocumentWordThreshold = 4000;

  // Nombre de la Hive box para preferencias del usuario
  static const settingsBoxName = 'pluma_settings';

  // Objetivo diario por defecto (palabras)
  static const defaultDailyWordTarget = 500;

  // Velocidad media de lectura en palabras por minuto (para estimated read time)
  static const wordsPerMinuteReading = 200;
}
