# ADR-005: Modelo de estadísticas y cálculo de streak

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

Pluma registra la actividad de escritura para motivar al usuario: palabras por día, streaks,
heatmap al estilo GitHub, objetivos. Todo debe calcularse de forma determinista desde
datos locales. No hay backend que centralice el cálculo.

## Problema

¿Cómo modelar las estadísticas de escritura para garantizar correctitud, performance y
testabilidad sin un servidor?

## Decisión

### Arquitectura de datos

**`DailyStats` como snapshot upserted.** Cada vez que termina una sesión de escritura
(el usuario sale del editor o la app va a background >5min), se hace un UPSERT en
`daily_stats` acumulando:

```sql
words_written = words_written + delta   -- NO sobreescribe
minutes_written = minutes_written + delta_minutes
sessions_count = sessions_count + 1
```

**Por qué delta, no total:** Si el usuario escribe 200 palabras y luego borra 50, el
`wordCount` del documento es 150. Pero en esa sesión *escribió* 200 palabras. El delta
captura el esfuerzo real de escritura, no solo el resultado neto. Esto es consistente
con cómo Werdsmith y similares cuentan las palabras.

**`WritingSession`** registra cada sesión individual para los récords (mejor sesión) y
la velocidad de escritura.

### Cálculo de streak

**Política de streak:**
- El streak se incrementa si el día anterior a hoy tiene `words_written > 0`
- Si el usuario no escribió ayer, el streak se rompe
- Hoy no cuenta hasta que se escriba la primera palabra de la sesión actual
- El streak se calcula iterando `DailyStats ORDER BY date DESC` — O(days_active), trivial

**Por qué esta política:** Alternativas como "gracia de 24 horas" son más complejas de
implementar y más difíciles de comunicar al usuario. La política simple y estricta es
predecible y honesta.

**Streak y zonas horarias:** Se usa `DateTime.now()` local del dispositivo — no UTC.
El streak se resetea a la medianoche local del usuario, que es el comportamiento esperado.

### Heatmap

- 365 filas en `DailyStats` = query trivial en <5ms
- Renderizado con `CustomPainter` sin librerías externas
- 4 niveles de intensidad: 0 palabras = gris, 1-99 = verde claro, 100-499 = verde medio, 500+ = verde oscuro

### Testabilidad

El cálculo de streak y el upsert de daily stats se testean con `fake_async` para simular
el paso de días sin `sleep`. Los tests de repositorio usan `NativeDatabase.memory()`.

## Consecuencias

**Positivas:**
- Determinístico: dado el mismo conjunto de `DailyStats`, siempre se obtiene el mismo streak
- Sin servidor: el cálculo es 100% local y offline
- Tests rápidos: `fake_async` elimina timing flakiness

**Negativas / trade-offs:**
- El delta de palabras puede ser positivo incluso en una sesión donde el documento quedó
  con menos palabras que al inicio (si el usuario escribió y luego borró). Esto es una
  decisión de producto consciente: registramos el esfuerzo, no solo el resultado.
- Si el usuario cambia la zona horaria del dispositivo mid-session, el streak podría
  comportarse de forma inesperada. Este edge case es aceptable para v1.
