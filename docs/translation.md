# Traducción de sesiones guardadas — build 16

## Uso

1. Guarda la sesión y abre **Sessions → tu sesión → Translate to Spanish**.
2. Pulsa **Translate to Spanish**. La primera vez, Apple puede solicitar permiso para descargar inglés y español. Se requiere iOS 18 o posterior y una compilación con el SDK de Translation.
3. La vista abre en **Español** al finalizar. El selector permite **English**, **Español** o **Both**.
4. **Edit Spanish** permite corregir, buscar/reemplazar y deshacer. Guardar modifica solo el español. **Restore translation** restaura la traducción automática dentro del borrador de edición.
5. Compartir ofrece copiar, TXT, PDF, SRT y WebVTT del idioma seleccionado. **Audio & subtitles** reproduce el audio inglés con esos subtítulos; no genera voz española.

La traducción se inicia explícitamente sobre el texto inglés ya corregido. No requiere grabar audio. Puede cancelarse; un intento incompleto no reemplaza una traducción anterior. Traducir otra vez solicita confirmación porque reemplaza también las correcciones españolas.

Si editas el inglés, el snapshot español queda desactualizado: se muestra un aviso y se oculta su lectura/exportación hasta traducir otra vez. El inglés y la copia española anterior permanecen guardados. El idioma de escucha sigue siendo inglés; esta entrega no incluye traducción durante la captura.

## Subtítulos y sincronización

Se reutilizan los UUID de párrafo y las ventanas de subtítulos ingleses. Las palabras españolas se distribuyen proporcionalmente entre esas ventanas. El resultado mantiene el reloj de la sesión, pero la correspondencia palabra a palabra es **aproximada**. La vista bilingüe coloca inglés y español en el mismo intervalo. Revisa legibilidad y tiempos antes de publicar un video.

Las sesiones antiguas sin tiempos pueden traducirse y exportarse como texto/PDF, pero no generan SRT/VTT sincronizado. Cuando hay una grabación parcial, la exportación se limita a su duración disponible. Las pausas eliminadas del audio siguen eliminadas de los subtítulos. El reloj no corresponde automáticamente a un video externo.

## Diseño para estudiantes

- `SessionTranslation`: nuevo modelo independiente en el esquema V6. V1–V5 no cambian; una migración aditiva conserva sesiones, borradores, marcadores, audio y correcciones.
- `TranslationSnapshot.source`: copia exacta de los párrafos ingleses corregidos al iniciar. Compararla con el texto actual detecta traducciones obsoletas, incluso si los UUID siguen siendo iguales.
- `generated`: español automático con los mismos UUID y orden. `edits`: diccionario de cambios del usuario. Así se puede restaurar el resultado automático sin tocar el inglés.
- `saveTranslation`: valida IDs, respuestas completas y vigencia antes de codificar JSON y guardar de forma atómica. Fallos de idioma, cancelación o descarga no producen una traducción parcialmente guardada.
- `AppleTranslationRunner`: usa `TranslationSession` de Apple, prepara idiomas y procesa párrafos completos. Reporta progreso y comprueba cancelación. El UUID del intento impide guardar una respuesta tardía después de cancelar.
- `TranslatedSubtitles`: función pura y comprobable; no llama al traductor ni al disco. Reutiliza tiempos originales y escapa texto al renderizar SRT/WebVTT.
- `SessionTranslationView`: concentra selección de idioma, edición, exportación y reproducción. La pantalla de captura permanece libre de controles adicionales.

## Compatibilidad y privacidad

La app sigue admitiendo iOS 17. En ese sistema no se generan traducciones, pero una traducción previamente guardada se puede leer, editar y compartir. `#if canImport(Translation)` permite compilar con Xcode 15.2; la rama de Apple necesita un SDK más reciente y `#available(iOS 18.0, *)` protege su ejecución.

El contenido y las traducciones se guardan localmente, sin CloudKit y excluidos del backup junto con la base existente. Eliminar la sesión elimina su traducción. La app no añade servicios de terceros, claves, cuentas ni clientes HTTP. Apple gestiona la descarga de idiomas y puede recoger métricas del uso de su API que no incluyen el contenido original o traducido, según su documentación. Compartir transmite únicamente al destino elegido por el usuario.

## Validación y límites

Consultar [el informe de validación](validation-report.md). Las pruebas con español prefijado en DEBUG verifican interfaz/persistencia/exportación, **no** la calidad ni el funcionamiento real del traductor de Apple. Es necesario probar en un iPhone iOS 18+: descarga, rechazo de descarga, cancelación, modo avión con idiomas instalados, texto extenso, cierre/reapertura y calidad inglés→español.

Fuentes oficiales:
- [TranslationSession](https://developer.apple.com/documentation/translation/translationsession)
- [Traducción dentro de una app](https://developer.apple.com/documentation/translation/translating-text-within-your-app)
