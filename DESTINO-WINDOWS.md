# Destino en Windows

## Ruta del proyecto
La carpeta del repositorio puede estar en cualquier lado. En la PC actual:
```
C:\Users\btc\Desktop\GodotF126\
```

Archivo a importar en Godot:
```
C:\Users\btc\Desktop\GodotF126\GodotF126\project.godot
```

## Godot sugerido
```
C:\Godot\Godot_v4.7.2-stable_win64.exe
```
(En la PC actual está en `C:\Users\btc\Desktop\Godot_v4.7.2-stable_win64.exe`.)
Versión **4.7.x stable, Standard** (sin .NET). Es un ejecutable portable: no se instala, pero hay que **descomprimirlo**; no abrirlo directo desde el `.zip`, porque WinRAR lo corre desde una carpeta temporal que se borra.

## Qué genera Godot al abrir el proyecto
- `GodotF126\.godot\` — caché de importación. Se puede borrar sin perder nada; está en `.gitignore`.
- Archivos `*.import` junto a los recursos (por ejemplo `icon.svg.import`) y `*.uid` junto a los scripts. Son normales y conviene commitearlos.

## Datos de usuario
Godot guarda `user://` (récords de vuelta, y más adelante telemetría) en:
```
%APPDATA%\Godot\app_userdata\GodotF126\
```

## Ejecutable (Paso 59)
```
C:\Users\btc\Desktop\GodotF126\GodotF126\export\GodotF126.exe
```
Un solo archivo (~105 MB) con los datos adentro: se puede copiar a cualquier carpeta, pendrive u otra PC con Windows 10/11 de 64 bits y OpenGL 3.3, sin instalar Godot. No está en git (`export/` en `.gitignore`).

Para regenerarlo hacen falta las *Export Templates* de Godot **4.7.2** (misma versión exacta que el editor). En esta PC están en `%APPDATA%\Godot\export_templates\4.7.2.stable\` (sólo Windows x86_64); en otra, desde el editor: *Editor → Administrar plantillas de export → Descargar e instalar*. Después, en la carpeta del repositorio:
```
Godot_v4.7.2-stable_win64.exe --headless --path GodotF126 --export-release "Windows Desktop" export/GodotF126.exe
```
El preset (`GodotF126\export_presets.cfg`) ya incluye los `*.json` de `data/` y deja afuera `addons/gut/`, `test/` y `.gutconfig.json`.

Prueba de rendimiento con el ejecutable (sin Godot): `GodotF126.exe -- --benchmark` (agregar `--quit` después de `--benchmark` para que se cierre sola). El informe queda en `%APPDATA%\Godot\app_userdata\GodotF126\benchmark.txt`. El `.exe` usa esa misma carpeta para récords, ajustes y campeonato.

## Entrega al profesor
- `PARA-EL-PROFESOR-GodotF126-abstract.md` → abrir en Word (o pegar el contenido) → *Archivo → Guardar como → PDF*.
- `informes\GodotF126-Agustin-Gimenez-formalizacion.md` → mismo procedimiento.
