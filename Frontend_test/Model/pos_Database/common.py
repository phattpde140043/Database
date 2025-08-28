import psycopg2 as pgcon

pos_dbname="pos_database"
logistics_dbname="logistics_database"
erp_dbname="erp_database"
user="postgres"
password="Vnptdn2@"
host="localhost"
port=5432

def execute_query(dbname, user, password, host, port, sql, params=None):
    """
    Hàm thực thi query chung, trả về tất cả rows.
    
    :param dbname: tên database
    :param user: user login
    :param password: mật khẩu
    :param host: địa chỉ host
    :param port: cổng kết nối
    :param sql: câu SQL query
    :param params: tuple tham số (nếu có), mặc định None
    :return: list các rows (tuple)
    """
    try:
        conn = pgcon.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        cur = conn.cursor()
        cur.execute(sql, params)  # params cho câu lệnh có placeholder (%s)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        print("Lỗi kết nối hoặc truy vấn:", e)
        return None
