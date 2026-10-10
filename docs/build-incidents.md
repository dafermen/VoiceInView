# Incidentes de desarrollo y distribución

Registro actualizado el 10 de octubre de 2026. Las horas del relato usan America/New_York; los logs pueden incluir UTC o la hora del worker. “Resuelto” solo se aplica al paso para el que existe evidencia.

## 1. Ruta y nombre del proyecto

El proyecto empezó como vReader y pasó a VoiceInView. El repositorio actual es dafermen/VoiceInView y el checkout utilizado está en /Users/dariomeneses/Projects/VoiceInView. Algunas sesiones de herramientas conservaron el cwd antiguo /Users/dariomeneses/Projects/vReader, que ya no existe.

Para la próxima sesión: confirmar pwd y git status antes de editar o ejecutar scripts. Actualizar el workspace del editor si apunta a la carpeta antigua. Si un entorno de herramientas restringe escrituras a la ruta anterior, usar sus permisos normales o corregir el workspace; no borrar y clonar de nuevo para resolver un fallo de rutas.

Se conservaron bundle ID com.dafermen.vReader y el directorio interno vReader para mantener identidad y datos.

## 2. Mac antiguo y dispositivo más nuevo

El Mac de desarrollo usa Ventura y Xcode 15.2. El objetivo original iOS 26 no compilaba allí. Se implementó compatibilidad iOS 17, selección de motor por compilador/OS y validación local con simulador iOS 17.2.

Los primeros intentos de instalación USB en un iPhone con iOS 27 mostraron Waiting to reconnect, dispositivo bloqueado y luego Could not support development al montar la imagen de desarrollo. Un error de dispositivo bloqueado no demuestra por sí solo incompatibilidad de Xcode; la segunda comprobación aportó un error diferente.

Camino útil: pruebas locales compatibles más compilación moderna en Cloud y distribución por TestFlight. El usuario confirmó funcionamiento básico de builds 5 y 6. Eso no certifica todas las funciones posteriores ni hace compatible el depurador antiguo con cualquier iPhone.

## 3. Acuerdos de Apple, GitHub y nombre ocupado

Durante la configuración aparecieron obstáculos distintos:

| Síntoma | Qué significaba / lección |
| --- | --- |
| Apple Developer Program License Agreement needs to be reviewed | Revisar el acuerdo con el titular de la cuenta; es una acción en Apple Developer |
| You must have Admin permission to the repository | El alta de Xcode Cloud necesita acceso adecuado al repositorio |
| La cuenta GitHub sigue visible después de borrarla en Xcode Accounts | La cuenta local y el acceso remoto de Cloud al repositorio son configuraciones distintas |
| Name vReader is already being used | El nombre de App Store Connect estaba ocupado; se adoptó VoiceInView |
| Workflow has no actions / Required to Pass | Añadir una acción; para esta distribución se usó Archive – iOS |
| Archive con Deployment Preparation=None | No prepara una entrega TestFlight; escoger la opción correspondiente al alcance |
| Missing Compliance | Completar la información de exportación solicitada por Apple |
| No Builds Available / Invited | Distinguir asignación de build, invitación, aceptación e instalación |

El historial demuestra que finalmente hubo un producto Cloud y TestFlight funcional, pero no conserva todos los clics exactos que corrigieron los permisos. No atribuir la solución a borrar credenciales si no existe evidencia.

## 4. Micrófono interrumpido al reproducir video

El usuario intentó reproducir YouTube en el mismo iPhone y recibió un mensaje de interrupción del micrófono. La app ahora configura mezcla de audio y ofrece continuidad en segundo plano por sesión. Eso no autoriza ni implementa captura interna de otras aplicaciones.

La fuente debe sonar por el altavoz y alcanzar el micrófono. Llamadas, rutas y decisiones de otras apps pueden interrumpirlo. La compatibilidad real debe probarse para cada escenario; no prometer que funciona con cualquier video o reunión.

## 5. Espera de Xcode y powerd

En una validación anterior, Xcode quedó esperando al servicio de energía. El comando de reinicio mediante launchctl devolvió Operation not permitted incluso con sudo. El usuario informó que killall powerd terminó sin error, pero el historial no demuestra que eso haya sido la causa de la recuperación.

No incorporar esos comandos en scripts del proyecto ni presentarlos como remedio de firma o del HTTP 502. Antes de intervenir servicios del sistema, investigar el proceso bloqueado y conservar diagnósticos. No desactivar protecciones de macOS.

## 6. Regresiones detectadas en pruebas de interfaz

La validación de audio/subtítulos detectó seguimiento inestable al añadir párrafos a una lista lazy. Se corrigió el scroll coalesciendo actualizaciones y repitiéndolo después del layout, respetando la relectura.

También se ajustaron una espera de carga de fixture largo, la identificación de un botón de edición duplicado y el cierre de la hoja nativa de compartir en las pruebas. Los 12 escenarios pasaron entre la ejecución final completa y la repetición enfocada. No describirlo como una única ejecución completa de 12/12 después de todos los ajustes.

