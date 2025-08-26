--------------------------------------------------------------------------------
--                               Phân quyền

-- 1. Tạo các ROLE chính
CREATE ROLE db_admin;
CREATE ROLE db_engineer;
CREATE ROLE db_analyst;
CREATE ROLE sale_app;
CREATE ROLE logistic_app;
CREATE ROLE erp_app;

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
GRANT ALL PRIVILEGES ON DATABASE pos_database TO db_admin;
GRANT ALL PRIVILEGES ON DATABASE logistic_database TO db_admin;
GRANT ALL PRIVILEGES ON DATABASE erp_database TO db_admin;




GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pos TO db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA logistic TO db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA erp TO db_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA pos, logistic, erp GRANT ALL PRIVILEGES ON TABLES TO db_admin;

-- DB Engineer: chỉ DML, không DELETE
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA pos TO db_engineer;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA logistic TO db_engineer;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA erp TO db_engineer;
ALTER DEFAULT PRIVILEGES IN SCHEMA pos, logistic, erp GRANT SELECT, INSERT, UPDATE ON TABLES TO db_engineer;

-- DB Analyst: chỉ SELECT trên view
GRANT USAGE ON SCHEMA pos TO db_analyst;
GRANT USAGE ON SCHEMA logistic TO db_analyst;
GRANT USAGE ON SCHEMA erp TO db_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA pos TO db_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA logistic TO db_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA erp TO db_analyst;

-- Sale Application
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA pos TO sale_app;

-- Logistic Application
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA logistic TO logistic_app;

-- ERP Application
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA erp TO erp_app;

-- Role cho bảng chứa PII
GRANT SELECT ON ALL TABLES IN SCHEMA pii TO pii_role;

-- Role cho view nghiệp vụ
GRANT SELECT ON ALL TABLES IN SCHEMA biz_view TO biz_view_role;

----------------------------------------------------
-- 4. Đảm bảo không có role ngoài dự án được truy cập
----------------------------------------------------
-- Thu hồi tất cả quyền còn sót
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA pos FROM PUBLIC;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA logistic FROM PUBLIC;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA erp FROM PUBLIC;
