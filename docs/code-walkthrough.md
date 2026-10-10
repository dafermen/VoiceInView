# Recorrido del código para estudiantes

Esta guía responde “¿dónde está?”, “¿qué recibe?” y “¿qué produce?”. Los comentarios `///` de las clases principales complementan estas explicaciones y se pueden consultar en Xcode. Los comentarios describen contratos y decisiones; no cambian el comportamiento.

## Mapa de responsabilidades

| Archivo | Qué hace y cómo conecta con el resto |
| --- | --- |
| [VoiceInViewApp](../VoiceInView/App/VoiceInViewApp.swift) | Punto de entrada @main; crea la escena que contiene AppRootView |
| [AppRootView](../VoiceInView/UI/AppRootView.swift) | Abre el almacén, crea el coordinador, conecta pestañas y cambios de foreground/background; muestra error recuperable si no abre la base |
| [CaptionScreen](../VoiceInView/UI/CaptionScreen.swift) | Presenta lectura, controles, fullscreen, opciones y seguimiento; conserva la posición al releer |
| [CaptionViewModel](../VoiceInView/ViewModels/CaptionViewModel.swift) | Permisos, readiness, máquina de estados, consumo del stream y generación para ignorar respuestas obsoletas |
| [SessionCoordinator](../VoiceInView/ViewModels/SessionCoordinator.swift) | Conecta eventos del ViewModel con persistencia, grabación, marcadores y vigilancia de espacio |
| [SpeechTranscribing](../VoiceInView/Services/Speech/SpeechTranscribing.swift) | Contrato que permite intercambiar motor real y test doble |
| [LegacySpeechTranscriber](../VoiceInView/Services/Speech/LegacySpeechTranscriber.swift) | Rotación de solicitudes, cola pendiente y desplazamiento temporal |
| [LegacySpeechBackend](../VoiceInView/Services/Speech/LegacySpeechBackend.swift) | Adaptador de SFSpeechRecognizer con reconocimiento local obligatorio |
| [AppleSpeechTranscriber](../VoiceInView/Services/Speech/AppleSpeechTranscriber.swift) | Activos de inglés, SpeechAnalyzer, tareas de entradas/resultados y tiempos del motor moderno |
| [AudioConversion](../VoiceInView/Services/Speech/AudioConversion.swift) | Actor que conserva AVAudioConverter y adapta buffers al formato que pide Speech |
| [AudioCaptureService](../VoiceInView/Services/Audio/AudioCaptureService.swift) | Configura AVAudioSession, selecciona micrófono integrado, copia buffers y entrega nivel/audio |
| [CapturedAudio](../VoiceInView/Services/Audio/CapturedAudio.swift) | Copia de audio de solo lectura y posición opcional en el reloj de sesión |
| [SessionAudioRecorder](../VoiceInView/Services/Audio/SessionAudioRecorder.swift) | Cola limitada, CAF, errores de escritura y reloj de muestras CaptureTimeline |
| [TranscriptAssembler](../VoiceInView/Models/TranscriptAssembler.swift) | Convierte revisiones del reconocimiento en cambios de párrafos finales |
| [TranscriptRepository](../VoiceInView/Persistence/TranscriptRepository.swift) | SwiftData, migraciones, upserts, correcciones, rutas de audio y borrado |
| [SessionMedia](../VoiceInView/Models/SessionMedia.swift) | Modelo V4 y estructuras de tiempos de palabras/párrafos |
| [TranscriptReview](../VoiceInView/Models/TranscriptReview.swift) | Texto corregido, historial Undo/Redo y búsqueda literal |
| [TranscriptEditorView](../VoiceInView/UI/TranscriptEditorView.swift) | Borrador de edición, confirmación de descarte y guardado explícito |
| [TranscriptShareView](../VoiceInView/UI/TranscriptShareView.swift) | Vista previa común antes de copiar o exportar TXT/PDF |
| [SessionMediaView](../VoiceInView/UI/SessionMediaView.swift) | Reproducción, cues activos, edición, exportación temporal y limpieza |
| [SubtitleExport](../VoiceInView/Utilities/SubtitleExport.swift) | Cues y serialización SRT/WebVTT, sin acceder al micrófono ni a SwiftData |

## Seguir Start, Pause y Stop

En CaptionViewModel.start, identifica los guard que rechazan estados incompatibles. Después de cada await relevante se vuelve a comprobar la generación. La operación pudo cambiar mientras estaba suspendida.

El coordinador instala onWillStart: crea una sesión persistida si debe guardar y prepara el archivo si se eligió grabación. onFinalized aplica únicamente cambios finales. onCheckpoint guarda duración. onEnded conserva el estado al terminar. Esos callbacks separan reconocimiento y almacenamiento.

