# Próxima compilación y distribución a TestFlight

Última verificación: 10 de octubre de 2026, zona America/New_York. Esta guía describe lo que funcionó para VoiceInView; los requisitos y las versiones admitidas por Apple pueden cambiar.

## 1. Datos que deben conservarse

| Dato | Valor |
| --- | --- |
| Repositorio | https://github.com/dafermen/VoiceInView.git |
| Proyecto / esquema | VoiceInView.xcodeproj / VoiceInView |
| Rama de distribución actual | main |
| Workflow de Cloud | VoiceView (nombre distinto del producto; no es un error) |
| Bundle ID | com.dafermen.vReader |
| Equipo Apple | 7799N4RYUG |
| App Store Connect app ID | 6820599198 |
| Grupo interno de testers | Dev |
| Versión en el proyecto | 0.1.0 |
| Build en el proyecto | 1; comprobar el número efectivo de cada subida en App Store Connect |
| Almacenamiento local de sesiones | Application Support/vReader/Sessions.store |
| Entorno Cloud seleccionado tras la prueba | Xcode 26.6 (17F113), macOS Tahoe 26.5.1 (25F80) |
| Mac utilizado para exportar | Xcode 15.2, macOS Ventura 13.7.8 |

Un nombre visible, un nombre de workflow y un bundle ID cumplen funciones diferentes. No cambiar el bundle ID para resolver un nombre ocupado o un fallo de exportación.

## 2. Qué está demostrado

Builds 9 y 10 compilaron con Xcode 27 y fallaron al exportar. Build 11 compiló con Xcode 26.6 y presentó el mismo HTTP 502 al consultar el equipo. Cambiar de versión no corrigió ese fallo.

El archivo de Build 11 se descargó y se exportó desde el Mac con Xcode 15.2. La salida confirmó EXPORT SUCCEEDED. Después, otra operación con destination=upload confirmó Upload succeeded y que Apple había iniciado el procesamiento.

El binario exportado conservó DTXcodeBuild=17F113 y DTSDKName=iphoneos26.5: se compiló en Cloud, no se recompiló con el SDK de Xcode 15.2. La firma utilizó un certificado Cloud Managed Apple Distribution y un perfil de App Store válido. Exportar desde el Mac sigue necesitando conexión y servicios de Apple; no fue una firma completamente offline.

Esta combinación funcionó con este archivo. No demuestra que cualquier Xcode antiguo pueda exportar cualquier archivo futuro. Tampoco confirma que el paquete ya esté disponible para testers.

## 3. Antes de iniciar una entrega

1. Revisar cambios y estado de Git; conservar el commit exacto.
2. Ejecutar las [validaciones adecuadas](testing.md). Para cambios funcionales, usar la suite y escenarios físicos pertinentes.
3. Verificar equipo, bundle ID, esquema compartido y permisos. No guardar credenciales en el repositorio.
4. Revisar versión/build y registrar el último build aceptado en App Store Connect. El número de ejecución de Cloud no es necesariamente CFBundleVersion.
5. Revisar acuerdos o avisos que aparezcan al titular en Apple Developer / App Store Connect.
6. Comprobar que el workflow usa un Xcode/SDK admitido para subir a Apple. Confirmar los [requisitos vigentes de SDK](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).
7. Revisar [incidentes conocidos](build-incidents.md) y no repetir una solución ya descartada sin evidencia nueva.

Guardar y subir documentación también puede disparar el workflow actual: Branch Changes está configurado para cualquier archivo de main. No confundir esa ejecución con una entrega funcional nueva.

## 4. Camino normal con Xcode Cloud

En App Store Connect → VoiceInView → Xcode Cloud → Workflows → VoiceView:

- Environment: elegir una versión estable explícita. El último intento documentado usó Xcode 26.6 y macOS Tahoe 26.5.1. No se afirma que esa combinación haya reparado Cloud.
- Branch Changes: main.
- Actions: Archive – iOS, esquema VoiceInView.
- Deployment Preparation: TestFlight (Internal Testing Only) para el grupo interno, o la opción de TestFlight and App Store si la entrega requiere ese alcance.
- Guardar el workflow. Desde Builds, Start Build sobre main.

Un workflow sin acciones no se puede guardar. Build/Test/Analyze no sustituyen el Archive necesario para este recorrido de distribución.

Después del build, distinguir:

