# ADR-007: Offline-first absoluto y privacidad

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

La filosofía de "Sin Anuncios Nunca" requiere que Pluma funcione completamente offline y
no envíe datos a ningún servidor externo. Esta es la invariante más importante del proyecto.

## Problema

¿Cómo garantizar que ninguna dependencia, configuración o feature futura viole el principio
de privacidad offline-first?

## Decisión

### Prohibiciones absolutas (no negociables)

Las siguientes dependencias están explícitamente prohibidas:

```yaml
# NUNCA agregar:
firebase_core, firebase_analytics, firebase_crashlytics  # Telemetría Google
amplitude_flutter, mixpanel_flutter                      # Analytics
sentry_flutter, datadog_flutter_plugin                   # Error tracking externo
google_mobile_ads, facebook_audience_network             # Publicidad
in_app_purchase, purchases_flutter                       # Suscripciones
```

Cualquier PR que añada uno de estos paquetes debe ser rechazado sin excepción.

### google_fonts en bundle

`google_fonts` tiene un modo de descarga dinámica (CDN). Para Pluma:

```dart
// En main.dart — siempre presente
GoogleFonts.config.allowRuntimeFetching = false;
```

Y los archivos `.ttf` de Merriweather e Inter deben estar en `assets/fonts/`. Si los fonts
no están bundled, la app usa el fallback del sistema — nunca descarga de la red.

### Flutter analytics por defecto

Flutter en modo release NO envía datos de performance a Google por defecto. Sin embargo,
si en el futuro se añade Firebase Performance Monitoring, eso violaría este ADR.

### Sin permiso de Internet en el manifest (deseable a largo plazo)

En Android, es posible no declarar `INTERNET` permission. Esto garantiza a nivel del OS
que la app nunca hace llamadas de red. Sin embargo, algunos paquetes como `file_picker`
(para Google Drive) podrían requerirlo. Evaluar en Fase 7 si es posible omitirlo.

### Sin cuenta, sin login, sin registro

No se implementarán:
- Pantalla de login o registro
- Autenticación social (Google, Apple, Facebook)
- Cloud sync (iCloud, Google Drive automático)
- Cualquier feature que requiera identificar al usuario en un servidor

### Privacidad en los stores

La Privacy Policy para App Store / Play Store declarará:
- No se recopila ningún dato
- No se envía ningún dato a ningún servidor
- Los datos del usuario permanecen exclusivamente en el dispositivo

Esta es la propuesta de valor más fuerte de Pluma.

## Consecuencias

**Positivas:**
- El usuario puede usar Pluma con total confianza de que sus escritos son suyos
- No se requiere consentimiento de cookies ni GDPR
- La privacy policy es trivial: "no recopilamos nada"
- Sin backend = sin costos de infraestructura = sostenible indefinidamente

**Negativas / trade-offs:**
- Sin sincronización entre dispositivos — el usuario que cambia de teléfono debe
  hacer un backup manual y restaurarlo. Mitigación: exportación de backup en Fase 7.
- Sin colaboración en tiempo real — por diseño.
- Si en el futuro se quisiera añadir sync (e.g., iCloud via documentos del sistema),
  requeriría un nuevo ADR que evalúe si viola el espíritu de este.
