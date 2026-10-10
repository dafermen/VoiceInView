# Punto de reanudación — mejoras de traducción (build 17)

Solicitud autorizada: seis mejoras propuestas, documentación y repositorio. El usuario avisa que queda aproximadamente 5% de su cupo; conservar estado verificable, no publicar código sin validar.

Base estable: e1b56c1 (build 16). Identidad com.dafermen.vReader y esquema V6 se conservan.

## Lista de trabajo
- [x] Escuchar audio original desde un párrafo traducido.
- [x] Diccionario personal para reconocimiento y términos españoles.
- [x] Traducción incremental que conserve ediciones de párrafos sin cambios.
- [x] Búsqueda bilingüe entre sesiones y acceso al resultado.
- [x] Vista previa de idioma/formato/vigencia antes de compartir.
- [x] Traducción opcional durante captura sobre texto final, sin bloquear micrófono.
- [x] Pruebas locales y documentación de usuario/junior.
- [ ] Commit/push y comprobación moderna en Cloud.

## Reanudar
Consultar git status y git diff antes de editar. No asumir que una compilación local con Xcode 15.2 valida Translation (requiere SDK moderno y iOS 18). Revisar check-runs del commit en GitHub para Cloud; éxito Cloud no confirma instalación TestFlight. Conservar traducciones completas anteriores ante fallos/cancelaciones. No cambiar certificados ni identidad.

## Estado de validación
- **71 pruebas unitarias aprobadas**, incluidas 10 de traducción.
- **Tres recorridos UI aprobados** entre las últimas ejecuciones: búsqueda española, bloqueo de traducción obsoleta y lectura/edición/audio/pausa/vista previa/exportación SRT.
- Corrección confirmada: sheet(item:) entrega el párrafo correcto al reproductor. El recorrido final pasó en 51,509 segundos, sin fallos.
- Evidencia UI final: `/private/tmp/VoiceInView-17-ui-verified.log` y `/private/tmp/VoiceInView-17-UI-Verified.xcresult`.
- Debug y Release finales compilados; `/private/tmp/VoiceInView-17-release-final.log`. Identidad/build 17 verificados; 118 enlaces locales, plist y diff revisados.
- Los conjuntos anteriores `VoiceInView-17-Tests.xcresult` y `VoiceInView-17-UI-Final.xcresult` incluyen los fallos ya corregidos. No presentarlos como ejecuciones completas exitosas.
- Próximo: push/check-runs del commit. Xcode 15.2 no verifica las APIs modernas de Translation/SpeechAnalyzer.
- Pendiente iPhone/TestFlight: descargar modelos, calidad, latencia, batería, interrupciones. La vista en directo es temporal y experimental; para exportar español se traduce la sesión guardada.
