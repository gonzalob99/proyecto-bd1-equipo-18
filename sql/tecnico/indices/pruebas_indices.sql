-- =============================================================
-- Aura Store - Comparacion de consultas con y sin indice por fecha
-- Etapa V - Optimizacion de consultas
-- =============================================================
-- Ejecutar TODO el archivo en una misma conexion de SQL Server.
-- En SSMS, activar "Incluir plan de ejecucion real" (Ctrl + M).
-- Las lecturas y tiempos aparecen en la pestana Mensajes.
--
-- Se generan 1.100.000 compras SIMULADAS en una tabla temporal.
-- No se insertan compras reales ni se ejecutan triggers del negocio.
-- El script no depende de haber ejecutado crear_indices.sql.
--
-- Adaptacion de la guia: se conserva una PK agrupada por id_compra,
-- como en el DDL del proyecto. Los indices por fecha son NO agrupados,
-- ya que una tabla solo puede tener un indice agrupado.
-- =============================================================

USE aura_store;
GO

SET NOCOUNT ON;

-- Permite repetir la demostracion en la misma conexion.
IF OBJECT_ID(N'tempdb..#compra_prueba_indices', N'U') IS NOT NULL
    DROP TABLE #compra_prueba_indices;

CREATE TABLE #compra_prueba_indices (
    id_compra INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
    id_cliente INT NOT NULL,
    id_metodo INT NOT NULL,
    fecha DATETIME NOT NULL
);

-- La copia conserva las columnas y tipos de compra.
-- No lleva FK: los identificadores son simulados y no necesitan
-- corresponder a clientes o medios de pago cargados en aura_store.
-- Se usan combinaciones de digitos para no depender de cuantas
-- filas tenga sys.objects en la instancia donde se haga la prueba.
;WITH Digitos AS (
    SELECT n
    FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS d(n)
),
Numeros AS (
    SELECT TOP (1100000)
        CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT) AS n
    FROM Digitos a
    CROSS JOIN Digitos b
    CROSS JOIN Digitos c
    CROSS JOIN Digitos d
    CROSS JOIN Digitos e
    CROSS JOIN Digitos f
    CROSS JOIN (VALUES (0),(1)) AS g(n)
)
INSERT INTO #compra_prueba_indices (id_cliente, id_metodo, fecha)
SELECT
    (n % 11) + 1,
    (n % 8) + 1,
    DATEADD(SECOND, n % 86400,
        DATEADD(DAY, n % 1825, CAST('20200101' AS DATETIME)))
FROM Numeros;

-- Se consulta un solo dia de un historial de cinco anos aprox.
-- Un rango pequeno permite apreciar el acceso por indice.
-- El limite superior exclusivo incluye todas las horas del dia.
DECLARE @fecha_desde DATETIME = '20230101';
DECLARE @fecha_hasta_exclusiva DATETIME = '20230102';
DECLARE @repeticion INT;

-- Datos de control. Con estos parametros deben ser 1.100.000 y 603.
SELECT
    COUNT(*) AS compras_simuladas,
    SUM(CASE
        WHEN fecha >= @fecha_desde AND fecha < @fecha_hasta_exclusiva
        THEN 1 ELSE 0
    END) AS compras_del_periodo
FROM #compra_prueba_indices;

-- Se actualizan las estadisticas antes de comparar los escenarios.
UPDATE STATISTICS #compra_prueba_indices WITH FULLSCAN;

-- =============================================================
-- A. SIN INDICE POR FECHA
-- Existe la PK agrupada por id_compra, pero no ayuda a buscar fechas.
-- Plan esperable: Clustered Index Scan.
-- =============================================================
PRINT 'A. Sin indice por fecha';
SET @repeticion = 1;

WHILE @repeticion <= 3
BEGIN
    PRINT 'Repeticion ' + CAST(@repeticion AS VARCHAR(1));
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;

    SELECT id_compra, fecha, id_cliente, id_metodo
    FROM #compra_prueba_indices
    WHERE fecha >= @fecha_desde
      AND fecha < @fecha_hasta_exclusiva
    OPTION (RECOMPILE);

    SET STATISTICS TIME OFF;
    SET STATISTICS IO OFF;
    SET @repeticion = @repeticion + 1;
END;

-- =============================================================
-- B. INDICE SIMPLE POR FECHA
-- Permite buscar el rango, pero no contiene id_cliente ni id_metodo.
-- Plan esperable: Index Seek + Key Lookup.
-- El optimizador tambien puede elegir un Scan si lo estima mas barato.
-- =============================================================
CREATE NONCLUSTERED INDEX IX_compra_prueba_fecha
ON #compra_prueba_indices (fecha);

PRINT 'B. Indice simple por fecha';
SET @repeticion = 1;

WHILE @repeticion <= 3
BEGIN
    PRINT 'Repeticion ' + CAST(@repeticion AS VARCHAR(1));
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;

    SELECT id_compra, fecha, id_cliente, id_metodo
    FROM #compra_prueba_indices
    WHERE fecha >= @fecha_desde
      AND fecha < @fecha_hasta_exclusiva
    OPTION (RECOMPILE);

    SET STATISTICS TIME OFF;
    SET STATISTICS IO OFF;
    SET @repeticion = @repeticion + 1;
END;

-- Se elimina solo el indice experimental de la tabla temporal.
DROP INDEX IX_compra_prueba_fecha ON #compra_prueba_indices;

-- =============================================================
-- C. INDICE CON COBERTURA
-- Misma definicion que el indice propuesto para dbo.compra.
-- Contiene fecha, id_cliente, id_metodo e id_compra (clave agrupada).
-- Plan esperable: Index Seek sin Key Lookup.
-- =============================================================
CREATE NONCLUSTERED INDEX IX_compra_prueba_fecha_cobertura
ON #compra_prueba_indices (fecha)
INCLUDE (id_cliente, id_metodo);

PRINT 'C. Indice por fecha con cobertura';
SET @repeticion = 1;

WHILE @repeticion <= 3
BEGIN
    PRINT 'Repeticion ' + CAST(@repeticion AS VARCHAR(1));
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;

    SELECT id_compra, fecha, id_cliente, id_metodo
    FROM #compra_prueba_indices
    WHERE fecha >= @fecha_desde
      AND fecha < @fecha_hasta_exclusiva
    OPTION (RECOMPILE);

    SET STATISTICS TIME OFF;
    SET STATISTICS IO OFF;
    SET @repeticion = @repeticion + 1;
END;

-- Se comparan las MISMAS filas y columnas en A, B y C.
-- Los indices no cambian los datos; el orden puede variar porque
-- no se utiliza ORDER BY. Cada SELECT debe devolver 603 compras.
-- OPTION (RECOMPILE) genera un plan nuevo para los parametros e
-- indices de cada escenario, sin vaciar la cache de la instancia.

DROP TABLE #compra_prueba_indices;
PRINT 'Fin de la demostracion. Se elimino la tabla temporal.';
