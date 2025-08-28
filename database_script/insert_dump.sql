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
('SKU_SMART_001', 'PROD_001', 'Black', '128GB', 499.99),
('SKU_TSHIRT_001', 'PROD_002', 'Red', 'M', 19.99),
('SKU_OVEN_001', 'PROD_003', 'Silver', '20L', 150.00),
('SKU_BOOK_001', 'PROD_004', 'N/A', 'Standard', 12.50),
('SKU_FB_001', 'PROD_005', 'White', '5', 29.99);

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
('CUST_001', 529.98, '123 Le Loi, HCM', 2, 'completed'),
('CUST_002', 19.99, '45 Nguyen Hue, HCM', 1, 'pending'),
('CUST_003', 150.00, '78 Hai Ba Trung, HN', 3, 'completed'),
('CUST_004', 42.49, '90 Tran Hung Dao, DN', 4, 'failed'),
('CUST_005', 29.99, '12 Bach Dang, HP', 5, 'completed');

INSERT INTO order_items (order_id, product_id, sku_id, quantity, unit_price) VALUES
(1, 'PROD_001', 1, 1, 499.99),
(1, 'PROD_005', 5, 1, 29.99),
(2, 'PROD_002', 2, 1, 19.99),
(3, 'PROD_003', 3, 1, 150.00),
(4, 'PROD_004', 4, 1, 12.50);
(4, 'PROD_005', 5, 1, 29.99),
(5, 'PROD_005', 5, 1, 29.99);

