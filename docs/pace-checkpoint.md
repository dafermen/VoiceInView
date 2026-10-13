# Punto de reanudación — build fuente 23

Actualizado 2026-10-13. Trabajo autorizado: reproducción A mi ritmo, corrección directa, favoritas protegidas, idioma de pestañas y preparación documental para App Store. Publicación pública no solicitada.

Implementación: [guía funcional/técnica](at-my-pace.md). Esquema V8, identidad `com.dafermen.vReader` conservada. Proyecto real `/Users/dariomeneses/Projects/VoiceInView`; la ruta antigua vReader no es la carpeta del proyecto.

Estado: implementación y verificación local completas; subidas a `main` en `40af9bd1310881a9d6c3cd37de9b38c2cf235ced`. Xcode Cloud completó Archive - iOS correctamente el 2026-10-13 a las 04:22:27 UTC: 0 errores, 0 fallos de tests, 0 incidencias de análisis y 4 advertencias (este archivo no ejecuta la suite local). Release final pasó (`/private/tmp/VoiceInView23-release-final.log`). La suite de 99 pruebas unitarias pasó (`/private/tmp/VoiceInView23-final.xcresult`); ese bundle también registra un fallo de navegación de test de exportación y otro de selección de párrafo traducido, por eso el resultado global del bundle es fallido. No presentarlo como una ejecución íntegramente verde.

Repeticiones: A mi ritmo/favoritas e idioma pasaron en iPhone; exportación de SRT y eliminación independiente de audio pasó en `/private/tmp/VoiceInView23-review.xcresult`. Traducción corregida/cancelada y exportada pasó en `/private/tmp/VoiceInView23-translation.xcresult` (92.960 s). El recorrido iPad pasó en `/private/tmp/VoiceInView23-ipad-final.xcresult` (45.475 s); la ejecución `/private/tmp/VoiceInView23-ipad-rotation.xcresult` pasó también (46.861 s), esperando ancho mayor que alto y controles interactuables antes de capturar. El cambio de idioma iPad pasó en `/private/tmp/VoiceInView23-ipad.xcresult` (21.944 s), aunque ese bundle global incluye el primer fallo de automatización del popover. Las correcciones de automatización conservan las aserciones de datos, guardado y cancelación.

Catálogos: 507 claves Localizable y 2 de permisos, mismas claves/placeholders EN/ES. No se obtuvieron `.stringsdata`; no atribuir cobertura de extracción del compilador al chequeo de catálogos. Metadata EN/ES dentro de los límites, enlaces relativos de documentación válidos. `validate-store-metadata.py --ready` rechaza correctamente los campos de publicación todavía pendientes.

Pendientes del titular: correo público de soporte/privacidad, identidad editorial, alojamiento/URLs públicas. Paquete listo para revisión en [App Store](app-store.md); no enviar formularios con marcadores pendientes. No revocar certificados ni cambiar bundle ID para solucionar una exportación fallida.

Release verificado: versión 0.1.0, CFBundleVersion 23, bundle com.dafermen.vReader, iOS mínimo 17, familias 1 y 2, UIBackgroundModes=[audio], manifiesto presente sin tracking ni tipos declarados como recopilados. No equivale al informe de privacidad del archivo moderno final.

## Entrega remota

[Compilación verificada](https://appstoreconnect.apple.com/teams/6f8417db-fcfe-4f6e-99af-3d19a8ed6ceb/apps/6820599198/ci/builds/626c35bf-9845-46e7-8272-d011e3cee568). Check final GitHub `115127872696`, conclusión `success`; estado general del commit también `success`. El check inicial `115125378527` fue reemplazado: consultar siempre todos los checks del SHA exacto. La API de anotaciones no devolvió el detalle de las 4 advertencias; no se atribuyen a una causa sin los logs de Apple.

El commit posterior de documentación registra este resultado y aclara las notas del revisor; no cambia código. Una compilación disparada por ese commit es distinta de la aquí verificada. Procesamiento/distribución TestFlight, número efectivo instalado y prueba física nueva pendientes de confirmación. No se envió a App Review ni se publicaron páginas legales.
