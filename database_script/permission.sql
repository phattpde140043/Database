--------------------------------------------------------------------------------
--                               Phân quyền

-- 1. Tạo các ROLE chính
CREATE ROLE db_admin; --WITH LOGIN PASSWORD 'your_password';
CREATE ROLE db_engineer; --WITH LOGIN PASSWORD 'your_password';
CREATE ROLE db_analyst; --WITH LOGIN PASSWORD 'your_password';
CREATE ROLE sale_app; --WITH LOGIN PASSWORD 'your_password';
CREATE ROLE logistic_app; --WITH LOGIN PASSWORD 'your_password';
CREATE ROLE erp_app; --WITH LOGIN PASSWORD 'your_password';

-- Các role bổ sung cho dữ liệu PII và nghiệp vụ
CREATE ROLE pii_role;
CREATE ROLE biz_view_role;

-- 2. REVOKE mặc định cho tất cả user ngoài dự án
\connect pos_database;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE pos_database FROM PUBLIC;

\connect logistic_database;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE logistic_database FROM PUBLIC;

\connect erp_database;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE erp_database FROM PUBLIC;


----------------------------------------------------
-- 3. Phân quyền cho từng role
----------------------------------------------------

-- DB Admin: toàn quyền
CREATE OR REPLACE FUNCTION grant_dba_privileges(
    target_db TEXT,
    target_user TEXT,
    target_schema TEXT DEFAULT 'public'
) RETURNS void AS
$$
DECLARE
    role_exists BOOLEAN;
BEGIN
    -- 1. Tạo user nếu chưa tồn tại
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = target_user) INTO role_exists;
    IF NOT role_exists THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', target_user, 'your_password');
    END IF;

    -- 2. Gán quyền trên database
    EXECUTE format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', target_db, target_user);

    -- 3. Gán quyền trên schema
    EXECUTE format('GRANT ALL PRIVILEGES ON SCHEMA %I TO %I', target_schema, target_user);

    -- 4. Gán quyền trên tất cả TABLES, SEQUENCES, FUNCTIONS trong schema
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO %I', target_schema, target_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I', target_schema, target_user);
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA %I TO %I', target_schema, target_user);

    -- 5. Thiết lập quyền mặc định cho object tạo mới
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON TABLES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON FUNCTIONS TO %I',
        target_schema, target_user
    );

    -- 6. (Tuỳ chọn) Cho phép user tạo database
    EXECUTE format('ALTER ROLE %I CREATEDB', target_user);

END;
$$ LANGUAGE plpgsql;

SELECT grant_dba_privileges('pos_database', 'db_admin', 'public');
SELECT grant_dba_privileges('logistic_database', 'db_admin', 'public');
SELECT grant_dba_privileges('erp_database', 'db_admin', 'public');


-- DB Engineer: chỉ DML, không DELETE

CREATE OR REPLACE FUNCTION grant_de_privileges(
    target_db TEXT,
    target_user TEXT,
    target_schema TEXT DEFAULT 'public'
) RETURNS void AS
$$
DECLARE
    role_exists BOOLEAN;
BEGIN
    -- 1. Tạo role/user nếu chưa tồn tại
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = target_user) INTO role_exists;
    IF NOT role_exists THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', target_user, 'changeme');
    END IF;

    -- 2. Database-level: CONNECT, CREATE, TEMP
    EXECUTE format('GRANT CONNECT, CREATE, TEMP ON DATABASE %I TO %I', target_db, target_user);

    -- 3. Schema-level: USAGE, CREATE
    EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I', target_schema, target_user);

    -- 4. Table-level: CHỈ SELECT, INSERT, UPDATE, REFERENCES, TRIGGER
    EXECUTE format(
        'GRANT SELECT, INSERT, UPDATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA %I TO %I',
        target_schema, target_user
    );

    -- 5. Sequence-level: ALL (cần để thao tác nextval/serial/identity)
    EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I', target_schema, target_user);

    -- 6. Function-level: EXECUTE
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I', target_schema, target_user);

    -- 7. Default privileges cho object mới tạo
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, REFERENCES, TRIGGER ON TABLES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL PRIVILEGES ON SEQUENCES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO %I',
        target_schema, target_user
    );

END;
$$ LANGUAGE plpgsql;

SELECT grant_de_privileges('pos_database', 'db_engineer', 'public');
SELECT grant_de_privileges('logistic_database', 'db_engineer', 'public');
SELECT grant_de_privileges('erp_database', 'db_engineer', 'public');



-- DB Analyst: chỉ SELECT trên view

CREATE OR REPLACE FUNCTION grant_analyst_privileges(
    target_db TEXT,
    target_user TEXT,
    target_schema TEXT DEFAULT 'public'
) RETURNS void AS
$$
DECLARE
    role_exists BOOLEAN;
BEGIN
    -- 1. Tạo user nếu chưa tồn tại
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = target_user) INTO role_exists;
    IF NOT role_exists THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', target_user, 'changeme');
    END IF;

    -- 2. Database-level: CONNECT
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', target_db, target_user);

    -- 3. Schema-level: USAGE
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', target_schema, target_user);

    -- 4. Table-level: chỉ SELECT
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', target_schema, target_user);

    -- 5. Function-level: EXECUTE
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I', target_schema, target_user);

    -- 6. Default privileges cho object mới (chỉ SELECT)
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO %I',
        target_schema, target_user
    );

END;
$$ LANGUAGE plpgsql;


SELECT grant_analyst_privileges('pos_database', 'db_analyst', 'public');
SELECT grant_analyst_privileges('logistic_database', 'db_analyst', 'public');
SELECT grant_analyst_privileges('erp_database', 'db_analyst', 'public');



--------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION grant_application_privileges(
    target_db TEXT,
    target_user TEXT,
    target_schema TEXT DEFAULT 'public'
) RETURNS void AS
$$
DECLARE
    role_exists BOOLEAN;
BEGIN
    -- 1. Tạo user nếu chưa tồn tại
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = target_user) INTO role_exists;
    IF NOT role_exists THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', target_user, 'changeme');
    END IF;

    -- 2. Database-level: CONNECT
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', target_db, target_user);

    -- 3. Schema-level: USAGE
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', target_schema, target_user);

    -- 4. Table-level: SELECT, INSERT, UPDATE
    EXECUTE format('GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA %I TO %I',
                   target_schema, target_user);

    -- 5. Sequence-level: USAGE, SELECT, UPDATE
    EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA %I TO %I',
                   target_schema, target_user);

    -- 6. Function-level: EXECUTE
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I',
                   target_schema, target_user);

    -- 7. Default privileges cho object mới
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT, INSERT, UPDATE ON TABLES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I',
        target_schema, target_user
    );
    EXECUTE format(
        'ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO %I',
        target_schema, target_user
    );

END;
$$ LANGUAGE plpgsql;




-- Sale Application
SELECT grant_application_privileges('pos_database', 'sale_app', 'public');

-- Logistic Application
SELECT grant_application_privileges('logistic_database', 'logistic_app', 'public');

-- ERP Application
SELECT grant_application_privileges('erp_database', 'erp_app', 'public');



----------------------------------------------------
Select * from Customers where customer_id = 'CUST_000015'
SELECT customer_id, name, email, phone, address, created_at FROM customers where customer_id = 'CUST_000003'
SELECT update_customer('CUST_000007','John Doey', 'hdajdn@yahoo.com', '0304967890', '123 Main St, City, Country')
Select * from audit_log
