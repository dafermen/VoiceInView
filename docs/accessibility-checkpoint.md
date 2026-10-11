# Punto de reanudación — build 20

2026-10-11. Base: `0b820fc`. Cambios autorizados implementados: orientación inclusiva, iPad universal, idioma inglés/español, Practicar idioma, pausa visible, papel claro y renglones. Sin cambio de esquema V7 ni de identidad.

## Estado técnico

- Preferencias persistentes; inglés inicial; idioma inmutable por sesión; reconocimiento, traducción y práctica en ambos sentidos; payloads antiguos interpretados como inglés.
- Pausa con aviso persistente, Reanudar y anuncio accesible; no reinicio automático del micrófono.
- Colores claros con texto oscuro; guías CoreGraphics decorativas; alto contraste tiene prioridad.
- Paquete Release 0.1.0 (20) compilado, familia `[1,2]`, icono iPad y cuatro orientaciones. La fuente local usa Xcode 15.2; Cloud debe validar las ramas modernas.

## Evidencia y límites

88 unitarias aprobadas en `VoiceInView-20-Unit.xcresult`, antes del ajuste final de dibujo y snapshot de diccionario. El log final `VoiceInView-20-confirmed.log` registra dos recorridos UI aprobados: lectura con renglones/pausa/giro/Reanudar y práctica española. Su tercer recorrido falló al abrir Sessions; después el runner unitario quedó esperando. Al cancelar Xcode no finalizó el bundle. No declarar toda esa suite aprobada.

La traducción guardada con edición/audio/exportación pasó en la ejecución anterior `VoiceInView-20-UI.xcresult`. La repetición aislada final (`VoiceInView-20-regression-final.log`) abrió Sessions, corrigió/guardó traducción y reprodujo audio, pero quedó esperando la jerarquía de la hoja nativa de compartir durante varios minutos. Se canceló; no cuenta como aprobación final integral. Revisar compartir en el dispositivo.

iPad: configuración y Release universales comprobados; capturas anteriores de vertical y fullscreen horizontal revisadas con fondo amarillo y pausa. La última ejecución `VoiceInView-20-ipad-final.log` no consiguió iniciar XCTest y fue cancelada. Queda pendiente el recorrido final de renglones en iPad y la aceptación física. No reinstalar ni borrar datos del iPhone para resolver problemas del simulador.

Más detalle: [informe de validación](validation-report.md), [incidentes](build-incidents.md), [guía inclusiva](inclusive-use.md).

## Próxima aceptación

1. Comprobar el check de Archive del commit publicado; éxito local no acredita TestFlight.
2. En iPhone/iPad: preparar ambos modelos, transcribir voz real, traducir en ambos sentidos y conservar idioma al reanudar.
3. Probar alarma real, segundo plano, VoiceOver, tamaños accesibles, ventana dividida y compartir en iPad.
4. No repetir la compilación o cambiar firma por un error de exportación sin consultar los logs detallados y el historial de incidentes.
