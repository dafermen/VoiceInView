# VoiceInView para estudiantes y desarrolladores junior

## 1. Qué problema resuelve

VoiceInView convierte voz en inglés captada por el micrófono del iPhone en texto legible. Está pensada para clases, reuniones, conferencias y otras situaciones en las que conviene leer lo que se escucha.

El usuario puede ampliar la lectura, girar el teléfono, pausar, guardar una sesión, marcar frases y corregir palabras antes de compartir. Si activa la grabación antes de empezar, también puede conservar audio, reproducirlo y exportar subtítulos.

La app usa el reconocimiento de Apple en el dispositivo. No implementa un servidor propio ni una alternativa de reconocimiento en la nube. La disponibilidad del modelo de inglés y la precisión dependen del dispositivo y deben probarse. Descargar inicialmente un modelo puede necesitar Internet.

## 2. Tecnologías y vocabulario

| Concepto | Explicación sencilla | Uso en este proyecto |
| --- | --- | --- |
| Swift | Lenguaje con el que escribimos instrucciones y tipos | Servicios, reglas, modelos y pantallas |
| SwiftUI | Describe cómo debe verse una pantalla según sus datos | Vistas en UI |
| ViewModel | Prepara estado y acciones para una vista | CaptionViewModel |
| Protocolo | Contrato que diferentes implementaciones cumplen | SpeechTranscribing |
| SwiftData | Persistencia de objetos en un almacén local | TranscriptRepository |
| AVFoundation | APIs de Apple para capturar, convertir y reproducir audio | AudioCaptureService y grabador |
| Speech | APIs para convertir voz en texto | Motores moderno y de compatibilidad |
| async/await | Permite esperar una operación sin bloquear toda la interfaz | Permisos, reconocimiento, exportación |
| actor | Aísla estado para controlar el acceso concurrente | AudioConversion |
| UUID | Identificador estable que no depende del contenido del texto | Sesiones, párrafos y ejecuciones |
| Test doble o mock | Sustituto controlado de una dependencia durante una prueba | Reconocimiento simulado |

No necesitas npm, CocoaPods ni una clave de OpenAI. Es un proyecto nativo de Xcode sin paquetes externos requeridos.

## 3. El recorrido de una frase

Imagina que alguien dice “Welcome to the conference”.

1. El usuario pulsa Start Listening. La app verifica disponibilidad y permisos.
2. El micrófono entrega pequeños bloques de muestras, no palabras.
3. AudioCaptureService copia cada bloque y le asigna una posición en el reloj de audio.
4. El motor de Speech recibe los bloques. Puede emitir “Welcome”, después “Welcome to”, y finalmente la frase completa.
5. TranscriptAssembler sustituye las revisiones del mismo tramo. No añade una frase nueva por cada cambio parcial.
6. CaptionViewModel actualiza el estado observado por SwiftUI.
7. SessionCoordinator guarda los resultados finalizados mediante TranscriptRepository cuando corresponde.
8. Si el usuario habilitó Save audio, los bloques también pasan al grabador.
9. Después de Stop, el usuario revisa el texto, corrige errores, escucha la grabación o comparte archivos.

~~~mermaid
flowchart TD
    U[Usuario: Start Listening] --> VM[CaptionViewModel]
    VM --> S[Motor Speech]
    S --> A[AudioCaptureService]
    A --> B[Bloques copiados con tiempo]
    B --> S
    B --> R[SessionAudioRecorder opcional]
    S --> T[TranscriptAssembler]
    T --> VM
    VM --> UI[SwiftUI: lectura]
    VM --> C[SessionCoordinator]
    C --> DB[TranscriptRepository / SwiftData]
    DB --> E[Revisión y correcciones]
    E --> X[TXT / PDF / SRT / VTT]
    R --> P[Audio CAF local]
    P --> M[Reproducción / exportación M4A]
~~~

El diagrama muestra responsabilidades; no significa que todas se ejecuten en el mismo hilo ni que cada flecha sea una llamada síncrona.

## 4. Separar responsabilidades

La vista decide qué dibujar. El ViewModel decide si se puede empezar o pausar. El coordinador conecta la sesión activa con su almacenamiento. El repositorio decide cómo leer y guardar. El motor de voz transforma audio en resultados.

Esta separación permite cambiar una pantalla sin reescribir la base de datos. También permite probar una sesión sin hablar realmente al micrófono: se inyecta un objeto que cumple SpeechTranscribing y entrega respuestas conocidas.

