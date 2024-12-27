CREATE TRIGGER trg11
ON sqlprog11_orders
AFTER UPDATE
AS
BEGIN
    -- Ki?m tra tr?ng th�i ��n h�ng �? ��?c update th�nh 'done' hay ch�a
    IF EXISTS (
        SELECT * 
        FROM inserted i
        INNER JOIN deleted d
        ON i.order_id = d.order_id 
        WHERE d.status != 'done' AND i.status = 'done'
    )
    BEGIN
        DECLARE @product_id INT;
        DECLARE @quantity INT;
        DECLARE @min_quantity INT;

        -- Khai b�o & con tr? s? duy?t qua t?ng h�ng trong t?p k?t qu? c?a c�u l?nh SELECT
        DECLARE prod_cursor CURSOR FOR
        SELECT od.product_id, od.quantity, p.min_quantity
        FROM inserted i
        INNER JOIN sqlprog11_ordersdetail od 
        ON i.order_id = od.order_id
        INNER JOIN sqlprog11_products p 
        ON od.product_id = p.product_id;

        -- M? con tr? �? b?t �?u duy?t d? li?u
        OPEN prod_cursor;

        -- L?y d? li?u t? con tr? v�o c�c bi?n
        FETCH NEXT FROM prod_cursor INTO @product_id, @quantity, @min_quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tr? s? l�?ng s?n ph?m trong kho t��ng ?ng v?i s? l�?ng �? b�n
            UPDATE sqlprog11_products
            SET quantity = quantity - @quantity
            WHERE product_id = @product_id;

            -- Ki?m tra n?u s? l�?ng t?n kho sau khi tr? nh? h�n ng�?ng t?i thi?u
            IF (
                SELECT quantity 
                FROM sqlprog11_products 
                WHERE product_id = @product_id
            ) < @min_quantity
            BEGIN
                -- T?o m?t y�u c?u �?t h�ng l?i (reorder) trong b?ng sqlprog11_reorder
                INSERT INTO sqlprog11_reorder (product_id, quantity, date_requested)
                VALUES (
                    @product_id,
                    (@min_quantity - (SELECT quantity FROM sqlprog11_products WHERE product_id = @product_id)),
                    GETDATE()
                );
            END;

            -- Ti?p t?c l?y h�ng ti?p theo t? con tr?
            FETCH NEXT FROM prod_cursor INTO @product_id, @quantity, @min_quantity;
        END;

        -- ��ng con tr? sau khi ho�n t?t
        CLOSE prod_cursor;

        -- Gi?i ph�ng b? nh? ��?c s? d?ng b?i con tr?
        DEALLOCATE prod_cursor;
    END
END;


				
				
				
				
				
				
				























