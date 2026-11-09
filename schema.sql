-- clothing-store-database — MySQL 8 schema (Threads & Co. apparel retail)
-- All tables InnoDB with foreign keys. ENUMs pin order / payment vocabularies.
-- Load order in setup.sh: schema.sql first, then seed.sql.
-- Safe to re-run: every table uses CREATE TABLE IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS categories (
  id   INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  category_id INT NOT NULL,
  name        VARCHAR(200) NOT NULL,
  description TEXT,
  base_price  DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS product_variants (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  sku        VARCHAR(50) NOT NULL UNIQUE,
  size       VARCHAR(20),
  color      VARCHAR(50),
  price      DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_variants_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventory (
  variant_id       INT PRIMARY KEY,
  quantity_on_hand INT NOT NULL DEFAULT 0,
  reorder_level    INT NOT NULL DEFAULT 5,
  CONSTRAINT fk_inventory_variant FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(100) NOT NULL,
  email      VARCHAR(255) NOT NULL UNIQUE,
  phone      VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status      ENUM('pending','paid','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
  total       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  order_id   INT NOT NULL,
  variant_id INT NOT NULL,
  quantity   INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(id),
  CONSTRAINT fk_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  method   ENUM('card','cash','mobile_money') NOT NULL,
  amount   DECIMAL(10,2) NOT NULL,
  status   VARCHAR(30) NOT NULL DEFAULT 'completed',
  paid_at  TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS promotions (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  code             VARCHAR(50) NOT NULL UNIQUE,
  description      VARCHAR(255),
  discount_percent DECIMAL(5,2) NOT NULL,
  starts_on        DATE,
  ends_on          DATE,
  active           BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;
