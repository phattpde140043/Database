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
Select * from payment_types



-- ==========================================
-- 1. accounts
-- ==========================================
INSERT INTO accounts (account_name, account_type) VALUES
('Cash Account', 'asset'),
('Bank Account', 'asset'),
('Credit Card', 'liability'),
('Loan Account', 'liability'),
('Equity Account', 'equity');

-- ==========================================
-- 2. departments
-- ==========================================
INSERT INTO departments (name) VALUES
('Sales'),
('Logistics'),
('HR'),
('Finance'),
('IT');

-- ==========================================
-- 3. employees
-- (email lưu dạng bytea -> encode text)
-- ==========================================
INSERT INTO employees (employee_id, name, email, department_id, hire_date, salary)
VALUES
('E001', 'Alice', encode('alice@example.com','escape')::bytea, 1, now() - interval '500 days', 1200.00),
('E002', 'Bob',   encode('bob@example.com','escape')::bytea, 2, now() - interval '400 days', 1500.00),
('E003', 'Carol', encode('carol@example.com','escape')::bytea, 3, now() - interval '300 days', 1300.00),
('E004', 'David', encode('david@example.com','escape')::bytea, 4, now() - interval '200 days', 2000.00),
('E005', 'Eva',   encode('eva@example.com','escape')::bytea, 5, now() - interval '100 days', 1700.00);

-- ==========================================
-- 4. suppliers
-- ==========================================
INSERT INTO suppliers (name, contact_name, phone, email, created_at)
VALUES
('Supplier A', 'John Doe', encode('0123456789','escape')::bytea, encode('a@supplier.com','escape')::bytea, now() - interval '50 days'),
('Supplier B', 'Jane Doe', encode('0987654321','escape')::bytea, encode('b@supplier.com','escape')::bytea, now() - interval '40 days'),
('Supplier C', 'Mike Ross',encode('0222333444','escape')::bytea, encode('c@supplier.com','escape')::bytea, now() - interval '30 days'),
('Supplier D', 'Rachel Z', encode('0333444555','escape')::bytea, encode('d@supplier.com','escape')::bytea, now() - interval '20 days'),
('Supplier E', 'Harvey S', encode('0444555666','escape')::bytea, encode('e@supplier.com','escape')::bytea, now() - interval '10 days');

-- ==========================================
-- 5. purchase_orders (partition theo order_date)
-- ==========================================
INSERT INTO purchase_orders (supplier_id, order_date, status, total_amount) VALUES
(1, '2025-08-05', 'draft', 1000.00),
(2, '2025-08-10', 'approved', 2500.00),
(3, '2025-09-12', 'received', 500.00),
(4, '2025-09-20', 'cancelled', 0.00),
(5, '2025-10-01', 'approved', 3000.00);

-- ==========================================
-- 6. purchase_order_items (partition theo order_date)
-- ==========================================
INSERT INTO purchase_order_items (po_id, product_id, quantity, unit_price, order_date) VALUES
(1, 'P001', 10, 100.00, '2025-08-05'),
(2, 'P002', 5, 500.00, '2025-08-10'),
(3, 'P003', 20, 25.00, '2025-09-12'),
(4, 'P004', 15, 10.00, '2025-09-20'),
(5, 'P005', 30, 100.00, '2025-10-01');

-- ==========================================
-- 7. shipments (partition theo shipment_date)
-- giả sử đã có warehouses (id 1-2)
-- ==========================================
INSERT INTO shipments (order_id, warehouse_id, shipment_date, status) VALUES
(101, 1, '2025-08-02', 'pending'),
(102, 1, '2025-08-05', 'in_transit'),
(103, 2, '2025-09-01', 'delivered'),
(104, 2, '2025-09-10', 'cancelled'),
(105, 1, '2025-10-15', 'in_transit');

-- ==========================================
-- 8. delivery_tracking (partition theo checkpoint_time)
-- ==========================================
INSERT INTO delivery_tracking (shipment_id, shipment_date, checkpoint_time, location, status) VALUES
(1, '2025-08-02', '2025-08-03 08:00', 'Hanoi', 'in_transit'),
(1, '2025-08-02', '2025-08-04 10:00', 'Hai Phong', 'in_transit'),
(2, '2025-08-05', '2025-08-06 12:00', 'Da Nang', 'delivered'),
(3, '2025-09-01', '2025-09-02 09:00', 'Ho Chi Minh', 'in_transit'),
(5, '2025-10-15', '2025-10-16 11:00', 'Can Tho', 'in_transit');

