-- ========================================================
-- PROJECT: Amazon E-commerce ETL Data Pipeline
-- 500K ROWS | Data Engineer Project
-- ========================================================

-- 1. count total rows
SELECT 
  COUNT(*) AS total_rows 
FROM amazon_products;

-- 2. Make id, main_category, ratings as Primary Key
ALTER TABLE amazon_products
MODIFY id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE amazon_products
MODIFY main_category VARCHAR(100);

ALTER TABLE amazon_products
MODIFY ratings VARCHAR(50);

-- 3. Check table structure
SHOW COLUMNS FROM amazon_products;

-- 4. MASTER TABLE FOR JOIN
CREATE TABLE category_master (
  category_id INT PRIMARY KEY,
  main_category VARCHAR(100),
  manager_name VARCHAR(100)
);

INSERT INTO category_master VALUES
(1, 'appliances', 'Ramesh'),
(2, 'computers', 'Suresh'),
(3, 'electronics', 'Bhuvan');

-- 5. INDEXING FOR PERFORMANCE
CREATE INDEX idx_category ON amazon_products(main_category);
CREATE INDEX idx_rating ON amazon_products(ratings);

-- 6. CLEANING WITH COALESCE - Ratings
SELECT id, name, COALESCE(ratings, 0) AS clean_rating
FROM amazon_products LIMIT 10;

-- 7. CLEANING WITH COALESCE - Price
SELECT id, name, COALESCE(discount_price, actual_price, 0) AS final_price
FROM amazon_products LIMIT 10;

-- 8. VIEW FOR CLEAN DATA
CREATE VIEW vw_clean_products AS
SELECT id, name, COALESCE(discount_price, 0) AS final_price, COALESCE(ratings, 0) AS final_rating
FROM amazon_products;

-- 9. INNER JOIN
SELECT p.name, c.manager_name
FROM amazon_products p
INNER JOIN category_master c ON p.main_category = c.main_category
LIMIT 10;

-- 10. LEFT JOIN
SELECT p.name, c.manager_name
FROM amazon_products p
LEFT JOIN category_master c ON p.main_category = c.main_category
LIMIT 10;

-- 11. RANK - best product in each category
SELECT main_category, name, ratings,
RANK() OVER (PARTITION BY main_category ORDER BY ratings DESC) AS rank_no
FROM amazon_products LIMIT 10;

-- 12. LAG - previous price
SELECT main_category, discount_price,
LAG(discount_price) OVER (PARTITION BY main_category ORDER BY discount_price) AS prev_price
FROM amazon_products LIMIT 10;

-- 13. AUDIT LOG & TRIGGER
CREATE TABLE product_audit_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT,
  old_price DECIMAL(10,2),
  new_price DECIMAL(10,2),
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_price_change
BEFORE UPDATE ON amazon_products
FOR EACH ROW
BEGIN
  IF OLD.discount_price != NEW.discount_price THEN
    INSERT INTO product_audit_log(product_id, old_price, new_price)
    VALUES (OLD.id, OLD.discount_price, NEW.discount_price);
  END IF;
END$$
DELIMITER ;

-- 14. Show views
SHOW FULL TABLES WHERE TABLE_TYPE LIKE 'VIEW';