| Mensaje | Qué permite concluir |
| --- | --- |
| ARCHIVE SUCCEEDED | Se produjo el archivo compilado |
| EXPORT SUCCEEDED | Se completó exportación/firma según sus opciones |
| Upload succeeded | Apple recibió la subida |
| Processing | Apple aún procesa el paquete |
| Ready to Test / Testing | Revisar asignación de grupo y disponibilidad para el tester |
| Actualización instalada en iPhone | Solo se confirma desde el dispositivo/TestFlight |

Si Cloud falla al exportar, abrir Build → Archive – iOS → Artifacts y descargar Logs y Archive. El ZIP XCResult ayuda con compilación/pruebas; para este incidente la información decisiva estaba en el ZIP Logs.

## 5. Diagnóstico rápido antes de modificar nada

Abrir dentro del ZIP Logs:

~~~text
app-store-export-archive-logs/xcodebuild-export-archive.log
app-store-export-archive-logs/*.xcdistributionlogs/IDEDistribution.critical.log
app-store-export-archive-logs/*.xcdistributionlogs/IDEDistribution.standard.log
~~~

El comando mostrado como Run command y el exit-code 70 no contienen por sí solos la causa. Buscar errores anteriores a EXPORT FAILED. Comparar la primera operación que falla entre intentos.

En este incidente, listTeams devolvió 502 y después apareció “No profiles … were found”. No se demostró que faltaran perfiles realmente: la consulta previa ya había fallado. No revocar certificados ni recrear identificadores basándose únicamente en ese mensaje secundario.

No copiar el comando del worker Cloud para ejecutarlo en el Mac: /Volumes/workspace y localhost:6667 pertenecen a ese entorno y no son rutas/servicios del equipo local.

## 6. Alternativa comprobada: exportar el archivo Cloud desde el Mac

Requisitos: archivo confiable de este proyecto descargado de Artifacts, Xcode instalado y cuenta Apple configurada con acceso al equipo. Una petición de autenticación o llavero se atiende en la interfaz de macOS; nunca escribir contraseñas en documentación o chats.

Descomprimir el ZIP de Archive en una carpeta local. No modificar el ejecutable, el SDK ni los metadatos del archivo para simular otra compilación. Conservar el original.

Desde la raíz del repositorio, en bash/zsh, ajustar solo la ruta del archivo real:

~~~sh
export VOICEINVIEW_ARCHIVE='/ruta/real/VoiceInView.xcarchive'
export VOICEINVIEW_XCODEBUILD='/Applications/Xcode 15.2.app/Contents/Developer/usr/bin/xcodebuild'
mkdir -p build
export VOICEINVIEW_DISTRIBUTION_DIR="$(mktemp -d "$PWD/build/distribution.XXXXXX")"
test -d "$VOICEINVIEW_ARCHIVE"
test -x "$VOICEINVIEW_XCODEBUILD"
~~~

Los dos test deben terminar con código 0; si no, corregir las rutas antes de seguir. build/ está ignorado por Git. Usar un directorio nuevo evita mezclar una entrega con otra.

Inspeccionar identidad y SDK del archivo:

~~~sh
plutil -p "$VOICEINVIEW_ARCHIVE/Info.plist"
plutil -p "$VOICEINVIEW_ARCHIVE/Products/Applications/VoiceInView.app/Info.plist"
~~~

Confirmar el bundle ID, versión y SDK esperado. El archivo previo a exportar puede mostrar equipo/firma vacíos; validar el resultado de distribución, no concluir que está roto solo por esos campos.

Crear opciones de exportación:

~~~sh
python3 - <<'PY'
import os, plistlib
from pathlib import Path
options = {
    "method": "app-store",
    "destination": "export",
    "teamID": "7799N4RYUG",
    "signingStyle": "automatic",
    "uploadSymbols": False,
    "manageAppVersionAndBuildNumber": True,
}
path = Path(os.environ["VOICEINVIEW_DISTRIBUTION_DIR"]) / "ExportOptions.plist"
with path.open("wb") as file:
    plistlib.dump(options, file)
PY
~~~

Este ejemplo reproduce opciones aceptadas por Xcode 15.2. Herramientas nuevas pueden preferir el nombre app-store-connect. Consultar el help de la versión utilizada antes de adaptar las opciones.

Exportar sin subir todavía:

~~~sh
set -o pipefail
"$VOICEINVIEW_XCODEBUILD" -exportArchive \
  -archivePath "$VOICEINVIEW_ARCHIVE" \
  -exportPath "$VOICEINVIEW_DISTRIBUTION_DIR/Export" \
  -exportOptionsPlist "$VOICEINVIEW_DISTRIBUTION_DIR/ExportOptions.plist" \
  -allowProvisioningUpdates \
  2>&1 | tee "$VOICEINVIEW_DISTRIBUTION_DIR/export.log"
~~~

-allowProvisioningUpdates permite que Xcode gestione lo necesario para la firma usando la cuenta configurada; puede crear o actualizar perfiles. No modifica el código fuente.

Exigir código de salida 0 y EXPORT SUCCEEDED. Revisar DistributionSummary.plist y el IPA: identificador correcto, equipo, perfil de App Store y get-task-allow=false. En el caso registrado apareció beta-reports-active=true. El IPA es un ZIP firmado; inspeccionarlo no requiere alterar su contenido.

Si falla, conservar el log y corregir el error concreto. No pasar a upload suponiendo que exportó.

## 7. Subir el mismo archivo

Este paso envía la app a Apple. Ejecutarlo cuando la entrega esté autorizada. Conservar exactamente el archivo que se acaba de verificar.

~~~sh
python3 - <<'PY'
import os, plistlib
from pathlib import Path
root = Path(os.environ["VOICEINVIEW_DISTRIBUTION_DIR"])
with (root / "ExportOptions.plist").open("rb") as file:
    options = plistlib.load(file)
options["destination"] = "upload"
options["uploadSymbols"] = True
with (root / "UploadOptions.plist").open("wb") as file:
    plistlib.dump(options, file)
PY

set -o pipefail
"$VOICEINVIEW_XCODEBUILD" -exportArchive \
  -archivePath "$VOICEINVIEW_ARCHIVE" \
  -exportPath "$VOICEINVIEW_DISTRIBUTION_DIR/Upload" \
  -exportOptionsPlist "$VOICEINVIEW_DISTRIBUTION_DIR/UploadOptions.plist" \
  -allowProvisioningUpdates \
  2>&1 | tee "$VOICEINVIEW_DISTRIBUTION_DIR/upload.log"
~~~

La operación vuelve a preparar y firmar para la subida. manageAppVersionAndBuildNumber solicita gestión automática; confirmar el número efectivo en App Store Connect. No asumir que el archivo fuente build=1 ni que Cloud Build 11 determinen por sí solos el número finalmente disponible en TestFlight.

En la ejecución comprobada, la salida final fue:

~~~text
Uploaded package is processing.
Upload succeeded.
Uploaded VoiceInView
** EXPORT SUCCEEDED **
~~~

Si terminó bien, no repetir la subida por no verlo inmediatamente en TestFlight. Revisar primero el procesamiento y cualquier correo de rechazo posterior.

## 8. Terminar en TestFlight

1. Abrir VoiceInView → TestFlight → iOS y localizar el paquete nuevo por versión, número y fecha.
2. Resolver la información pendiente que Apple solicite según la app real. No copiar una declaración de cifrado sin revisar su aplicabilidad.
3. Asignar la compilación al grupo interno Dev si no se añadió automáticamente.
4. Comprobar invitación y acceso del tester.
5. En iPhone, abrir TestFlight y actualizar. Registrar versión/build efectivamente instalados.
6. Probar grabación optativa, corrección, reproducción, subtítulos, pausa/reanudación y orientación. Seguir [la lista de audio y subtítulos](media-and-subtitles.md).

La subida del 10 de octubre quedó confirmada; estos pasos posteriores todavía no tienen confirmación para ese paquete en el registro del proyecto.

## 9. Qué guardar para la siguiente persona

Registrar fecha y zona horaria, commit, número Cloud, Xcode/macOS/SDK, versión/build de App Store Connect, resultado de cada fase y pruebas de dispositivo. Conservar logs y artefactos localmente en build/ o en almacenamiento privado del equipo.

No subir ZIPs de logs, archivos de firma, IPA, xcarchive o datos personales a GitHub. El repositorio contiene el diagnóstico resumido, no credenciales ni registros íntegros de la cuenta.

La ruta /private/tmp usada durante el incidente no es almacenamiento permanente. Esta guía reproduce el procedimiento en build/ para futuras ejecuciones.

## Referencias

- [Distribución mediante archivos y Organizer](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases/).
- [Certificados administrados por Apple](https://developer.apple.com/help/account/certificates/cloud-managed-certificates).
- [Acciones de Xcode Cloud](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions).
- [Requisitos de SDK de Apple](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).