Pause/Stop finalizan el reconocimiento cuando corresponde; cancel sirve para abortar. No son intercambiables: cancelar puede descartar texto provisional. Resume usa una nueva identidad de ejecución. El archivo de audio puede seguir abierto entre pausas, pero Stop lo cierra.

## Seguir una revisión de texto

TranscriptAssembler.apply recibe TranscriptionUpdate y devuelve FinalizedChange:

- removedIDs identifica filas que dejaron de representar el resultado.
- upserted contiene párrafos nuevos o actualizados. Un upsert inserta si no existe y actualiza si existe.
- Dos resultados se comparan por runID e intervalo, no por igualdad de palabras.
- Se conserva el UUID cuando se reemplaza un tramo para evitar recrear su identidad en la interfaz.
- runOrder conserva el orden de ejecuciones aunque llegue tarde una corrección de una ejecución anterior.

TranscriptRepository.apply transforma ese cambio en filas persistentes. Reintentar un guardado con las mismas identidades no debe duplicar el texto. Solo almacena tiempos de subtítulos cuando el segmento declara que usa el reloj de sesión.

## Seguir una corrección del usuario

TranscriptReview.paragraphs resuelve originales más correcciones. EditHistory mantiene valor actual, pasado y futuro; limita el pasado a 100 snapshots. Una nueva edición limpia el futuro de Redo.

TranscriptSearch escapa la consulta para que sea literal. Usa NSRange/NSString en UTF-16, coherente con NSRegularExpression. No mezclar esos offsets directamente con índices de String de Swift, especialmente con emoji. En reemplazos múltiples importa el orden para no desplazar los rangos pendientes.

El repositorio valida que los párrafos editados sigan perteneciendo a la sesión. Guardar la corrección no sobrescribe el reconocimiento original. Las distintas pantallas y exportadores deben resolver el mismo mapa.

## Seguir la creación de subtítulos

1. SessionMedia guarda un diccionario JSON: UUID de párrafo → CaptionTiming.
2. SubtitleExport.cues recibe ReviewParagraph corregidos y ese diccionario.
3. Valida los rangos y divide texto/palabras. Conserva tiempos nativos cuando coinciden; estima posiciones cuando cambió el texto.
4. Agrupa por longitud aproximada, hasta 5 segundos y cortes de silencio mayores de 0.8 segundos.
5. Ordena, redondea a milisegundos y recorta contra el siguiente cue. Descarta los de duración no positiva.
6. render produce texto SRT o WebVTT escapando caracteres de marcado.

Los límites ayudan a la legibilidad; no constituyen una certificación de estándares profesionales de subtitulado. Las pruebas incluyen correcciones, silencios, formato y ausencia de tiempos inventados para sesiones antiguas.

## Seguir un archivo compartido

SessionMediaView.prepareExport crea un directorio temporal único. RecordingExport.m4a usa AVAssetExportSession sobre el CAF, y el resto de archivos usa el texto revisado y los cues. MediaActivityView conecta SwiftUI con UIActivityViewController.

La tarea comprueba cancelación. cleanup borra los temporales al cerrar/cancelar; no borra la grabación original. El destino elegido por el usuario puede subir archivos a Internet, aunque VoiceInView no tenga un cliente de red propio.

## Límites de concurrencia que debes respetar

- UI, coordinador y contexto SwiftData: MainActor.
- Conversión moderna: actor AudioConversion.
- Grabación: cola serial con límite de bloques pendientes.
- Reloj de muestras: acceso protegido con NSLock.
- Buffer copiado: contrato de solo lectura, no protección mágica por Sendable.
- Callbacks de un motor antiguo: se descartan mediante generación.

Build 11 dejó advertencias de Sendable en AudioConversion y RecordingExport. Están registradas en [incidentes](build-incidents.md). No cambiar a Swift 6 language mode ni añadir @unchecked Sendable o @preconcurrency solo para ocultarlas sin revisar la propiedad de los objetos y ejecutar pruebas.

## Qué probar cuando cambias una pieza

| Cambio | Evidencia pertinente |
| --- | --- |
| Revisión parcial/final y orden | TranscriptAssemblerTests |
| Ciclo de escucha y opciones de fondo | CaptionViewModelTests / LegacySpeechTranscriberTests |
| Migración, correcciones y borrado | TranscriptRepositoryTests / SessionMediaTests |
| Texto revisado y búsqueda | TranscriptExportTests |
| Audio, reloj y subtítulos | SessionMediaTests; AudioConversionTests con herramientas modernas |
| Fullscreen, lectura y reproductor | HomeScreenTests y revisión visual en ambas orientaciones |
| Firma o distribución | Registros de archive/export/upload; una prueba de UI no valida certificados |

El [plan de pruebas](testing.md) distingue los escenarios automatizados de los que requieren un iPhone.
