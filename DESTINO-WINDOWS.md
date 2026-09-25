# Destino en Windows

## Ruta del proyecto
```
C:\Users\CriptoAprendices\Desktop\Proyecto Ing Software Avanzado\
```

Archivo a importar en Godot:
```
C:\Users\CriptoAprendices\Desktop\Proyecto Ing Software Avanzado\GodotF126\project.godot
```

## Godot sugerido
```
C:\Godot\Godot_v4.3-stable_win64.exe
```
Versión **4.3-stable, Standard** (sin .NET). Es un ejecutable portable: no se instala.

## Qué genera Godot al abrir el proyecto
- `GodotF126\.godot\` — caché de importación. Se puede borrar sin perder nada; está en `.gitignore`.
- Archivos `*.import` junto a los recursos (por ejemplo `icon.svg.import`). Son normales.

## Datos de usuario (a partir del Paso 4, telemetría)
Godot guarda `user://` en:
```
%APPDATA%\Godot\app_userdata\GodotF126\
```

## Ejecutable (Paso 8, todavía no existe)
Cuando se haga el export, la salida prevista es:
```
C:\Users\CriptoAprendices\Desktop\Proyecto Ing Software Avanzado\GodotF126\export\GodotF126.exe
```
Requiere instalar los *Export Templates* de Godot 4.3 y agregar `*.json` a los filtros de recursos no-Godot.

## Entrega al profesor
- `PARA-EL-PROFESOR-GodotF126-abstract.md` → abrir en Word (o pegar el contenido) → *Archivo → Guardar como → PDF*.
- `informes\GodotF126-Agustin-Gimenez-formalizacion.md` → mismo procedimiento.
