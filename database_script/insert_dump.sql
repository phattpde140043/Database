INSERT INTO categories (name) VALUES
('Electronics'),
('Clothing'),
('Home Appliances'),
('Books'),
('Sports');

INSERT INTO products (name, category_id) VALUES
('Smartphone', 1),
('T-Shirt', 2),
('Microwave Oven', 3),
('Novel Book', 4),
('Football', 5);


INSERT INTO products_sku (sku, product_id, color, size, price) VALUES
('SKU_SMART_001', 'PROD_00001', 'Black', '128GB', 499.99),
('SKU_TSHIRT_001', 'PROD_00002', 'Red', 'M', 19.99),
('SKU_OVEN_001', 'PROD_00003', 'Silver', '20L', 150.00),
('SKU_BOOK_001', 'PROD_00004', 'N/A', 'Standard', 12.50),
('SKU_FB_001', 'PROD_00005', 'White', '5', 29.99);

INSERT INTO customers (name, email, phone, address) VALUES
('Nguyen Van A', 'a.nguyen@example.com', '+84901111111', '123 Le Loi, HCM'),
('Tran Thi B', 'b.tran@example.com', '+84902222222', '45 Nguyen Hue, HCM'),
('Le Van C', 'c.le@example.com', '+84903333333', '78 Hai Ba Trung, HN'),
('Pham Thi D', 'd.pham@example.com', '+84904444444', '90 Tran Hung Dao, DN'),
('Hoang Van E', 'e.hoang@example.com', '+84905555555', '12 Bach Dang, HP');

INSERT INTO payment_types (name) VALUES
('Cash'),
('Credit Card'),
('Debit Card'),
('E-Wallet'),
('Bank Transfer');


INSERT INTO orders (customer_id, total_amount, shipping_address, payment_type_id, payment_status) VALUES
('CUST_000001', 529.98, '123 Le Loi, HCM', 2, 'completed'),
('CUST_000002', 19.99, '45 Nguyen Hue, HCM', 1, 'pending'),
('CUST_000003', 150.00, '78 Hai Ba Trung, HN', 3, 'completed'),
('CUST_000004', 42.49, '90 Tran Hung Dao, DN', 4, 'failed'),
('CUST_000005', 29.99, '12 Bach Dang, HP', 5, 'completed');

INSERT INTO order_items (order_id, product_id, sku_id, quantity, unit_price, order_date)
SELECT o.order_id, v.product_id, v.sku_id, v.quantity, v.unit_price, o.order_date
FROM orders o
JOIN (
    VALUES
        (6, 'PROD_00001', 6, 1, 499.99),
        (6, 'PROD_00005', 10, 1, 29.99),
        (7, 'PROD_00002', 7, 1, 19.99),
        (8, 'PROD_00003', 8, 1, 150.00),
        (9, 'PROD_00004', 9, 1, 12.50),
        (9, 'PROD_00005', 10, 1, 29.99),
        (10, 'PROD_00005', 10, 1, 29.99)
) AS v(order_id, product_id, sku_id, quantity, unit_price)
ON o.order_id = v.order_id;

Select * from customers
Select * from products
Select * from products_sku
Select * from orders
Select * from order_items
Select * from categories

