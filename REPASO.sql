USE HiperAlmacen
GO

SELECT * FROM Categorias
SELECT * FROM Productos --Id Categoria
SELECT * FROM Clientes
SELECT * FROM Facturas --Identificacion (Clientes)
SELECT * FROM DetalleFactura --Id Factura, Id Productos

-- 1) JOINS =================================================================================
-- 1. INNER JOIN 
SELECT C.IdCategoria, C.NombreCat, P.NombrePro, P.Precio
FROM Categorias AS C INNER JOIN Productos AS P ON C.IdCategoria = P.IdCategoria

-- 2. LEFT JOIN 
SELECT C.IdCategoria, C.NombreCat, P.NombrePro, P.Precio, DF.Cantidad
FROM Categorias AS C 
LEFT JOIN Productos AS P ON C.IdCategoria = P.IdCategoria
LEFT JOIN DetalleFactura AS DF ON P.IdProducto = DF.Idproducto

-- 3. RIGHT JOIN
SELECT C.IdCategoria, C.NombreCat, P.NombrePro, P.Precio
FROM Categorias AS C 
RIGHT JOIN Productos AS P ON C.IdCategoria = P.IdCategoria
RIGHT JOIN DetalleFactura AS DF ON P.IdProducto = DF.Idproducto -- Todos coinciden 

-- 4. FULL JOIN
SELECT *
FROM Categorias AS C 
FULL JOIN Productos AS P ON C.IdCategoria = P.IdProducto
FULL JOIN DetalleFactura AS DF ON P.IdProducto = DF.Idproducto

-- 5. CROSS JOIN 
SELECT *
FROM Categorias CROSS JOIN Productos

-- 6. SELF JOIN 
SELECT *
FROM Categorias AS C FULL JOIN Productos AS P ON C.IdCategoria = P.IdProducto

-- 2) VISTAS =================================================================================
/*  Crear una vista en donde muestre a todas las categorias y la posible relación y 
	detalle producto y crear una nueva columna llamada "Stock"*/

CREATE VIEW v_DetalleProducto AS
	SELECT C.NombreCat, P.NombrePro, P.Cantidad, DF.Cantidad AS 'Cantidad vendida', 
			(P.Cantidad - DF.Cantidad) AS Stock
	FROM Categorias AS C 
	LEFT JOIN Productos AS P ON C.IdCategoria = P.IdCategoria
	LEFT JOIN DetalleFactura AS DF ON P.Idproducto = DF.Idproducto

-- VER LA VISTA
SELECT * FROM v_DetalleProducto

-- DROP VIEW
DROP VIEW v_DetalleProducto

-- 3) PROCEDIMIENTOS =========================================================================
-- 1. CREATE -----------------------
CREATE PROCEDURE sp_InsertarCategoria
	@NombreCat VARCHAR(40),
	@Descripcion VARCHAR(40)
	AS
	INSERT INTO Categorias (NombreCat, Descripcion) VALUES (@NombreCat, @Descripcion)

-- EJECUTAR EL PROCEDIMIENTO 
EXEC sp_InsertarCategoria 'Videoconsolas', 'Consolas de videojuegos'
-- MOSTRAR LA NUEVA CATEGORIA
SELECT * FROM Categorias
-- ELIMINAR EL PROCEDIMIENTO
DROP PROCEDURE sp_InsertarCategoria
-- MOSTRAR LA CATEGORIA 
SELECT * FROM Categorias

-- 2. READ ------------------------------------------
CREATE PROCEDURE sp_buscarCompraCliente
	@identificacion INT
	AS 
	SELECT C.Identificacion, C.NombreCli, C.Apellido, F.IdFactura, F.FechaCompra, 
		   DF.Cantidad AS 'Cantidad comprada'
	FROM Clientes AS C
	LEFT JOIN Facturas AS F ON C.Identificacion = F.Identificacion
	LEFT JOIN DetalleFactura AS DF ON F.IdFactura = DF.IdFactura
	WHERE C.Identificacion = @identificacion

