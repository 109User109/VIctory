# 2026-11-25 — Verificación y primeras pruebas de arranque

Revisión base del fork: `a44b54ec382d5db0d65fc4e4605a2c05b6018e59`.
Motor compilado desde `940d32f69b22265690a0b5a15d6ded572ba33baf`, perfil
`diag`, característica `diagnostics`. No se modificó el motor en esta sesión.

Equipo: Ryzen 5 7530U, Radeon integrada, 31,3 GiB de RAM, Windows 11 x64
26100; controlador AMD `31.0.21914.18001`. El reinicio solicitado durante
la instalación de herramientas continúa pendiente.

## Identidad comprobada antes de ejecutar

Se extrajo el ejecutable del archivo local aportado por el usuario, fuera del
repositorio. Antes de ejecutarlo, se compararon dos hashes independientes:

| Identificador | Valor calculado |
| --- | --- |
| SHA-256 del ejecutable | `e95020b2fa4a721db3df59fdecf75621730ac559d8835252f6c3b658d5a08993` |
| BLAKE3 del ejecutable | `b99f876b74d4a77f03af5f878223b27bd647b5c35a79d5decd9f716504239e93` |

El SHA-256 coincide con la [evidencia publicada por TuxBox](https://github.com/brcly/TuxBox/blob/main/evidence/projectscarlett-startup.json),
consultada el 25 de noviembre de 2026. El BLAKE3 coincide con
[`KNOWN_BUILDS` en la revisión de VIctory utilizada](https://github.com/Marvisak/VIctory/blob/940d32f69b22265690a0b5a15d6ded572ba33baf/crates/victory-game/src/lib.rs),
que lo identifica como Series 1.0.2.1. El ejecutable mide 120.181.760 bytes.
La copia colocada junto a los recursos también se verificó antes del arranque.

Estas referencias proceden de los proyectos comunitarios. No se encontró una
referencia de Rockstar: la coincidencia identifica el archivo utilizado por
esos proyectos, sin certificar su seguridad. La configuración del paquete
declara 1.0.2.1, pero no se verificó la integridad completa de todos los recursos.

## Ejecución real

Se utilizó la misma compilación, recursos, caché y directorio de guardados en
las tres pruebas, en orden. No es una comparación de rendimiento con caché fría.
La ventana estuvo limitada a 1280×720; la resolución interna no se redujo con
ese ajuste. Se inspeccionó visualmente cada ventana y se cerró con Alt+F4.

| Prueba | Intervalo UTC aproximado | Observación |
| --- | --- | --- |
| Radeon, Series S | 10:53:38–10:55:12; 94 s | Negro, alrededor de 30 FPS; hasta 11 llamadas de dibujo por fotograma |
| Radeon, Series X | 10:55:17–10:56:08; 51 s | Negro, aproximadamente 20–30 FPS; hasta 13 llamadas de dibujo por fotograma |
| WARP por software, Series S | 10:56:14–10:59:14; 180 s | Negro; 8–10 FPS en observaciones posteriores, 11 llamadas de dibujo por fotograma |

En Series S con Radeon se probó Enter una vez sin un cambio visible.
Los tres procesos terminaron con código 0 después del cierre manual.
Ese código indica el cierre, no que el objetivo de video y menús se haya cumplido.
No se observaron el video ni los menús; no se comprobó reproducción audible.
Los contadores de FPS describen presentaciones de fotogramas, incluso negros.

Comandos reproducibles, sustituyendo la ruta ilustrativa por los archivos locales:

```powershell
$game = 'D:\Mi juego\game_scarlett_master.exe'
Get-FileHash -LiteralPath $game -Algorithm SHA256
.\target\diag\victory.exe inspect $game
.\scripts\windows\Iniciar-VIctory.ps1 -GameExe $game
.\scripts\windows\Iniciar-VIctory.ps1 -GameExe $game -Software
```

La comparación Series X se ejecutó directamente con el entorno equivalente
al lanzador (`VICTORY_CONFIG`, `VICTORY_CACHE_DIR`, `VICTORY_DATA_DIR`,
`VICTORY_GAME_DIR`, `VICTORY_WINDOW_MAX=1280x720`, `VICTORY_LOG=info`,
`VICTORY_D3D12_WARP=0`):

```powershell
.\target\diag\victory.exe run $game --execute --console series-x
```

## Indicios y límites del diagnóstico

- VIctory reconoce la versión. El enlace estático del ejecutable informa
  91 importaciones HLE, 424 del host, 72 del título y ninguna faltante.
  Esto no garantiza que todas las funciones estén implementadas.
- Aparecen rechazos de formatos alternativos de textura. El código dispone
  de una ruta alternativa para ese rechazo; el aviso por sí solo no prueba
  la causa del negro.
- En Series S, tanto Radeon como WARP rechazan además la creación de una
  textura 1920×1080, formato 67, flags 5, con `0x80070057`.
- Se registran vistas sin recurso y métodos de dispositivo sin implementar.
  También aparece un aviso de rechazo para la biblioteca del escalador,
  seguido de su carga y enlace correctos. La revisión posterior del
  [análisis de logs](2026-11-25-log-analysis.md) corrige la interpretación
  inicial: el aviso no demuestra que la carga dinámica haya fallado.
- WARP fue confirmado por el registro del adaptador. Al cambiar de adaptador
  se recreó una biblioteca de pipelines incompatible con el anterior.
  El negro también por software impide atribuirlo exclusivamente a la Radeon.

No se cambiaron controladores, políticas de seguridad ni archivos de recursos.
Los registros crudos, la comprobación de hashes y las cachés permanecen fuera
del repositorio, en la carpeta de datos hermana.

## Cambios versionados y siguiente prueba

Se actualizó la portada y el índice de la bitácora con estos resultados.
Validación documental: `git diff --check` y `cargo xtask policy`; no se
repitieron las pruebas unitarias del motor porque no cambió su código.

Queda pendiente completar el reinicio y aislar un fallo concreto de creación
de recursos o de la capa de compatibilidad, aplicar una corrección y repetir
la comprobación visual. El objetivo de video con audio y menús sigue pendiente.
