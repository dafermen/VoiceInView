# Documentación de VoiceInView

Actualizada el 10 de octubre de 2026. Los documentos de aprendizaje están en español; la interfaz de la app y parte de la documentación técnica conservan el inglés.

## Por dónde empezar

| Necesidad | Documento |
| --- | --- |
| Conocer la app, instalar el proyecto y consultar sus funciones | [README principal](../README.md) |
| Aprender desde cero cómo funciona el proyecto | [Guía para estudiantes y desarrolladores junior](junior-guide.md) |
| Encontrar la clase o función que realiza una tarea | [Recorrido del código](code-walkthrough.md) |
| Preparar el Mac y ejecutar validaciones | [Desarrollo](development.md) |
| Entender las decisiones de diseño | [Arquitectura](architecture.md) y [ADRs](decisions/ADR-006-xcode-15-compatibility.md) |
| Compilar, firmar y llevar una versión a TestFlight | [Guía de distribución](distribution-runbook.md) |
| Investigar errores que ya ocurrieron | [Historial de incidentes](build-incidents.md) |
| Saber qué se probó realmente | [Resultados de validación](validation-report.md) |
| Planificar pruebas pendientes | [Pruebas](testing.md), [audio y subtítulos](media-and-subtitles.md) y [fiabilidad](reliability.md) |
| Preparar una publicación pública | [Lista de publicación](release-checklist.md) y [App Store](app-store.md) |
| Entender el tratamiento de los datos | [Privacidad](privacy.md) |

## Estado al cerrar esta actualización

- Las versiones TestFlight 0.1.0 (5) y (6) tuvieron confirmación del usuario de funcionamiento básico en su iPhone.
- Las mejoras posteriores incluyen corrección de texto, audio opcional, reproducción y subtítulos SRT/WebVTT.
- La compilación Cloud 11 produjo el archivo con Xcode 26.6. Su exportación automática falló.
- Ese mismo archivo se exportó y subió desde el Mac con Xcode 15.2 el 10 de octubre. Apple confirmó la subida y el inicio del procesamiento.
- Falta confirmar el número final asignado en App Store Connect, el fin del procesamiento, la asignación al grupo Dev y las pruebas físicas de esas últimas mejoras.
- La exportación automática de Cloud continúa sin solución confirmada. Existe una alternativa comprobada para este archivo; no una garantía de compatibilidad futura.

## Cómo interpretar el historial

Los informes `phase-*-report.md`, [el informe de entrega inicial](implementation-report.md) y las secciones antiguas de validación describen lo conocido en sus fechas. No son el estado actual. Mantenerlos permite aprender qué se intentó y por qué se cambió de camino.

Al documentar un resultado, distinguir: implementado, compilado, probado en simulador, probado en dispositivo, subido, procesado y disponible para testers. Cada palabra requiere evidencia distinta.