-- EJECUTAR EL PROCEDIMIENTO (Solo vista)
EXEC sp_buscarCompraCliente 34
DROP PROCEDURE sp_buscarCompraCliente

-- 3. UPDATE -----------------------------------------
CREATE PROCEDURE sp_actualizarDatosGeneral
	@IdProducto INT,
	@IdCategoria INT, 
	@NombrePro VARCHAR(40),
	@cantidad INT
	AS 
	UPDATE Productos SET IdCategoria = @IdCategoria, NombrePro = @NombrePro, 
			CantidadStock = @cantidad WHERE IdProducto = @IdProducto

-- USAR EL PROCEDIMIENTO
EXEC sp_actualizarDatosGeneral 3, 11, 'Play station 5', 26
-- VER 
SELECT * FROM Productos WHERE IdProducto = 3
DROP PROCEDURE sp_actualizarDatosGeneral

-- 4. ELIMINAR ----------------------------------------
CREATE PROCEDURE sp_eliminarCategoria
	@IdCategoria INT
	AS 
	DELETE FROM Categorias WHERE IdCategoria = @IdCategoria
-- EJECUTAR
EXEC sp_eliminarCategoria 12
-- VER 
SELECT * FROM Categorias

-- 4) CASE =============================================================================
-- Sin parámetro
CREATE VIEW v_verificarStock AS
	SELECT NombrePro, cantidad,
		CASE 
			WHEN Cantidad = 0 THEN 'Sin stock'
			WHEN Cantidad < 10 THEN 'Muy poco stock'
			WHEN cantidad < 20 THEN 'Stock bajo'
			WHEN Cantidad > 20 THEN 'Buen stock'
			ELSE 'Stock suficiente'
		END AS Estado
	FROM Productos
-- EJECUTAR 
SELECT * FROM v_verificarStock
DROP VIEW v_verificarStock

-- Con parámetros
CREATE VIEW v_verEstado
AS
	SELECT NombrePro, Precio, Cantidad,
		CASE Descontinuado
			WHEN 1 THEN 'En producción'
			WHEN 0 THEN 'Descontinuado'
			ELSE 'Nada'
		END AS Estado
	FROM Productos
-- EJECUTAR
SELECT * FROM v_verEstado
SELECT * FROM Productos
SELECT * FROM DetalleFactura

-- 5) TRIGGERS =============================================================================

-- Actualizar el stock teniendo en cuenta la cantidad comprada
CREATE TRIGGER trg_ActualizarStock
ON DetalleFactura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- VALIDAR STOCK
    IF EXISTS (
        SELECT 1
        FROM inserted I
        INNER JOIN Productos P 
            ON I.IdProducto = P.IdProducto
        WHERE I.Cantidad > P.CantidadStock
    )
    BEGIN
        RAISERROR('No hay stock suficiente',16,1);
        ROLLBACK TRANSACTION;
        RETURN;
    END


    -- INSERT (RESTAR STOCK) 
    UPDATE P SET P.CantidadStock = P.CantidadStock - I.Cantidad
    FROM Productos AS  P INNER JOIN inserted AS I ON P.IdProducto = I.IdProducto;

	-- UPDATE (Actualizar el stock teniendo en cuenta la nueva cantidad)
    UPDATE P SET P.CantidadStock = P.CantidadStock + D.Cantidad - I.Cantidad
    FROM Productos AS P
    INNER JOIN deleted AS D ON P.IdProducto = D.IdProducto
    INNER JOIN inserted AS I  ON I.IdProducto = D.IdProducto;

    -- DELETE (Sumar al stock la cantidad previamente comprada)
    UPDATE P SET P.CantidadStock = P.CantidadStock + D.Cantidad
    FROM Productos AS P INNER JOIN deleted AS D ON P.IdProducto = D.IdProducto;
END

-- Insertar datos
INSERT INTO DetalleFactura VALUES (4, 20, 3, 5)

-- Actualizar
UPDATE DetalleFactura SET Cantidad = 10 WHERE IdDetalle = 7000

-- Eliminar 
DELETE DetalleFactura WHERE IdDetalle = 7000