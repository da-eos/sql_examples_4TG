
drop table if exists  study_cases.transactions cascade;

CREATE TABLE study_cases.transactions (
    id SERIAL PRIMARY KEY,
    from_user VARCHAR(100),
    to_user VARCHAR(100),
    amount NUMERIC,
    transaction_date TIMESTAMPTZ,
    additional_comment TEXT
);


-- looop 1ML records
DO $$
DECLARE
    i INTEGER;
    user_count INTEGER := 1000;
BEGIN
    FOR i IN 1..100000 LOOP
        INSERT INTO study_cases.transactions (from_user, to_user, amount, transaction_date, additional_comment) 
        VALUES (
            'user_' || (random() * user_count)::INT,
            'user_' || (random() * user_count)::INT,
            random() * 1000, 
            NOW() - INTERVAL '1 day' * (random() * 365),
            'transaction ' || i
        );
    END LOOP;
END $$;



select count(1)
from study_cases.transactions


select *
from study_cases.transactions
limit 100;
--2
select max(transaction_date),min(transaction_date)
from study_cases.transactions

--313ms
--350ms
EXPLAIN ANALYZE
SELECT from_user, SUM(amount) AS total_sent
FROM study_cases.transactions
where transaction_date >= '2024-01-01'
GROUP BY from_user
order by SUM(amount) desc 
limit 10;

-- mat.view

CREATE MATERIALIZED VIEW mv_total_sent AS
SELECT from_user, SUM(amount) AS total_sent
FROM study_cases.transactions
where transaction_date >= '2024-01-01'
GROUP BY from_user
order by SUM(amount) desc 
limit 10;


REFRESH MATERIALIZED VIEW mv_total_sent;

--0.042
--0.017
EXPLAIN ANALYZE
SELECT * FROM mv_total_sent;