-- ==========================================
-- 9. financial_transactions (partition theo transaction_date)
-- ==========================================
INSERT INTO financial_transactions (transaction_date, account_id, amount, type, status) VALUES
('2025-08-01', 1, 500.00, 'debit', 'approved'),
('2025-08-05', 2, 1200.00, 'credit', 'received'),
('2025-09-10', 3, 300.00, 'debit', 'draft'),
('2025-09-20', 4, 1000.00, 'credit', 'approved'),
('2025-10-05', 5, 2000.00, 'debit', 'cancelled');

select * from accounts

select * from departments 
select * from employees

select * from warehouses 

select * from suppliers
Select * from purchase_orders
select * from purchase_order_items

select * from shipments 
select * from delivery_tracking

select * from financial_transactions


-- ------------------------------------------------------------
-- Insert mẫu: Warehouses (5 rows)
-- ------------------------------------------------------------
BEGIN;

INSERT INTO warehouses (name, location)
VALUES
  ('Warehouse A', 'Hanoi, Vietnam'),
  ('Warehouse B', 'Ho Chi Minh, Vietnam'),
  ('Warehouse C', 'Da Nang, Vietnam'),
  ('Warehouse D', 'Hai Phong, Vietnam'),
  ('Warehouse E', 'Can Tho, Vietnam');

-- ------------------------------------------------------------
-- (TÙY CHỌN) Insert mẫu: Products (5 rows)
-- Nếu bạn đã có bảng products và categories, chỉnh category_id cho phù hợp.
-- Sử dụng product_id tĩnh 'P001'..'P005' để dễ tham chiếu.
-- ------------------------------------------------------------
INSERT INTO products (product_id, name, category_id, created_at)
VALUES
  ('P001', 'Product 1', 1, now() - interval '40 days'),
  ('P002', 'Product 2', 1, now() - interval '35 days'),
  ('P003', 'Product 3', 2, now() - interval '30 days'),
  ('P004', 'Product 4', 2, now() - interval '20 days'),
  ('P005', 'Product 5', 3, now() - interval '10 days');

-- ------------------------------------------------------------
-- (TÙY CHỌN) Insert mẫu: products_sku (5 rows) — 1 SKU / product
-- ------------------------------------------------------------
INSERT INTO products_sku (sku, product_id, color, size, price)
VALUES
  ('SKU_P001', 'P001', 'Red',    'M', 100.00),
  ('SKU_P002', 'P002', 'Blue',   'L', 150.00),
  ('SKU_P003', 'P003', 'Black',  'S',  75.50),
  ('SKU_P004', 'P004', 'White',  'XL', 20.00),
  ('SKU_P005', 'P005', 'Green',  'M', 250.00);

-- ------------------------------------------------------------
-- Insert mẫu: Inventory (5 rows) — tham chiếu đến warehouses & skus
-- Dùng subquery để lấy đúng warehouse_id và sku_id theo name/sku
-- ------------------------------------------------------------
INSERT INTO inventory (warehouse_id, product_id, sku_id, stock_quantity)
VALUES
  (
    (SELECT warehouse_id FROM warehouses WHERE name = 'Warehouse A' LIMIT 1),
    'P001',
    (SELECT sku_id FROM products_sku WHERE sku = 'SKU_P001' LIMIT 1),
    120
  ),
  (
    (SELECT warehouse_id FROM warehouses WHERE name = 'Warehouse B' LIMIT 1),
    'P002',
    (SELECT sku_id FROM products_sku WHERE sku = 'SKU_P002' LIMIT 1),
    50
  ),
  (
    (SELECT warehouse_id FROM warehouses WHERE name = 'Warehouse C' LIMIT 1),
    'P003',
    (SELECT sku_id FROM products_sku WHERE sku = 'SKU_P003' LIMIT 1),
    200
  ),
  (
    (SELECT warehouse_id FROM warehouses WHERE name = 'Warehouse D' LIMIT 1),
    'P004',
    (SELECT sku_id FROM products_sku WHERE sku = 'SKU_P004' LIMIT 1),
    15
  ),
  (
    (SELECT warehouse_id FROM warehouses WHERE name = 'Warehouse E' LIMIT 1),
    'P005',
    (SELECT sku_id FROM products_sku WHERE sku = 'SKU_P005' LIMIT 1),
    75
  );

COMMIT;


Select * from inventory