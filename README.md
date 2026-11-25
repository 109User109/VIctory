# VIctory — video inicial y menús en Windows

Este fork reúne nuestras pruebas para intentar abrir **el video de introducción y los menús de GTA VI** en una notebook con Windows y gráficos integrados. Usamos como base [VIctory, de Marvisak](https://github.com/Marvisak/VIctory), y registramos la preparación, los cambios y los resultados para poder continuar desde una revisión conocida.

**Estado al 25 de noviembre de 2026:** verificamos la identidad del ejecutable y realizamos las primeras pruebas reales. VIctory reconoce la versión y abre una ventana, pero los perfiles Series S y Series X con la Radeon, y Series S por software, muestran una pantalla negra. **Todavía no logramos reproducir el video ni mostrar los menús.**

## A qué apuntamos

El primer objetivo es llegar al arranque del juego, reproducir su video inicial con audio y navegar sus pantallas de configuración y menús. Queremos identificar qué funciona, dónde falla y qué necesita corregirse, dejando evidencia de cada prueba.

La primera escena renderizada en 3D requiere funciones gráficas distintas de las del video. La GPU de este equipo no expone mesh shaders, que la ruta actual de VIctory necesita para dibujar el mundo. Por ahora no prometemos cargar esa escena ni jugar la historia.

## Qué tenemos preparado

- Código de VIctory descargado y compilado con optimizaciones y diagnósticos.
- Rust 1.98.1, herramientas C++ de Visual Studio y SDK de Windows instalados en el equipo de prueba.
- [Script de compilación](scripts/windows/Compilar-VIctory.ps1) para reconstruir la revisión local.
- [Lanzador para Windows](scripts/windows/Iniciar-VIctory.cmd), que solicita la ruta del ejecutable del juego y la recuerda.
- Perfil Series S, registros de sesión y carpetas separadas para caché y guardados.
- [Bitácora de experimentos](docs/experiments/README.md) con las pruebas y limitaciones conocidas.

Los ejecutables compilados, las herramientas instaladas y los archivos del juego no se distribuyen en este repositorio. Cada equipo necesita su propia preparación y sus archivos.

## Equipo de prueba

| Componente | Configuración |
| --- | --- |
| Procesador | AMD Ryzen 5 7530U, 6 núcleos y 12 hilos |
| Memoria | Aproximadamente 32 GB de RAM; 31,3 GiB utilizables |
| Gráficos | AMD Radeon integrada |
| Sistema | Windows 11 IoT Enterprise LTSC, x64 |
| Almacenamiento | SSD NVMe |
| Funciones gráficas consultadas | Shader Model 6.6 disponible; mesh shaders no disponibles |

Estos datos describen nuestro equipo de prueba; no son requisitos oficiales ni una garantía de compatibilidad.

## Qué comprobamos y qué falta

| Comprobación | Resultado |
| --- | --- |
| Compilación de VIctory | Correcta |
| Arranque de la herramienta y lectura de configuración | Correctos |
| Lanzador con `-CheckOnly` | Correcto |
| Pruebas automáticas del proyecto | Siete fallos gráficos: uno en `victory-gpu` y seis en `victory-shader` |
| Identidad del ejecutable | SHA-256 coincide con la referencia de TuxBox; BLAKE3 coincide con la versión reconocida por VIctory |
| Arranque real: Radeon Series S / Series X y software Series S | Ventana abierta; pantalla negra en las tres pruebas |
| Video inicial y menús del juego | No visibles en las pruebas; audio no comprobado |
| Primera escena 3D | No probada; existe la limitación de mesh shaders |

Los fallos están detallados en la [sesión de preparación](docs/experiments/2026-11-25-windows-menu.md). Todavía no determinamos si provienen del traductor, del controlador o de supuestos de las pruebas, ni si afectan al video y los menús.

La [sesión de primer arranque](docs/experiments/2026-11-25-first-boot.md) registra las referencias de hashes, los comandos y el resultado de cada perfil. Son referencias de los proyectos comunitarios, no una certificación de Rockstar ni una validación integral de los recursos. Los contadores de fotogramas y llamadas de dibujo avanzan, pero no demuestran que se esté reproduciendo el video.

El instalador de Microsoft solicitó reiniciar Windows al finalizar. La sesión de preparación no confirmó ese reinicio.

## Cómo preparar una prueba

Se necesita Windows x64, el Rust fijado por `rust-toolchain.toml`, las herramientas de desarrollo de escritorio con C++ de Visual Studio y el SDK de Windows. VIctory pide una CPU con AVX2 y una GPU Direct3D 12 con Shader Model 6.6; para el mundo 3D también requiere mesh shaders.

Desde la raíz del repositorio, en PowerShell:

```powershell
.\scripts\windows\Compilar-VIctory.ps1
.\scripts\windows\Iniciar-VIctory.ps1 -CheckOnly
```

Cuando estén disponibles el ejecutable del juego y todos sus recursos de la misma versión, abrir `scripts\windows\Iniciar-VIctory.cmd` y pegar la ruta del ejecutable. También se puede indicar directamente:

```powershell
.\scripts\windows\Iniciar-VIctory.ps1 -GameExe 'D:\Mi juego\juego.exe'
```

`-CheckOnly` comprueba la herramienta y su configuración; no ejecuta el juego ni valida sus gráficos. El lanzador no bloquea el acceso al modo historia: para esta primera prueba, quedarse en el video inicial y los menús.

La ventana se limita a 1280×720, pero **eso no cambia la resolución interna**. La primera ejecución puede tener pausas mientras se traducen shaders. Los archivos del juego, las cachés, los registros crudos y los guardados deben permanecer fuera del repositorio. El lanzador crea una carpeta hermana llamada `<nombre-del-repo>-datos`.

Más detalles y controles en la [guía de los scripts](scripts/windows/README.md).

## Próximos pasos

1. Completar el reinicio pendiente antes de una nueva comparación del entorno.
2. Investigar la pantalla negra: creación de texturas, vistas sin recurso y funciones de la capa de compatibilidad todavía sin implementar.
3. Probar una corrección concreta y comprobar visualmente el video y los menús; verificar el audio por separado.
4. Versionar cada avance junto con sus resultados, manteniendo los archivos del juego fuera del repositorio.

## Cómo registramos el trabajo

La [bitácora](docs/experiments/README.md) conserva la revisión base, el entorno, los comandos relevantes, los resultados y lo pendiente. Los cambios se guardan en commits; las instrucciones para futuras sesiones están en [AGENTS.md](AGENTS.md).

Este trabajo se realiza con asistencia de **OpenAI Codex**, atribuida en los commits mediante `Assisted-by: OpenAI Codex`.

## Proyecto original y licencia

El cargador, la capa de compatibilidad, el renderizado y el traductor de shaders provienen del trabajo de [Marvisak/VIctory y sus colaboradores](https://github.com/Marvisak/VIctory). Nuestra aportación inicial es la preparación del entorno, los scripts y el registro de pruebas en este equipo.

Se conserva la [licencia GPL-3.0-or-later](LICENSE) del proyecto. La excepción de las tablas BCPack y las reglas sobre el contenido permitido están documentadas en la [política de archivos](docs/asset-policy.md).
