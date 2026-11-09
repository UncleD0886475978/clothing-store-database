-- clothing-store-database — seed data (ALL SAMPLE DATA)
-- ============================================================================
-- Everything in this file is SAMPLE data for the fictional neighborhood
-- apparel store "Threads & Co.": a sample catalog, sample stock levels,
-- sample customers and sample orders. No real people, no real sales.
-- IDs are pinned so variants / inventory / order items line up exactly.
-- INSERT IGNORE makes re-runs safe against the UNIQUE keys (sku, email, code).
-- ============================================================================

-- ---------- Categories (6) ----------
INSERT IGNORE INTO categories (id, name) VALUES
  (1, 'Men'),
  (2, 'Women'),
  (3, 'Kids'),
  (4, 'Shoes'),
  (5, 'Accessories'),
  (6, 'Sale');

-- ---------- Products (12) ----------
INSERT IGNORE INTO products (id, category_id, name, description, base_price) VALUES
  (1,  1, 'Classic Crew T-Shirt', 'Everyday cotton crew-neck tee.', 19.99),
  (2,  1, 'Slim-Fit Jeans', 'Stretch-denim slim-fit jeans.', 49.99),
  (3,  1, 'Hooded Sweatshirt', 'Brushed-fleece pullover hoodie.', 39.99),
  (4,  2, 'Summer Dress', 'Lightweight floral summer dress.', 44.99),
  (5,  4, 'Running Shoes', 'Cushioned everyday running shoes.', 79.99),
  (6,  5, 'Leather Wallet', 'Full-grain leather bifold wallet.', 29.99),
  (7,  5, 'Baseball Cap', 'Adjustable cotton twill cap.', 16.99),
  (8,  2, 'Denim Jacket', 'Classic trucker-style denim jacket.', 69.99),
  (9,  5, 'Wool Scarf', 'Warm woven wool scarf.', 24.99),
  (10, 1, 'Chino Shorts', 'Flat-front chino shorts.', 34.99),
  (11, 2, 'Yoga Leggings', 'High-waist stretch yoga leggings.', 39.99),
  (12, 4, 'Canvas Sneakers', 'Low-top canvas sneakers.', 54.99);

-- ---------- Product variants (30) — sizes S/M/L/XL, waist, shoe sizes, OS ----------
INSERT IGNORE INTO product_variants (id, product_id, sku, size, color, price) VALUES
  (1,  1, 'TC-TSHIRT-M-BLK',  'M',  'Black', 19.99),
  (2,  1, 'TC-TSHIRT-L-WHT',  'L',  'White', 19.99),
  (3,  1, 'TC-TSHIRT-S-NVY',  'S',  'Navy', 19.99),
  (4,  2, 'TC-JEANS-32-BLU',  '32', 'Blue', 49.99),
  (5,  2, 'TC-JEANS-34-BLK',  '34', 'Black', 49.99),
  (6,  3, 'TC-HOODIE-M-GRY',  'M',  'Gray', 39.99),
  (7,  3, 'TC-HOODIE-L-BLK',  'L',  'Black', 39.99),
  (8,  3, 'TC-HOODIE-XL-NVY', 'XL', 'Navy', 39.99),
  (9,  4, 'TC-DRESS-S-YEL',   'S',  'Yellow', 44.99),
  (10, 4, 'TC-DRESS-M-FLR',   'M',  'Floral', 44.99),
  (11, 4, 'TC-DRESS-L-RED',   'L',  'Red', 44.99),
  (12, 5, 'TC-RUN-9-BLK',     '9',  'Black', 79.99),
  (13, 5, 'TC-RUN-10-WHT',    '10', 'White', 79.99),
  (14, 5, 'TC-RUN-11-BLU',    '11', 'Blue', 79.99),
  (15, 6, 'TC-WALLET-OS-BRN', 'OS', 'Brown', 29.99),
  (16, 6, 'TC-WALLET-OS-BLK', 'OS', 'Black', 29.99),
  (17, 7, 'TC-CAP-OS-RED',    'OS', 'Red', 16.99),
  (18, 7, 'TC-CAP-OS-BLK',    'OS', 'Black', 16.99),
  (19, 8, 'TC-JACKET-M-BLU',  'M',  'Blue', 69.99),
  (20, 8, 'TC-JACKET-L-BLU',  'L',  'Blue', 69.99),
  (21, 9, 'TC-SCARF-OS-GRY',  'OS', 'Gray', 24.99),
  (22, 9, 'TC-SCARF-OS-PLD',  'OS', 'Plaid', 24.99),
  (23, 10, 'TC-SHORTS-32-KHK', '32', 'Khaki', 34.99),
  (24, 10, 'TC-SHORTS-34-NVY', '34', 'Navy', 34.99),
  (25, 11, 'TC-LEGGINGS-S-BLK', 'S', 'Black', 39.99),
  (26, 11, 'TC-LEGGINGS-M-BLK', 'M', 'Black', 39.99),
  (27, 11, 'TC-LEGGINGS-L-GRY', 'L', 'Gray', 39.99),
  (28, 12, 'TC-SNEAK-8-WHT',  '8',  'White', 54.99),
  (29, 12, 'TC-SNEAK-9-WHT',  '9',  'White', 54.99),
  (30, 12, 'TC-SNEAK-10-BLK', '10', 'Black', 54.99);

