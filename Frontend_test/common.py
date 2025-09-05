import psycopg2 as pgcon

pos_dbname="pos_database"
logistics_dbname="logistic_database"
erp_dbname="erp_database"
user="postgres"
password="Vnptdn2@"
host="localhost"
port=5432

def execute_query(dbname, user, password, host, port, sql, params=None):
    try:
        conn = pgcon.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        cur = conn.cursor()
        print(f"[SQL] {sql} | Params: {params}")  # log câu query

        cur.execute(sql, params)
        print(f"[DEBUG] Rowcount sau execute: {cur.rowcount}")

        try:
            rows = cur.fetchall()
            print(f"[DEBUG] Fetchall: {rows}")
        except Exception:
            rows = None
            print("[DEBUG] Không có kết quả để fetch.")

        conn.commit()
        print("[DEBUG] Commit thành công ✅")

        cur.close()
        conn.close()
        return rows

    except Exception as e:
        print("Lỗi kết nối hoặc truy vấn:", e)
        try:
            conn.rollback()
            print("[DEBUG] Rollback do lỗi ❌")
        except:
            pass
        return None

