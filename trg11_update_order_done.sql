CREATE TRIGGER trg11
ON sqlprog11_orders
AFTER UPDATE
AS
BEGIN
    -- Ki?m tra tr?ng thái ðõn hàng ð? ðý?c update thành 'done' hay chýa
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

        -- Khai báo & con tr? s? duy?t qua t?ng hàng trong t?p k?t qu? c?a câu l?nh SELECT
        DECLARE prod_cursor CURSOR FOR
        SELECT od.product_id, od.quantity, p.min_quantity
        FROM inserted i
        INNER JOIN sqlprog11_ordersdetail od 
        ON i.order_id = od.order_id
        INNER JOIN sqlprog11_products p 
        ON od.product_id = p.product_id;

        -- M? con tr? ð? b?t ð?u duy?t d? li?u
        OPEN prod_cursor;

        -- L?y d? li?u t? con tr? vào các bi?n
        FETCH NEXT FROM prod_cursor INTO @product_id, @quantity, @min_quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tr? s? lý?ng s?n ph?m trong kho týõng ?ng v?i s? lý?ng ð? bán
            UPDATE sqlprog11_products
            SET quantity = quantity - @quantity
            WHERE product_id = @product_id;

            -- Ki?m tra n?u s? lý?ng t?n kho sau khi tr? nh? hõn ngý?ng t?i thi?u
            IF (
                SELECT quantity 
                FROM sqlprog11_products 
                WHERE product_id = @product_id
            ) < @min_quantity
            BEGIN
                -- T?o m?t yêu c?u ð?t hàng l?i (reorder) trong b?ng sqlprog11_reorder
                INSERT INTO sqlprog11_reorder (product_id, quantity, date_requested)
                VALUES (
                    @product_id,
                    (@min_quantity - (SELECT quantity FROM sqlprog11_products WHERE product_id = @product_id)),
                    GETDATE()
                );
            END;

            -- Ti?p t?c l?y hàng ti?p theo t? con tr?
            FETCH NEXT FROM prod_cursor INTO @product_id, @quantity, @min_quantity;
        END;

        -- Ðóng con tr? sau khi hoàn t?t
        CLOSE prod_cursor;

        -- Gi?i phóng b? nh? ðý?c s? d?ng b?i con tr?
        DEALLOCATE prod_cursor;
    END
END;


				
				
				
				
				
				
				























