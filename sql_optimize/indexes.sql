
--index

drop table if exists study_cases.employees;
CREATE TABLE study_cases.employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    salary INTEGER,
    department_id INTEGER
);



CREATE OR REPLACE FUNCTION random_string(length INTEGER) RETURNS TEXT AS $$
DECLARE
    chars TEXT[] := '{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
    result TEXT := '';
BEGIN
    FOR i IN 1..length LOOP
        result := result || chars[1 + trunc(random() * 25)];
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    FOR i IN 1..1000000 LOOP
        INSERT INTO study_cases.employees (name, salary, department_id)
        VALUES (
            random_string(10), -- Генерация случайного имени длиной 10 символов
            (random() * 100000)::INTEGER, -- Генерация случайной зарплаты от 0 до 100000
            (random() * 10)::INTEGER + 1 -- Генерация случайного department_id от 1 до 10
        );
    END LOOP;
END;
$$;

select count(*)
from study_cases.employees e 

-- example 1
-- 106ms
-- 0.048ms
explain ANALYZE
select name, salary, department_id
from study_cases.employees
where name = 'humdoocgpo';

--example 2
--140ms
--106ms
explain analyze
select name, salary, department_id
from study_cases.employees
where salary >= 30000 and salary <= 50000;





-- Индекс по имени
CREATE INDEX idx_btree_name ON study_cases.employees (name);

-- Индекс по зарплате
CREATE INDEX idx_btree_salary ON study_cases.employees (salary);


drop index if exists idx_btree_name;
drop index if exists idx_btree_salary;




-- индекс GiST (Generalized Search Tree)

drop table if exists study_cases.documents;

CREATE TABLE study_cases.documents (
    id SERIAL PRIMARY KEY,
    content TEXT
);

CREATE INDEX idx_gist_text ON study_cases.documents USING GIST (content gist_trgm_ops);


-- добавляем 10к записей в таблицу
DO $$
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO study_cases.documents (content) 
        VALUES ('example text ' || i);
    END LOOP;
END $$;


select *
from study_cases.documents e 
limit 100;


-- 23ms
-- 5ms
explain analyze
SELECT * FROM study_cases.documents WHERE  content  % 'example';
--триграммы Для слова "example" триграммы будут: ["exa", "xam", "amp", "mpl", "ple"].







-- Создание таблицы locations

drop table if exists study_cases.locations;
CREATE TABLE study_cases.locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    geom GEOMETRY(Point, 4326)
);

-- Создание индекса GiST
CREATE INDEX idx_gist_location ON study_cases.locations USING GiST (geom);

-- Наполнение таблицы данными в цикле
DO $$
DECLARE
    i INTEGER;
    lat FLOAT;
    lon FLOAT;
BEGIN
    FOR i IN 1..30000 LOOP
        lat := 10 + random() * (20 - 10);
        lon := 10 + random() * (20 - 10);
        
        INSERT INTO study_cases.locations (name, geom) 
        VALUES ('Location ' || i, ST_SetSRID(ST_MakePoint(lon, lat), 4326));
    END LOOP;
END $$;


select *
from study_cases.locations
limit 100

--8ms
--2ms
explain analyze
SELECT * FROM study_cases.locations 
WHERE geom && ST_MakeEnvelope(15, 15, 25, 25, 4326);





--GIN (Generalized Inverted Index)

drop table if exists study_cases.documents_json;

CREATE TABLE study_cases.documents_json (
    id SERIAL PRIMARY KEY,
    data JSONB
);


CREATE INDEX idx_gin_jsonb ON study_cases.documents_json USING GIN (data jsonb_path_ops);


DO $$
BEGIN
    FOR i IN 1..30000 LOOP
        INSERT INTO study_cases.documents_json  (data) 
        VALUES (jsonb_build_object('author', 'Author ' || i, 'text', 'example text ' || i));
    END LOOP;
END $$;


--12ms
--0ms
explain analyze
SELECT * FROM study_cases.documents_json  WHERE data @> '{"author": "Author 1"}';

--Block Range INdex




