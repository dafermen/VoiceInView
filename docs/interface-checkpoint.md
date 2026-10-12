# Punto de reanudación — build 21

Base: a5e9937, main. Mejoras autorizadas: avisos iniciales/modelos más visibles, audio inicial activado sin sobrescribir preferencias anteriores, renglones alineados al texto y menús en inglés/español independientes de la captura.

Implementación local terminada. Release iPhone/iPad y 92 pruebas unitarias aprobadas. Cuatro recorridos UI de iPhone aprobados en tandas dirigidas, incluida la preparación con aviso completo. En iPad ya pasó lectura/renglones/giro/reanudar; siguen idioma/preparación. Se está repitiendo Release tras el último ajuste de altura del aviso. Publicación y Cloud pendientes. No confundir la aprobación Cloud de build 20 con esta entrega. Identidad com.dafermen.vReader, esquema V7 y mínimo iOS 17 sin cambios.

Código: AppSettings/InterfaceLanguage; AppRootView propaga locale y aplica valor inicial antes de abrir el almacén; ReaderParagraph/TextKit mide y dibuja guías; CaptionScreen prepara permisos; catálogos en Resources. Pruebas AppSettingsTests, CaptionViewModelTests y HomeScreenTests. Revisar especialmente interpolaciones de localización y geometría con descendentes.

Evidencia: /private/tmp/build21-release.log (BUILD SUCCEEDED, fuente 21, UIDeviceFamily [1,2]); /private/tmp/build21-verified.log y VoiceInView-21-Verified.xcresult (92 pruebas, cero fallos, TEST SUCCEEDED). Pruebas de interfaz: build21-ui.log / VoiceInView-21-UI.xcresult. Después de validar, actualizar este archivo y validation-report, commit/push y verificar el Archive del SHA publicado. Si se interrumpe la conversación, empezar por git status y este punto, sin reinstalar el iPhone ni borrar sesiones.

Guía: [interfaz y preparación](interface-and-onboarding.md). Build 20: [checkpoint anterior](accessibility-checkpoint.md). Incidentes anteriores de firma y simulador: [registro](build-incidents.md).


## Evidencia UI

- `build21-ui.log`: lectura con renglones/interrupción/giro 50,356 s e idiomas independientes durante pausa 27,804 s aprobados. Dos fallos de selectores corregidos; esa tanda global no pasó completa.
- `build21-ui-verified.log` / `VoiceInView-21-UI-Verified.xcresult`: preparación inicial 13,391 s y práctica de sesión española 33,348 s, TEST SUCCEEDED.
- `build21-preparation-final.log` / `VoiceInView-21-Preparation-Final.xcresult`: aviso sin truncamiento en iPhone pequeño, 14,821 s, TEST SUCCEEDED. Este fue el último ajuste de presentación; no modifica modelos, permisos ni persistencia.
- Capturas de ajustes españoles, preparación completa y renglones en vertical/horizontal revisadas en `/private/tmp/screens21`.
- iPad: `build21-ipad.log`, lectura/renglones/giro/reanudar pasó en 71,486 s. Otros recorridos todavía en ejecución.