Empieza a leer por [VoiceInViewApp](../VoiceInView/App/VoiceInViewApp.swift), después [AppRootView](../VoiceInView/UI/AppRootView.swift), [SessionCoordinator](../VoiceInView/ViewModels/SessionCoordinator.swift) y [CaptionViewModel](../VoiceInView/ViewModels/CaptionViewModel.swift). Consulta el [mapa del código](code-walkthrough.md) para continuar.

## 5. Dos motores de reconocimiento

El proyecto puede compilarse con herramientas distintas:

- Con el compilador de Xcode 15.2 se incluye el motor LegacySpeechTranscriber, basado en SFSpeechRecognizer.
- Con Swift 6.2 o posterior se puede incluir AppleSpeechTranscriber. Se selecciona en iOS 26 o posterior y usa SpeechAnalyzer/SpeechTranscriber.
- En sistemas anteriores se usa el motor de compatibilidad. La selección por versión no implica que el modelo esté instalado ni que el teléfono soporte todas las funciones.
- Si el motor seleccionado no está listo, se informa al usuario. No se envía el audio a un servidor como alternativa.

`#if compiler(>=6.2)` es una decisión al compilar. `if #available(iOS 26.0, *)` es una comprobación del sistema donde corre la app. Son preguntas diferentes: “¿mis herramientas conocen esta API?” y “¿el iPhone puede usarla?”.

En el motor de compatibilidad se cierra una solicitud después de 50 segundos de audio enviado. Mientras llega el resultado final, los nuevos bloques esperan en una cola limitada. Se abre una solicitud nueva con un UUID nuevo. Esto conserva la continuidad sin asumir que una petición puede durar indefinidamente.

## 6. Estados y operaciones asíncronas

CaptionState representa idle, preparing, listening, stopping, paused, ended o problem. Los botones dependen de ese estado: no se debe iniciar una segunda captura mientras la primera se prepara.

Una respuesta puede llegar tarde. Por ejemplo: el permiso tarda en responder y el usuario ya abandonó la pantalla. El ViewModel conserva un identificador de generación; antes de aplicar el resultado comprueba que siga perteneciendo a la operación actual.

`@MainActor` concentra los cambios de interfaz y la coordinación. No convierte todo el audio en una tarea de interfaz: el callback del micrófono, la cola de escritura y el actor de conversión tienen responsabilidades propias. Evita meter escritura de disco, esperas o trabajo pesado dentro del callback de audio.

## 7. Por qué se copia el audio

El sistema puede reutilizar la memoria del bloque entregado al micrófono. Guardar esa referencia para procesarla más tarde podría leer datos cambiados. AudioCaptureService crea una copia que los consumidores solo deben leer.

CapturedAudio usa `@unchecked Sendable`: el compilador confía en el desarrollador. No añade un candado ni hace seguro cualquier uso. La seguridad depende de copiar antes de compartir y no modificar después el buffer compartido.

SessionAudioRecorder limita a 128 los bloques pendientes. Si el disco no alcanza a escribirlos, la app muestra un fallo en lugar de dejar crecer la memoria sin límite. Su cola serial escribe en orden. CaptureTimeline protege su contador con un candado.

## 8. Tres clases de tiempo

| Reloj | Para qué sirve | Qué pasa al pausar |
| --- | --- | --- |
| Date | Fecha de inicio de la sesión | La hora real continúa |
| ContinuousClock | Duración de escucha activa | La app acumula solo intervalos activos |
| CaptureTimeline | Posición en audio grabado y subtítulos | No avanza si no entran muestras |

Ejemplo: 48 000 muestras a 48 000 Hz representan un segundo. CaptureTimeline acumula `frames / sampleRate`. Si se habla 5 segundos, se pausa 10 y se habla otros 5, la grabación tiene aproximadamente 10 segundos. Los subtítulos deben seguir ese mismo reloj, no los 20 segundos del reloj de pared.

Los motores suman el desplazamiento de cada ejecución al tiempo de sus resultados. De lo contrario, cada reinicio produciría subtítulos que vuelven incorrectamente al segundo cero.

## 9. Qué se guarda y por qué no se borra el original

| Modelo | Contenido |
| --- | --- |
| ConferenceSession | Identidad, título y metadatos de la sesión |
| StoredCaption | Texto reconocido y datos de orden de cada tramo final |
| CaptionBookmark | Marcador con una copia de la frase |
| SessionReview | Correcciones y posición de lectura |
| SessionMedia | Nombre relativo del audio y tiempos de los párrafos |
| SessionDraft | Marca que distingue un borrador recuperable de una sesión guardada |

