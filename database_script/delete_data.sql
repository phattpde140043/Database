CREATE OR REPLACE FUNCTION delete_old_order_items(retention_interval INTERVAL DEFAULT '3 months')
RETURNS void AS $$
BEGIN
    DELETE FROM order_items
    WHERE order_date < NOW() - retention_interval;

    RAISE NOTICE 'Order_items older than % deleted', retention_interval;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_old_orders_without_items(
    retention_interval INTERVAL DEFAULT '3 months'
)
RETURNS void AS $$
BEGIN
    DELETE FROM orders o
    WHERE o.order_date < NOW() - retention_interval
      AND NOT EXISTS (
          SELECT 1
          FROM order_items oi
          WHERE oi.order_id = o.order_id
      );

    RAISE NOTICE 'Old orphan orders older than % deleted', retention_interval;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_soft_deleted_skus(retention_interval INTERVAL DEFAULT '3 months')
RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT sku_id
        FROM products_sku
        WHERE deleted_at IS NOT NULL
          AND deleted_at < NOW() - retention_interval
    LOOP
        -- Xóa order_items trước
        DELETE FROM order_items
        WHERE sku_id = r.sku_id;

        -- Sau đó xóa SKU
        DELETE FROM products_sku
        WHERE sku_id = r.sku_id;

        RAISE NOTICE 'SKU % and its order_items deleted (soft-deleted older than %)', 
            r.sku_id, retention_interval;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_soft_deleted_products(retention_interval INTERVAL DEFAULT '3 months')
RETURNS void AS $$
DECLARE
    p RECORD;
    s RECORD;
BEGIN
    -- Vòng 1: xử lý SKU của các product bị soft-delete quá hạn
    FOR p IN
        SELECT product_id
        FROM products
        WHERE deleted_at IS NOT NULL
          AND deleted_at < NOW() - retention_interval
    LOOP
        FOR s IN
            SELECT sku_id
            FROM products_sku ps
            WHERE ps.product_id = p.product_id
        LOOP
            -- Kiểm tra SKU có order_item nào không
            IF NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.sku_id = s.sku_id) THEN
                DELETE FROM products_sku WHERE sku_id = s.sku_id;
                RAISE NOTICE 'Deleted SKU % under product % (no order_items)', s.sku_id, p.product_id;
            END IF;
        END LOOP;
    END LOOP;

    -- Vòng 2: xóa product nếu không còn SKU nào
    FOR p IN
        SELECT product_id
        FROM products
        WHERE deleted_at IS NOT NULL
          AND deleted_at < NOW() - retention_interval
    LOOP
        IF NOT EXISTS (SELECT 1 FROM products_sku ps WHERE ps.product_id = p.product_id) THEN
            DELETE FROM products WHERE product_id = p.product_id;
            RAISE NOTICE 'Deleted product % (no remaining SKUs)', p.product_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_soft_deleted_categories(retention_interval INTERVAL DEFAULT '3 months')
RETURNS void AS $$
DECLARE
    c RECORD;
BEGIN
    FOR c IN
        SELECT category_id
        FROM categories
        WHERE deleted_at IS NOT NULL
          AND deleted_at < NOW() - retention_interval
    LOOP
        -- Nếu category không có product nào active hoặc soft-delete chưa quá hạn
        IF NOT EXISTS (
            SELECT 1
            FROM products p
            WHERE p.category_id = c.category_id
        ) THEN
            DELETE FROM categories WHERE category_id = c.category_id;
            RAISE NOTICE 'Deleted category % (no remaining products)', c.category_id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_delivery_tracking()
RETURNS void AS $$
BEGIN
    DELETE FROM delivery_tracking
    WHERE shipment_date < NOW() - INTERVAL '3 months';
    
    RAISE NOTICE 'Deleted old delivery_tracking records older than 3 months';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_shipments()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM shipments s
    WHERE s.shipment_date < NOW() - INTERVAL '3 months'
      AND NOT EXISTS (
          SELECT 1
          FROM delivery_tracking d
          WHERE d.shipment_id = s.shipment_id
      )
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % shipments older than 3 months with no delivery_tracking', v_deleted_count;

    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_warehouses()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM warehouses w
    WHERE w.deleted_at IS NOT NULL
      AND w.deleted_at < NOW() - INTERVAL '3 months'
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.warehouse_id = w.warehouse_id
      )
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % warehouses soft-deleted > 3 months with no inventory linked', v_deleted_count;

    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_purchase_order_items()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM purchase_order_items poi
    WHERE poi.order_date < NOW() - INTERVAL '3 months'
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % purchase_order_items older than 3 months', v_deleted_count;
    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_purchase_orders()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM purchase_orders po
    WHERE po.order_date < NOW() - INTERVAL '3 months'
      AND NOT EXISTS (
          SELECT 1
          FROM purchase_order_items poi
          WHERE poi.po_id = po.po_id
      )
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % purchase_orders older than 3 months with no items', v_deleted_count;
    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_suppliers()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM suppliers s
    WHERE s.deleted_at IS NOT NULL
      AND s.deleted_at < NOW() - INTERVAL '3 months'
      AND NOT EXISTS (
          SELECT 1
          FROM purchase_orders po
          WHERE po.supplier_id = s.supplier_id
      )
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % suppliers soft-deleted > 3 months with no purchase_orders', v_deleted_count;
    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_financial_transactions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM financial_transactions ft
    WHERE ft.transaction_date < NOW() - INTERVAL '3 months'
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % financial_transactions older than 3 months', v_deleted_count;
    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_old_employees()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    DELETE FROM employees e
    WHERE e.deleted_at IS NOT NULL
      AND e.deleted_at < NOW() - INTERVAL '3 months'
    RETURNING 1 INTO v_deleted_count;

    RAISE NOTICE 'Deleted % employees soft-deleted > 3 months', v_deleted_count;
    RETURN COALESCE(v_deleted_count, 0);
END;
$$ LANGUAGE plpgsql;

