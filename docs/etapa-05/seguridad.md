# Seguridad de la base de datos

**Proyecto:** Aura Store — Sistema de gestión para un comercio de indumentaria deportiva  
**Etapa V:** Lógica de negocio técnica

## 1. Objetivo

Se configuraron permisos para el rol `rol_consulta_productos`, con el objetivo de permitir la consulta de productos y ligas sin habilitar modificaciones sobre esas tablas.

## 2. Permisos del rol

El rol `rol_consulta_productos` ya existía en la base de datos y tenía asignado al usuario `usuario_con_rol`. Se verificaron los permisos de lectura sobre:

- `dbo.producto`
- `dbo.liga`

El archivo `sql/tecnico/seguridad/gestion_permisos.sql` otorga esos permisos y permite consultar la configuración del rol y sus miembros.

## 3. Pruebas y validación

Las pruebas se realizaron en SQL Server, sobre la base de datos `aura_store`, usando el contexto del usuario `usuario_con_rol`.

El archivo `sql/tecnico/seguridad/pruebas_seguridad.sql` comprueba los permisos del usuario y realiza consultas sobre las tablas.

| Operación | `dbo.producto` | `dbo.liga` |
|---|---|---|
| SELECT | Permitido | Permitido |
| INSERT | No permitido | No permitido |
| UPDATE | No permitido | No permitido |
| DELETE | No permitido | No permitido |

Las consultas de prueba devolvieron los siguientes resultados: `SELECT` permitido (`1`), e `INSERT`, `UPDATE` y `DELETE` no permitidos (`0`). No se modificaron filas durante las pruebas.

## 4. Archivos

- `sql/tecnico/seguridad/gestion_permisos.sql`: configuración de permisos.
- `sql/tecnico/seguridad/pruebas_seguridad.sql`: pruebas de permisos.

## 5. Conclusión

Las pruebas realizadas comprobaron que el usuario `usuario_con_rol` puede consultar las tablas `producto` y `liga`, pero no cuenta con permisos para insertar, actualizar ni eliminar registros en ellas.