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
Versión **4.7.x stable, Standard** (sin .NET). Es un ejecutable portable: no se instala.

## Qué genera Godot al abrir el proyecto
- `GodotF126\.godot\` — caché de importación. Se puede borrar sin perder nada; está en `.gitignore`.
- Archivos `*.import` junto a los recursos (por ejemplo `icon.svg.import`) y `*.uid` junto a los scripts. Son normales y conviene commitearlos.

## Datos de usuario
Godot guarda `user://` (récords de vuelta, y más adelante telemetría) en:
```
%APPDATA%\Godot\app_userdata\GodotF126\
```

## Ejecutable (Paso 59, todavía no existe)
Cuando se haga el export, la salida prevista es:
```
C:\Users\btc\Desktop\GodotF126\GodotF126\export\GodotF126.exe
```
Requiere instalar los *Export Templates* de Godot 4.7 (misma versión exacta que el editor) y agregar `*.json` a los filtros de recursos no-Godot.

## Entrega al profesor
- `PARA-EL-PROFESOR-GodotF126-abstract.md` → abrir en Word (o pegar el contenido) → *Archivo → Guardar como → PDF*.
- `informes\GodotF126-Agustin-Gimenez-formalizacion.md` → mismo procedimiento.
