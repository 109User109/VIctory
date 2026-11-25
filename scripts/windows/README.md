# Preparación en Windows

Estos scripts requieren las herramientas descritas en el README principal:
Rust fijado por `rust-toolchain.toml`, herramientas C++ de Visual Studio y SDK
de Windows. No instalan herramientas ni descargan archivos del juego.

Desde la raíz del repositorio:

```powershell
.\scripts\windows\Compilar-VIctory.ps1
.\scripts\windows\Iniciar-VIctory.ps1 -CheckOnly
.\scripts\windows\Iniciar-VIctory.ps1 -GameExe 'D:\Mi juego\juego.exe'
```

También se puede abrir `Iniciar-VIctory.cmd` en esta carpeta. Pedirá la ruta del
ejecutable del juego y la recordará para la próxima sesión. `-GameExe` permite
cambiarla. El ejecutable debe estar junto a sus recursos completos y fuera del
repositorio.

Los datos se guardan en una carpeta hermana llamada `<nombre-del-repo>-datos`:

- `juego`: ubicación opcional para los archivos aportados por el usuario.
- `cache`: archivos derivados por VIctory.
- `partidas`: guardados y registros propios del port.
- `logs`: transcripciones del lanzador.
- `launcher.toml`: configuración local mínima; las rutas se fijan por entorno.
- `ejecutable.txt`: ruta recordada, que se puede borrar para volver a elegir.

El lanzador usa `target\diag\victory.exe`, perfil Series S y una ventana de
hasta 1280×720. Ese límite no cambia la resolución interna. La primera ejecución
puede hacer pausas mientras traduce shaders. `-CheckOnly` verifica que la herramienta
arranque y lea la configuración; no comprueba el juego ni valida los gráficos.

Para esta prueba, quedarse en el video inicial y los menús. El lanzador no impide
seleccionar modo historia. Enter equivale a A, Backspace a B, las flechas a la
cruceta y Esc a Menu; también se admite un mando XInput.

`-Software` activa WARP para diagnósticos, con un rendimiento muy bajo. La
[bitácora](../../docs/experiments/README.md) registra los fallos conocidos y las
pruebas realizadas.
