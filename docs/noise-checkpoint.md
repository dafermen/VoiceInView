# Entrega de reducción de ruido — fuente 22

2026-10-12. Implementación terminada; validación local completada, publicación/Cloud pendientes. Leer este archivo antes de continuar si la sesión se interrumpe.

- Preferencia global opt-in, acceso rápido, instantánea por sesión y textos English/Español.
- Procesamiento nativo Apple antes del tap, AGC desactivado y ducking mínimo. No limpia archivos anteriores, no silencia automáticamente ni captura audio interno.
- Identidad com.dafermen.vReader, versión 0.1.0 y esquema V7 conservados; build fuente 22.
- Pruebas añadidas de persistencia, pausa/reanudación, fallo explícito y navegación del filtro.
- **95 unitarias y un recorrido UI iPhone aprobados**, TEST SUCCEEDED: `/private/tmp/VoiceInView22-verified.log` y `.xcresult`. UI de filtro en inglés/español y pausa/reanudación: 33,287 s. Capturas revisadas. El primer intento unitario no ejecutó pruebas por timeout del daemon; ver incidentes.
- **Release aprobado**, `/private/tmp/VoiceInView22-release.log`, BUILD SUCCEEDED. Paquete 0.1.0 (22), familia [1,2], identidad conservada; sin firma local.
- Catálogos: 485 claves por idioma, dos razones de permiso, paridad/placeholders correctos. La extracción de claves desde el compilador no se ejecutó: el build no emitió .stringsdata.
- **UI iPad aprobada**, 51,624 s, TEST EXECUTE SUCCEEDED: `/private/tmp/VoiceInView22-ipad.log` y `.xcresult`. Capturas revisadas. DerivedData `/private/tmp/VoiceInView22`.
- Pendientes: GitHub/Cloud y comparación acústica física. No afirmar entrega TestFlight ni calidad de reducción a partir de dobles de prueba.

Entorno local: Xcode 15.2 / simuladores iOS 17.2. Las ramas modernas de reconocimiento requieren la compilación Cloud. Las advertencias locales de onLevel y onDismiss son preexistentes.
