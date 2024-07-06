 

-- Хинты

CREATE EXTENSION IF NOT EXISTS pg_hint_plan;

SELECT oid, extname, extowner FROM pg_extension;



drop table if exists study_cases.my_table;
-- Создание таблицы my_table
CREATE TABLE study_cases.my_table (
    id SERIAL PRIMARY KEY,
    amount_sale INT,
    user_id TEXT
);

-- Заполнение таблицы my_table в цикле

DO $$
DECLARE
    i INT := 1;
BEGIN
    WHILE i <= 1000000 LOOP
        INSERT INTO study_cases.my_table (amount_sale, user_id)
        VALUES (floor(random() * 1000)::int, md5(random()::text));
        i := i + 1;
    END LOOP;
END $$;


select *
from study_cases.my_table
limit 100;


select count(1)
from study_cases.my_table


-- Создаем индекс на таблицу и на колонку some_column
CREATE INDEX idx_some_column ON study_cases.my_table(amount_sale);



-- > 500 122ms
-- = 500 95ms 2ms
explain analyze
SELECT * 
FROM study_cases.my_table
WHERE amount_sale = 500;


explain analyze
SELECT /*+ SeqScan(study_cases.my_table) */ * 
FROM study_cases.my_table 
WHERE amount_sale > 500;



explain analyze
SELECT /*+ IndexScan(study_cases.my_table idx_some_column) */ * 
FROM study_cases.my_table 
WHERE amount_sale > 500;


DROP TABLE IF EXISTS study_cases.transactions;
CREATE TABLE study_cases.transactions (
    id SERIAL PRIMARY KEY,
    amount_sale INT,
    user_id TEXT,
    transaction_date DATE
);


DROP TABLE IF EXISTS study_cases.users;
CREATE TABLE study_cases.users (
    user_id TEXT PRIMARY KEY,
    user_name TEXT
);


DROP TABLE IF EXISTS study_cases.orders;
CREATE TABLE study_cases.orders (
    order_id SERIAL PRIMARY KEY,
    user_id TEXT,
    order_name TEXT
);


DROP TABLE IF EXISTS study_cases.sellers;
CREATE TABLE study_cases.sellers (
    seller_id SERIAL PRIMARY KEY,
    order_id INT,
    seller_name TEXT
);

-- Заполнение таблицы users 10,000 записями
SELECT populate_users(10000);

-- Заполнение таблицы orders 25,000 записями
SELECT populate_orders(25000);

-- Заполнение таблицы sellers 5,000 записями
SELECT populate_sellers(5000);

-- Заполнение таблицы transactions 50,000 записями
SELECT populate_transactions(50000);

users: 10,000 записей
sellers: 5,000 записей
orders: 25,000 записей
transactions: 50,000 записей

--33.5ms
--31.338ms
--1.2ms

EXPLAIN ANALYZE
SELECT /*+ Leading(s o u t) */ t.*, u.user_name, o.order_name, s.seller_name
FROM study_cases.transactions t
JOIN study_cases.users u ON t.user_id = u.user_id
JOIN study_cases.orders o ON t.user_id = o.user_id
JOIN study_cases.sellers s ON o.order_id = s.order_id
WHERE t.transaction_date >= '2024-01-01';



CREATE OR REPLACE FUNCTION populate_users(n INTEGER) RETURNS VOID AS $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..n LOOP
        INSERT INTO study_cases.users (user_id, user_name)
        VALUES (md5(random()::text), md5(random()::text));
    END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION populate_orders(n INTEGER) RETURNS VOID AS $$
DECLARE
    i INTEGER;
    uid TEXT;
BEGIN
    FOR i IN 1..n LOOP
        SELECT user_id INTO uid FROM study_cases.users ORDER BY random() LIMIT 1;
        INSERT INTO study_cases.orders (user_id, order_name)
        VALUES (uid, md5(random()::text));
    END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION populate_sellers(n INTEGER) RETURNS VOID AS $$
DECLARE
    i INTEGER;
    oid INTEGER;
BEGIN
    FOR i IN 1..n LOOP
        SELECT order_id INTO oid FROM study_cases.orders ORDER BY random() LIMIT 1;
        INSERT INTO study_cases.sellers (order_id, seller_name)
        VALUES (oid, md5(random()::text));
    END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION populate_transactions(n INTEGER) RETURNS VOID AS $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..n LOOP
        INSERT INTO study_cases.transactions (amount_sale, user_id, transaction_date)
        VALUES (random() * 1000, md5(random()::text), '2024-01-01'::date + (random() * 365)::int);
    END LOOP;
END;
$$ LANGUAGE plpgsql;