Las correcciones son un mapa por UUID. El texto que se muestra se calcula como “corrección si existe; de lo contrario, original”. Así se puede restaurar el reconocimiento original. El editor trabaja sobre un borrador hasta que se guarda; deshacer no requiere reconocer la voz otra vez.

El esquema V4 añadió SessionMedia y V5 añade SessionDraft, sin modificar los modelos anteriores. Las migraciones anteriores conservan sesiones, marcadores y correcciones. Cambiar una estructura persistida no equivale a cambiar una variable temporal: hay usuarios con bases de datos antiguas.

La carpeta interna sigue llamándose vReader y el bundle ID sigue siendo com.dafermen.vReader. Renombrar esos identificadores para que “se vean más bonitos” puede romper la continuidad de instalaciones y datos.

El almacenamiento se excluye del backup. Los datos importantes deben exportarse; borrar la app puede hacer perder sus datos locales.

## 10. Audio y subtítulos

Durante la captura se guarda PCM de 16 bits en CAF. La codificación M4A ocurre al exportar. Mantener un archivo PCM abierto durante las pausas evita añadir relleno de un codificador cada vez que se retoma la escucha.

SubtitleExport convierte tiempos y palabras en pequeños bloques llamados cues. Agrupa por longitud, duración y silencios. Usa los tiempos originales si coinciden las palabras; si se modifica el párrafo, distribuye las palabras corregidas dentro del intervalo disponible. Esa sincronización es estimada, no una nueva alineación automática con la voz.

SRT usa una coma antes de los milisegundos; WebVTT usa punto y una cabecera WEBVTT. Ambos son archivos de texto con inicio, fin y contenido. El reproductor muestra el cue correspondiente al tiempo del audio.

Eliminar audio conserva texto y tiempos de subtítulos. Las sesiones antiguas sin tiempos no pueden generar sincronización real. Exportar “todo junto” comparte varios archivos mediante la hoja nativa; no implica insertar subtítulos dentro de un video ni crear un ZIP.

## 11. Qué significa escuchar otro video

La app escucha el micrófono. Un video de otra aplicación puede transcribirse si su sonido sale por el altavoz y llega físicamente al micrófono. No existe captura interna del audio de YouTube o de otras apps.

Save audio y Continue in background son preferencias diferentes: inicialmente apagadas, se recuerdan al cambiarlas. Al iniciar se toma una copia de la preferencia de audio para esa captura. El ajuste de segundo plano puede cambiar durante la escucha. Las llamadas y otras actividades pueden interrumpir la captura incluso con ambas activadas. La app no debe reactivar el micrófono a escondidas después de una interrupción. Con audífonos, el sonido del video normalmente no llega al micrófono como se necesita.

## 12. Cómo estudiar y practicar

1. Ejecuta la app en un simulador para conocer las pantallas. No concluyas que reconoce voz por ver texto de prueba.
2. Lee TranscriptAssembler y sus pruebas. Sigue una secuencia de resultados parciales y finales.
3. Lee TranscriptReview y prueba mentalmente una corrección, Undo y Restore original.
4. Lee CaptureTimeline y calcula el tiempo de dos bloques con distintas duraciones.
5. Lee SessionMediaTests para ver cómo se verifica audio generado sin una grabación de una persona.
6. Sigue una acción de la vista hasta el repositorio con el mapa del código.
7. Haz un cambio pequeño en una rama; ejecuta las comprobaciones pertinentes y revisa el diff antes de subirlo.

Ejercicios propuestos, no funciones nuevas ya implementadas:

- Explica por qué repetir la palabra “yes” no debe eliminarse como duplicado.
- Dibuja qué ocurre cuando Stop llega mientras se solicita permiso.
- Calcula una marca SRT para 65.125 segundos: 00:01:05,125.
- Diseña una prueba que compruebe que borrar audio no borra las correcciones.
- Compara lo que prueba un mock de Speech con lo que requiere un iPhone real.

## 13. Compilar no es publicar

Compilar traduce Swift a un programa. Archive prepara un paquete con metadatos. Exportar aplica firma y empaquetado de distribución. Subir envía el paquete a Apple. Procesar verifica el paquete del lado de Apple. Asignar a testers y actualizar TestFlight son pasos posteriores.

