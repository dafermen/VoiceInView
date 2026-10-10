# Sesiones: iniciar, guardar y descartar

Implementado en fuente para 0.1.0 build 14. La disponibilidad en TestFlight debe comprobarse por separado.

## Recorrido principal

1. En Captions, elige Audio y Background. La elección se recuerda para futuras sesiones y al cerrar/reabrir la app.
2. Pulsa el micrófono circular para iniciar. Cambia a pausa mientras escucha y a reproducir para continuar. El cuadrado circular termina la captura.
3. Tras Stop, pulsa Save Session para conservarla en la biblioteca o Discard para eliminar el texto y cualquier audio, previa confirmación.
4. El + azul prepara otra sesión con un solo toque si ya guardaste. Si queda un borrador pendiente, ofrece Save and new session, Discard and new session o Cancel. No inicia el micrófono automáticamente.

Los iconos mantienen etiquetas para VoiceOver y áreas de toque de 44 puntos. Guardar y Descartar conservan texto visible porque deciden qué datos se conservan. Durante la escucha, los indicadores de audio y segundo plano abren las preferencias sin ir a Settings. En fullscreen se mantienen los controles de captura y el acceso mediante indicadores compactos.

## Preferencias frente a captura actual

Ambas preferencias están apagadas al instalar por primera vez. Después se conserva la elección del usuario. La grabación usa la preferencia que había al iniciar. Cambiar Audio durante una sesión prepara la siguiente, sin crear audio retroactivo. Segundo plano puede activarse/desactivarse para la sesión actual desde sus preferencias. Llamadas o interrupciones de iOS siguen deteniendo la captura; no hay reanudación automática.

## Borradores de recuperación

Los resultados finales se guardan en disco durante la escucha, junto con el audio si se activó. Stop mantiene el borrador pendiente de decisión. Sessions los muestra separados de Saved sessions, incluso después de reabrir la app. Puedes abrirlos para revisar el texto/audio y después guardarlos o descartarlos desde esa lista. El borrador activo debe detenerse antes de esas acciones.

Guardar quita la marca de borrador y conserva la identidad, texto, audio, correcciones y tiempos. Descartar borra estos datos de esa sesión; las copias previamente exportadas quedan bajo control de su destino. Si hay un error de almacenamiento se muestra y no se inicia otra sesión automáticamente. La recuperación conserva lo que ya se escribió: no garantiza recuperar texto provisional ni todas las muestras de audio tras una terminación abrupta. Los datos locales están excluidos del backup; exporta lo importante.

## Para quien desarrolla

- AppSettings guarda preferencias; CaptionViewModel mantiene el estado actual y la elección de audio de esa captura.
- SessionCoordinator conecta Start/Stop, checkpoints, publicación y descarte. newSession protege las decisiones pendientes.
- TranscriptRepository crea sesión y SessionDraft juntos; publish elimina la marca. La migración V5 añade este modelo y deja guardadas todas las sesiones anteriores sin marca.
- Pruebas: persistencia de preferencias, separación Stop/Save, descarte aislado, migración V4, reapertura de borrador y recorrido de UI incluyendo fullscreen horizontal.

La grabación que empieza a mitad de sesión queda fuera de esta entrega; requiere definir el desplazamiento del audio respecto a los subtítulos.