-- ---------- Inventory — one row for EVERY variant ----------
INSERT IGNORE INTO inventory (variant_id, quantity_on_hand, reorder_level) VALUES
  (1, 42, 10), (2, 35, 10), (3, 28, 10),
  (4, 18, 5),  (5, 14, 5),
  (6, 22, 8),  (7, 19, 8),  (8, 9, 5),
  (9, 12, 4),  (10, 15, 4), (11, 7, 4),
  (12, 11, 3), (13, 13, 3), (14, 6, 3),
  (15, 20, 5), (16, 17, 5),
  (17, 30, 10), (18, 26, 10),
  (19, 8, 3),  (20, 5, 3),
  (21, 16, 5), (22, 10, 5),
  (23, 21, 6), (24, 18, 6),
  (25, 24, 8), (26, 27, 8), (27, 12, 8),
  (28, 14, 4), (29, 16, 4), (30, 9, 4);

-- ---------- Customers (5, sample) ----------
INSERT IGNORE INTO customers (id, first_name, last_name, email, phone) VALUES
  (1, 'Maya', 'Johnson', 'maya.johnson@example.com', '555-0101'),
  (2, 'Daniel', 'Osei', 'daniel.osei@example.com', '555-0102'),
  (3, 'Priya', 'Nair', 'priya.nair@example.com', '555-0103'),
  (4, 'Tom', 'Becker', 'tom.becker@example.com', '555-0104'),
  (5, 'Lena', 'Ortiz', 'lena.ortiz@example.com', '555-0105');

-- ---------- Orders (4) — totals match their items below ----------
-- Order 1: 2x TC-TSHIRT-M-BLK (39.98) + 1x TC-CAP-OS-RED (16.99) = 56.97
-- Order 2: 1x TC-RUN-9-BLK (79.99) + 1x TC-LEGGINGS-M-BLK (39.99) = 119.98
-- Order 3: 1x TC-JEANS-32-BLU (49.99) + 1x TC-HOODIE-M-GRY (39.99) = 89.98
-- Order 4: 1x TC-DRESS-M-FLR (44.99) + 1x TC-SCARF-OS-GRY (24.99) = 69.98
INSERT IGNORE INTO orders (id, customer_id, order_date, status, total) VALUES
  (1, 1, '2025-06-01 10:15:00', 'paid', 56.97),
  (2, 2, '2025-06-03 14:40:00', 'delivered', 119.98),
  (3, 3, '2025-06-05 09:05:00', 'shipped', 89.98),
  (4, 4, '2025-06-07 16:20:00', 'pending', 69.98);

INSERT IGNORE INTO order_items (order_id, variant_id, quantity, unit_price) VALUES
  (1, 1, 2, 19.99),
  (1, 17, 1, 16.99),
  (2, 12, 1, 79.99),
  (2, 26, 1, 39.99),
  (3, 4, 1, 49.99),
  (3, 6, 1, 39.99),
  (4, 10, 1, 44.99),
  (4, 21, 1, 24.99);

-- ---------- Payments — one per order ----------
INSERT IGNORE INTO payments (order_id, method, amount, status, paid_at) VALUES
  (1, 'card', 56.97, 'completed', '2025-06-01 10:16:00'),
  (2, 'card', 119.98, 'completed', '2025-06-03 14:41:00'),
  (3, 'mobile_money', 89.98, 'completed', '2025-06-05 09:06:00'),
  (4, 'cash', 69.98, 'pending', NULL);

-- ---------- Promotions (2) ----------
INSERT IGNORE INTO promotions (code, description, discount_percent, starts_on, ends_on, active) VALUES
  ('WELCOME10', 'Welcome offer — 10% off a first order', 10.00, '2025-01-01', '2025-12-31', TRUE),
  ('SUMMER20', 'Summer sale — 20% off selected lines', 20.00, '2025-06-01', '2025-08-31', TRUE);