En octubre de 2026 aprendimos esa diferencia: Archive terminó bien, pero Cloud falló con HTTP 502 al consultar el equipo. El mismo archivo se exportó y subió desde el Mac. Lee la [guía de distribución](distribution-runbook.md) y el [historial de incidentes](build-incidents.md) antes de la próxima entrega.

## 14. Cómo saber si algo funciona

Una prueba unitaria demuestra una regla con entradas controladas. Una prueba de UI demuestra un recorrido con condiciones concretas. Ninguna sustituye una medición real de voz, latencia o batería.

La validación registrada para audio/subtítulos fue de 56 pruebas unitarias compatibles y 12 escenarios de interfaz, pasando estos últimos entre una ejecución completa y una repetición enfocada. La prueba moderna de conversión no se ejecutó con Xcode 15.2. Consulta [testing](testing.md) y [validation-report](validation-report.md) antes de repetir números o afirmar que todo está verificado.

## 15. Ejemplo: guardar no es lo mismo que recuperar

Piensa en un documento en edición: necesitamos recuperarlo tras un cierre inesperado, pero todavía no sabemos si el usuario quiere conservarlo. La transcripción funciona igual. Al iniciar, el repositorio crea ConferenceSession y una marca SessionDraft. Cada resultado final se escribe en disco. Stop cierra el audio y deja la marca; no decide por el usuario.

Save Session elimina solo la marca: el texto, audio, UUID y tiempos siguen siendo los mismos. Discard elimina la sesión y sus archivos después de confirmación. El botón + llama a newSession directamente cuando no hay decisión pendiente; si existe un borrador, ofrece guardar o descartar antes de limpiar la pantalla. Si guardar falla, la pantalla conserva la sesión para reintentar.

La migración es aditiva: una sesión antigua sin marca se considera guardada. Nunca debemos clasificar todas las sesiones antiguas como borradores solo porque añadimos una función. Las pruebas abren una base V4, migran a V5, cierran/reabren un borrador y verifican su texto y su archivo de audio.

Las preferencias pertenecen a AppSettings/UserDefaults; el estado de captura pertenece al ViewModel. Recordar “guardar audio” no significa activar el micrófono al abrir la app. Start sigue siendo una acción explícita. Cambiar esa preferencia a mitad de una sesión afecta a la siguiente: no podemos reconstruir audio pasado ni mover el origen de los subtítulos sin una implementación específica.

## 16. Del párrafo al audio, y del micrófono al indicador

Un párrafo tiene un UUID. SessionMedia guarda tiempos usando ese UUID. SubtitleExport transforma texto revisado y tiempos en cues: pequeños fragmentos con inicio y fin. Al tocar un párrafo, SessionDetailView abre SessionMediaView con su UUID; el reproductor busca el primer cue correspondiente y llama a play(from:). No calcula segundos a partir del número de letras ni usa el orden visual como si fuera tiempo.

play(from:) primero valida la posición y hace seek. Si el reproductor estaba pausado, inicia; si ya estaba reproduciendo, sigue. Reutilizar toggle() sin comprobar el estado sería un error: tocar la segunda frase pausaría el audio.

El tap del micrófono ya calcula RMS y entrega un nivel normalizado. El motor de Speech consume esa señal para detectar falta de audio y ahora comunica el nivel mediante onLevel. CaptionViewModel limita las actualizaciones visuales a unas diez por segundo y solo las acepta mientras escucha. El indicador no escribe muestras ni sustituye la grabación. Estado listening y recordingPrepared permiten distinguir transcribir de guardar audio.

Pausa finaliza el turno de Speech y conserva el borrador. Reanudar inicia otro turno dentro de la misma sesión. Una interrupción no autoriza reanudar por sí sola. Las pruebas provocan un error, comprueban que el UUID y texto final sobreviven, y exigen una llamada explícita a start().

Un gesto de ampliación usa estado temporal durante el movimiento. Solo al finalizar persiste el tamaño en AppSettings: esto evita escribir preferencias en cada actualización del gesto. Se limita al mismo intervalo que el control Aa. SessionTitle usa DateFormatter local y limpia el nombre al guardar; no necesita IA ni red.

SwiftUI describe vistas mediante tipos genéricos. Una cadena muy larga de modificadores puede resultar cara de comprobar para el compilador aunque sea rápida en ejecución. En esta entrega se midieron unos 176 segundos en el getter del lector; separar contenido, estilo, interacción y seguimiento redujo cada comprobación a menos de un segundo en la ejecución medida. Esto no es una medición de velocidad de transcripción. Los componentes conservan los mismos IDs de párrafo y acciones.
