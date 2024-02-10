DROP DATABASE IF EXISTS mydb;
CREATE DATABASE mydb;
USE mydb;

CREATE TABLE transaction_status (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_name VARCHAR(255) NOT NULL,
    status VARCHAR(255) DEFAULT 'pending'
);
CREATE TABLE customers (
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    phone_number VARCHAR(20) NOT NULL,
    name VARCHAR(255) DEFAULT 'guest'
);
CREATE TABLE sellers (
    seller_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    product_name VARCHAR(255) NOT NULL
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    product VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
	customer_id INT NOT NULL,
    seller_id INT NOT NULL,
    transaction_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    FOREIGN KEY (transaction_id) REFERENCES transaction_status(transaction_id)
);

CREATE TABLE transfers (
    transfer_id INT PRIMARY KEY AUTO_INCREMENT,
    product VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    transaction_id INT,
    seller_id INT NOT NULL,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    FOREIGN KEY (transaction_id) REFERENCES transaction_status(transaction_id),
    CHECK (EXISTS (SELECT 1 FROM transaction_status WHERE transaction_id = transfers.transaction_id AND status = 'OK'))
);

-- Триггеры для концепции "безопасности":
DELIMITER //
CREATE TRIGGER after_payments_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    INSERT INTO transaction_status (transaction_name, status)
    VALUES (CONCAT('оплата_', NEW.payment_id), 'pending');
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_transaction_status_update
AFTER UPDATE ON transaction_status
FOR EACH ROW
BEGIN
    IF NEW.status = 'OK' AND OLD.status != 'OK' THEN
        INSERT INTO transfers (product, amount, transaction_id, seller_id)
        SELECT product, amount, transaction_id, seller_id
        FROM payments
        WHERE transaction_id = NEW.transaction_id;
    END IF;
END;
//
DELIMITER ;
-- Заполним проверочными данными.
INSERT INTO sellers (name, phone_number, product_name) VALUES ('Продаванов Максим', '88005553535', 'ВеликийТовар');
INSERT INTO sellers (name, phone_number, product_name) VALUES ('Кидалов Игорь', '+77008009895', 'СомнительныйТовар');
INSERT INTO customers (phone_number, name) VALUES ('+35355558008', 'Покупалов Иван');
INSERT INTO customers (phone_number, name) VALUES ('+123456789', 'Непокупалов Петр');
-- Пример работы, пока status не станет OK, перечисление продавцу не запишется.
INSERT INTO payments (product, amount, customer_id, seller_id) VALUES ('ВеликийТовар', 100.00, 1, 1);
INSERT INTO payments (product, amount, customer_id, seller_id) VALUES ('СомнительныйТовар', 150.00, 2, 2);
UPDATE payments SET transaction_id = 1 WHERE (payment_id = 1);
-- Вот тут мы обозначаем, что status стал OK, появляется новая строка в transfers
UPDATE transaction_status SET status = 'OK' WHERE (transaction_id = 1);
