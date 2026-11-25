# 2026-11-25 — Análisis comparado de la pantalla negra

Base: `7bdf41d02439cc768580ef3abc63e1605807b5b4`.
Se analizaron las tres ejecuciones de la [sesión anterior](2026-11-25-first-boot.md),
en el mismo Ryzen 5 7530U con Radeon integrada y controlador 31.0.21914.18001.
No se ejecutó nuevamente el juego ni se modificó el motor.

## Qué muestran los registros

El arranque alcanza el dispositivo D3D12, abre archivos de recursos y continúa
enviando dibujos y cómputo al host hasta el cierre manual. No hay mensajes de
nivel ERROR, ni avisos de pérdida del dispositivo, falta de memoria o fallo
de creación de la cadena de presentación en estos logs. Esto no descarta
fallos silenciosos ni prueba que el estado interno del juego avance correctamente.

| Dato del registro | Radeon Series S | Radeon Series X | WARP Series S |
| --- | --- | --- | --- |
| Mensajes ERROR / WARN | 0 / 12 | 0 / 8 | 0 / 11 |
| Aperturas registradas por DirectStorage | 60 | 60 | 60 |
| Fallos finales de creación de textura (`no host texture`) | 2 | 0 | 1 |
| Último fotograma informado por el contador periódico | 2048 | 1024 | 1024 |
| Dibujos pedidos / ejecutados desde el informe anterior | 8607 / 8607 | 6656 / 6656 | 5632 / 5632 |
| Despachos pedidos / ejecutados desde el informe anterior | 1024 / 1024 | 512 / 512 | 512 / 512 |

El contador de fotogramas se imprime en potencias de dos: esas cifras no son
el total final. Los avisos tampoco equivalen a cantidad de llamadas fallidas;
varios se emiten una sola vez por clase de evento. Abrir los archivos no
valida todo su contenido. Las aperturas incluyen el contenedor de películas;
la DLL de Bink también se enlaza, pero eso no confirma decodificación de video.

## Interpretaciones corregidas

1. **La DLL del escalador sí se carga.** En ambas pruebas Series S, después
   del aviso de rechazo aparecen su carga dinámica y 7 importaciones HLE,
   79 del host, ninguna faltante. También se comprobó su presencia en la
   carpeta local. En [kernel.rs](../../crates/victory-hle/src/modules/kernel.rs),
   `find_module` comparte el aviso entre consultas de módulos y cargas;
   `GetModuleHandle` lo llama con `load=false`. Es compatible con una consulta
   previa sobre un módulo aún no cargado, aunque el log no identifica la API
   de origen. No corresponde describirlo como una carga definitivamente bloqueada.

2. **El aviso de transición a negro del fotograma 1 no prueba una imagen previa.**
   En [queue.rs](../../crates/victory-gpu/src/queue.rs), `blinks` inicia el estado
   anterior en `false`. Por eso el primer fotograma negro dispara el texto
   «después de uno que no era negro». Los siete niveles iniciales son cero.
   [capture.rs](../../crates/victory-gpu/src/capture.rs) mide una cuadrícula de
   píxeles de la textura fuente; no examina todos los píxeles de la pantalla.

3. **El rechazo de formatos alternativos tiene una ruta de recuperación.**
   [resource.rs](../../crates/victory-gpu/src/resource.rs) intenta
   `CreateCommittedResource` si falla `CreateCommittedResource3`. Solamente
   `no host texture` confirma el fallo posterior. Series X no presenta ese
   segundo fallo y también muestra negro: el formato 67 de Series S no explica
   por sí solo el resultado común.

4. **No hay evidencia de compilación de shaders atascada permanentemente.**
   Series S con Radeon pierde un despacho inicial; posteriormente los
   contadores pedidos/ejecutados coinciden y las métricas muestran cero
   pipelines pendientes. [pipeline.rs](../../crates/victory-gpu/src/pipeline.rs)
   permite que una primera solicitud todavía en preparación devuelva `None`.
   Ejecutar un pipeline no demuestra que la traducción produzca píxeles correctos.

5. **Las 545 vistas de textura nulas son un indicio, no 545 archivos faltantes.**
   [bindless.rs](../../crates/victory-gpu/src/bindless.rs) cuenta posiciones del
   heap sin una vista del host. Las métricas simultáneas redondean a cero los
   dibujos por fotograma que indexan directamente ese heap. Falta identificar
   si los shaders que producen la salida leen esas posiciones; el censo solo
   no permite atribuirles la pantalla negra.

## Qué sigue siendo sospechoso

Los métodos de dispositivo en slots `0x218` y `0x1c8` se invocan en las tres
pruebas antes de la primera presentación y permanecen sin implementar en
[device.rs](../../crates/victory-gpu/src/device.rs). El stub de
[object.rs](../../crates/victory-gpu/src/object.rs) devuelve `E_NOTIMPL` y registra
cada slot solo una vez. El log no muestra cómo responde el juego ni identifica
el contrato de esas llamadas: no se puede concluir que sean el bloqueo.
El slot `0xb8` de la cola aparece durante el cierre manual, por lo que no es
evidencia de la causa inicial del negro.

La hipótesis de trabajo es un problema de compatibilidad en la generación de
la imagen o en el progreso del arranque. Los logs actuales no distinguen
entre un video que nunca empieza y un video/menú que se procesa pero se dibuja
mal. WARP reproduce el síntoma, por lo que la falta de potencia de la Radeon
no es una explicación suficiente. Tampoco aparece un fallo explícito de mesh
shaders en este tramo; la limitación para el mundo 3D es un asunto separado.

La siguiente prueba útil es Series X con la capa de depuración D3D12
(`VICTORY_D3D12_DEBUG=1`) y trazas de dibujos de fotogramas seleccionados
(`VICTORY_CAPTURE_FRAMES`, nivel debug de `victory_gpu`). Permite investigar
los recursos que alimentan la presentación sin mezclar los fallos adicionales
de formato 67 de Series S. Se debe comprobar primero que la capa se active.
Si no identifica el fallo, instrumentar el inicio/avance del decodificador y
las dos llamadas de dispositivo pendientes. Cualquier captura o volcado debe
quedar fuera del repositorio. Esta prueba se propone; no se realizó aquí.

## Trabajo registrado

Se corrigió la interpretación de la DLL en la primera bitácora y se agregó
este análisis al índice. Consultas utilizadas: `Select-String` sobre los tres
logs, conteos con PowerShell y `rg -n` sobre los emisores de los mensajes.
Se revisaron las rutas de carga, creación de texturas, despacho, presentación
y diagnóstico del código local. Validación: enlaces locales, `git diff --check`
y `cargo xtask policy`. No se repitieron pruebas unitarias por tratarse de
documentación. No hay una corrección del renderizado aplicada ni causa única
confirmada en esta sesión.