## 7. Builds 9, 10 y 11: Archive correcto, exportación fallida

| Ejecución | Herramientas observadas | Resultado |
| --- | --- | --- |
| Build 9 | Xcode 27.0 (27A266a) | ARCHIVE SUCCEEDED; exportaciones App Store, Ad Hoc y Development fallan |
| Build 10 | Xcode 27.0 (27A266a) | Mismo HTTP 502 en consulta del equipo |
| Build 11 | Xcode 26.6 (17F113), macOS Tahoe 26.5.1 seleccionado | ARCHIVE SUCCEEDED; mismo HTTP 502 |
| Exportación desde Mac, 10/oct, ~00:06 | Xcode 15.2 sobre el archivo Cloud 11 | EXPORT SUCCEEDED |
| Subida desde Mac, 10/oct, ~00:07 | Mismo archivo, destination=upload | Upload succeeded; Apple inicia procesamiento |

Los logs de exportación mostraron esta secuencia:

~~~text
Session Proxy Provider: Unable to authenticate with App Store Connect
HTTP 502 ... /services/QH65B2/listTeams.action
error: exportArchive Communication with Apple failed
error: exportArchive No profiles for 'com.dafermen.vReader' were found
** EXPORT FAILED **
~~~

El endpoint localhost:6667 es el proxy del worker de Cloud. No es el servidor del Mac del desarrollador. La consulta de equipo ya había fallado cuando apareció el mensaje sobre perfiles.

### Qué se intentó y qué demuestra

- Repetir la compilación mantuvo el error.
- Cambiar de Xcode 27 a 26.6 mantuvo el error. No fue una reparación.
- Revisar el comando visible y exit-code 70 no bastó; la causa observable estaba en el ZIP Logs.
- Exportar el mismo archivo desde el Mac sí funcionó, con firma Cloud Managed Apple Distribution.
- Subir desde el Mac también funcionó. No se reescribió el código ni se alteró el SDK del binario.
- No se revocaron certificados ni se cambió el bundle ID como remedio.
- Se preparó un informe para Apple; el usuario indicó que todavía no lo había enviado.

### Conclusión acotada

Se aisló el fallo de comunicación/autenticación del entorno Cloud y se comprobó una alternativa desde el Mac. No se determinó si la causa interna de Apple era una incidencia de servicio, autorización de sesión u otro problema. No se reparó ni se confirmó recuperada la exportación automática de Cloud.

El IPA exportado conservó SDK iphoneos26.5 y DTXcodeBuild 17F113. Xcode 15.2 se usó para exportar/subir un binario moderno, no para recompilarlo con su SDK antiguo.

El número “Build 11” identifica una ejecución Cloud. El archivo fuente tenía CFBundleVersion=1; la opción de gestión automática de versión/build se habilitó para subir. El número final en TestFlight no se confirmó. No etiquetar la entrega como “TestFlight build 11” sin comprobarlo allí.

### Evidencia y conservación

Se leyeron los ZIPs originales de Logs de builds 9, 10 y 11 y el archivo de Build 11. El log local de subida terminó en Uploaded package is processing, Upload succeeded y EXPORT SUCCEEDED.

Las evidencias locales se generaron bajo /private/tmp/VoiceInView-Build11-LocalExport y otros directorios temporales de diagnóstico. Pueden desaparecer y no están en Git. Para nuevos intentos usar un directorio privado persistente y la [guía de distribución](distribution-runbook.md).

## 8. Advertencias Swift pendientes

Build 11 mostró:

- AudioConversion: importación de AVFAudio y captura de AVAudioPCMBuffer no Sendable en un closure @Sendable.
- RecordingExport, en SessionMediaView: captura de AVAssetExportSession no Sendable en el handler de cancelación; sería error en Swift 6 language mode.
- En builds anteriores se observó advertencia sobre la captura weak de self en AudioCaptureService.

No fueron el error de exportación: Archive terminó correctamente. Son deuda técnica que debe analizarse antes de migrar el modo de lenguaje. Revisar aislamiento, propiedad y cancelación; no aplicar atributos para silenciarlas sin pruebas con el SDK moderno. Esta actualización documental no las corrige.

## 9. Qué hacer si vuelve a ocurrir

1. Identificar si falla compilación, firma, subida, procesamiento o acceso del tester.
2. Guardar el error completo del ZIP Logs, con fecha/build/commit/herramientas.
3. Si se repite listTeams 502 con Archive correcto, utilizar la alternativa de exportación local comprobada, verificando que siga siendo compatible.
4. Si el Mac también falla, diagnosticar su nuevo error; no suponer que sea el mismo.
5. Si Apple rechaza el procesamiento, conservar ese rechazo por separado de Upload succeeded.
6. Actualizar este registro con el resultado observado, incluyendo intentos que no funcionaron.
