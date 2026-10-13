# Punto de reanudación — build fuente 23

Actualizado 2026-10-13. Trabajo autorizado: reproducción A mi ritmo, corrección directa, favoritas protegidas, idioma de pestañas y preparación documental para App Store. Publicación pública no solicitada.

Implementación: [guía funcional/técnica](at-my-pace.md). Esquema V8, identidad `com.dafermen.vReader` conservada. Proyecto real `/Users/dariomeneses/Projects/VoiceInView`; la ruta antigua vReader no es la carpeta del proyecto.

Estado: implementación y verificación local completas; pendiente de subir y verificar Cloud. Release final pasó (`/private/tmp/VoiceInView23-release-final.log`). La suite de 99 pruebas unitarias pasó (`/private/tmp/VoiceInView23-final.xcresult`); ese bundle también registra un fallo de navegación de test de exportación y otro de selección de párrafo traducido, por eso el resultado global del bundle es fallido. No presentarlo como una ejecución íntegramente verde.

Repeticiones: A mi ritmo/favoritas e idioma pasaron en iPhone; exportación de SRT y eliminación independiente de audio pasó en `/private/tmp/VoiceInView23-review.xcresult`. Traducción corregida/cancelada y exportada pasó en `/private/tmp/VoiceInView23-translation.xcresult` (92.960 s). El recorrido iPad pasó en `/private/tmp/VoiceInView23-ipad-final.xcresult` (45.475 s); la ejecución `/private/tmp/VoiceInView23-ipad-rotation.xcresult` pasó también (46.861 s), esperando ancho mayor que alto y controles interactuables antes de capturar. El cambio de idioma iPad pasó en `/private/tmp/VoiceInView23-ipad.xcresult` (21.944 s), aunque ese bundle global incluye el primer fallo de automatización del popover. Las correcciones de automatización conservan las aserciones de datos, guardado y cancelación.

Catálogos: 507 claves Localizable y 2 de permisos, mismas claves/placeholders EN/ES. No se obtuvieron `.stringsdata`; no atribuir cobertura de extracción del compilador al chequeo de catálogos. Metadata EN/ES dentro de los límites, enlaces relativos de documentación válidos. `validate-store-metadata.py --ready` rechaza correctamente los campos de publicación todavía pendientes.

Pendientes del titular: correo público de soporte/privacidad, identidad editorial, alojamiento/URLs públicas. Paquete listo para revisión en [App Store](app-store.md); no enviar formularios con marcadores pendientes. No revocar certificados ni cambiar bundle ID para solucionar una exportación fallida.

Release verificado: versión 0.1.0, CFBundleVersion 23, bundle com.dafermen.vReader, iOS mínimo 17, familias 1 y 2, UIBackgroundModes=[audio], manifiesto presente sin tracking ni tipos declarados como recopilados. No equivale al informe de privacidad del archivo moderno final.
