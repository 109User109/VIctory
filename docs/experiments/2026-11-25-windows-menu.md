# 2026-11-25 — Preparación para video inicial y menús

Sesión iniciada el 24 de noviembre y completada el 25, hora de Argentina.
Revisión base: `940d32f69b22265690a0b5a15d6ded572ba33baf` de Marvisak/VIctory.

## Equipo y herramientas

| Elemento | Valor observado |
| --- | --- |
| CPU | AMD Ryzen 5 7530U, 6 núcleos / 12 hilos, x64 |
| RAM utilizable | 31,3 GiB |
| GPU | AMD Radeon integrada |
| Controlador | 31.0.21914.18001 |
| Sistema | Windows 11 IoT Enterprise LTSC, 10.0.26100 |
| Consulta Direct3D | Shader Model 6.6 disponible; MeshShaderTier = 0 |
| Rust | 1.98.1, x86_64-pc-windows-msvc |
| Compilación | Visual Studio 2026 C++, Windows SDK 10.0.26100.0 |
| DXIL del SDK | 1.9.2602.17 |

Se descargó el código y se instalaron Rust, sus componentes fijados por el
repositorio y las herramientas C++/SDK de Microsoft. El instalador de Visual
Studio terminó con código 3010, que solicita reinicio. Esta sesión no confirmó
un reinicio posterior.

## Resultado

- `cargo build --profile diag -p victory --features diagnostics --locked`:
  compilación correcta.
- Ejecutable `--version`, ayuda de `run` y configuración: correctos.
- Lanzador local en Windows PowerShell: comprobación `-CheckOnly` correcta.
- Suite del proyecto: **no pasó completa**. Un fallo en `victory-gpu` y seis en
  `victory-shader` sobre esta máquina.
- El fallo de `victory-gpu` se reprodujo de forma aislada, con un solo hilo.
- No se ejecutó el juego: faltaban sus archivos. No hay resultado de video,
  menús, audio, rendimiento ni carga de la escena 3D en este equipo.

Primera ejecución de pruebas:

```powershell
cargo test --workspace --profile diag --features victory/diagnostics --locked
```

La primera ejecución se detuvo en `victory-gpu`. Se completaron los paquetes
restantes con el validador DXIL del SDK instalado:

```powershell
cargo test -p victory-hle -p victory-loader -p victory-pe -p victory-pipeline -p victory-shader -p xtask --profile diag --all-features --locked --no-fail-fast
```

## Fallos observados

En `victory-gpu`:

- `draw::tests::a_texture_written_in_one_format_reads_in_another_through_a_placed_view`

En `victory-shader`:

- `emit::stride_tests::a_heap_buffer_read_by_element_takes_the_views_stride`
- `emit::synthetic_tests::gathers_at_a_level_match_the_hardware`
- `emit::synthetic_tests::permutes_read_the_lane_named_and_zero_from_lanes_left_out`
- `emit::valu_tests::image_atomics_of_64_bits`
- `emit::valu_tests::fspx_programs_run_with_the_hardwares_dot_products`
- `emit::waterfall_tests::lanes_load_from_the_buffer_their_nested_arms_chose`

No se determinó si los fallos son del traductor, del controlador o de una
suposición de las pruebas. Tampoco se determinó si afectan al video o los menús.
No se modificó código del motor para ocultar estos resultados.

## Preparación y próximos pasos

Se agregaron scripts portables para compilar e iniciar el perfil Series S con
diagnósticos, guardar transcripciones y mantener los datos fuera del repositorio.
La ventana se limita a 1280×720; esto no cambia la resolución interna.
El lanzador no pulsa botones ni bloquea el acceso al modo historia.

Queda pendiente reiniciar Windows, comprobar la versión y el conjunto de archivos
del juego y probar video y menús. La ruta actual de renderizado del mundo requiere
mesh shaders, que esta GPU no expone. No se promete funcionamiento de la escena 3D.

SHA256 del ejecutable local compilado durante la preparación (no distribuido):
`128364546DAE4F156600B8075A358495494FD33D041B2B279F0153C9E8F17384`.

## Registro en el fork

Se creó el fork `109User109/VIctory` y la rama `codex/windows-menu-setup` a
partir de la revisión probada. `upstream` conserva el repositorio original y
`origin` apunta al fork. Se migraron los scripts al repositorio y los accesos
locales delegan en esas copias versionadas. Se comprobó su sintaxis y la
ejecución `-CheckOnly` con Windows PowerShell después de la migración.

Se añadió `AGENTS.md` para mantener esta bitácora y la atribución a Codex en
sesiones futuras. No se repitieron las pruebas del motor por este cambio de
scripts y documentación; los siete fallos anteriores siguen abiertos.
