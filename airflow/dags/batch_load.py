from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime, timedelta
import pandas as pd
import psycopg2
from sqlalchemy import create_engine
import os
import pyarrow

storage_dir = '/storage'

# --- Default arguments ---
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['phattp1912@gmail.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=10),
}

def execute_query(conn_id,query,columns):
    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    conn.commit()
    conn.close()
    df = pd.DataFrame(results, columns=columns)
    return df

def save_file_parquet(df, file_path):
    try:
        if not isinstance(df, pd.DataFrame):
            print("Lỗi: Đối tượng đầu vào không phải là DataFrame.")
            
        if df.empty:
            print("DataFrame rỗng, không có dữ liệu để lưu vào file Parquet.")
            return False
        
        print(f"Kích thước DataFrame: {df.shape}")
        print(f"Các cột và kiểu dữ liệu:\n{df.dtypes}")
        
        try:
            print(f"Phiên bản pyarrow: {pyarrow.__version__}")
        except ImportError:
            print("Lỗi: Thư viện pyarrow không được cài đặt.")
            
        
        directory = os.path.dirname(file_path)
        if directory:
            print(f"Kiểm tra và tạo thư mục: {directory}")
            os.makedirs(directory, exist_ok=True)
            if not os.access(directory, os.W_OK):
                print(f"Lỗi: Không có quyền ghi vào thư mục {directory}")
                
        print(f"Đang lưu DataFrame vào file Parquet tại: {file_path}")
        df.to_parquet(file_path, index=False, engine='pyarrow')
        print(f"Lưu file Parquet thành công tại: {file_path}")
        
        return True
    
        
    except ImportError as ie:
        print(f"Lỗi thư viện: {str(ie)}")
        
    except pd.errors.PyArrowError as pae:
        print(f"Lỗi pyarrow khi lưu file Parquet: {str(pae)}")
        
    except OSError as ose:
        print(f"Lỗi hệ thống file: {str(ose)}")
        
    except Exception as e:
        print(f"Lỗi không xác định khi lưu file Parquet: {str(e)}")



def get_account_data():
    conn_id ="erp_conn"
    query = "select account_id, account_name, account_type,updated_at from accounts;"
    columns = ['account_id', 'account_name', 'account_type', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/account/account_{current_date}.parquet')

def get_categories_data():
    conn_id ="pos_conn"
    query = "select category_id,name,created_at,deleted_at,updated_at from categories ;"
    columns = ['category_id', 'name', 'created_at', 'deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/category/category_{current_date}.parquet')

def get_department_data():
    conn_id ="erp_conn"
    query = "select department_id,name,updated_at from departments ;"
    columns = ['department_id', 'name', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/department/department_{current_date}.parquet')

def get_employee_data():
    conn_id ="erp_conn"
    query = "select employee_id,name,email,department_id,hire_date,salary,deleted_at,updated_at from employees ;"
    columns = ['employee_id', 'name', 'email', 'department_id', 'hire_date', 'salary', 'deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/employee/employee_{current_date}.parquet')

def get_payment_type_data():
    conn_id ="pos_conn"
    query = "select payment_type_id, name, updated_at from payment_types ;"
    columns = ['payment_type_id', 'name', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/payment_type/payment_type_{current_date}.parquet')

def get_product_data():
    conn_id ="pos_conn"
    query = "select product_id,name,category_id,created_at,deleted_at,updated_at from products ;"
    columns = ['product_id', 'name', 'category_id', 'created_at', 'deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/product/product_{current_date}.parquet')

def get_product_sku_data():
    conn_id ="pos_conn"
    query = "select sku_id,sku,product_id,color,size,price,created_at,deleted_at,updated_at from products_sku ;"
    columns = ['sku_id', 'sku', 'product_id', 'color', 'size','price', 'created_at', 'deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/product_sku/product_sku_{current_date}.parquet')

def get_supplier_data():
    conn_id ="erp_conn"
    query = "select supplier_id,name,contact_name,email,phone,created_at,deleted_at,updated_at from suppliers ;"
    columns = ['supplier_id', 'name', 'contact_name', 'email', 'phone', 'created_at','deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/supplier/supplier_{current_date}.parquet')

def get_warehouse_data():
    conn_id ="logistic_conn"
    query = "select warehouse_id,name,location,created_at,deleted_at,updated_at from warehouses ;"
    columns = ['warehouse_id', 'name', 'location', 'created_at', 'deleted_at', 'updated_at']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/warehouse/warehouse_{current_date}.parquet')

def get_pos_logging_data():
    conn_id ="pos_conn"
    query = "select log_id,log_time,user_name,action_type,object_type,object_name,query from audit_log ;"
    columns = ['log_id', 'log_time', 'user_name', 'action_type', 'object_type', 'object_name','query']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/pos_logging/pos_logging_{current_date}.parquet')

def get_erp_logging_data():
    conn_id ="erp_conn"
    query = "select log_id,log_time,user_name,action_type,object_type,object_name,query from audit_log ;"
    columns = ['log_id', 'log_time', 'user_name', 'action_type', 'object_type', 'object_name','query']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/erp_logging/erp_logging_{current_date}.parquet')

def get_logistic_logging_data():
    conn_id ="logistic_conn"
    query = "select log_id,log_time,user_name,action_type,object_type,object_name,query from audit_log ;"
    columns = ['log_id', 'log_time', 'user_name', 'action_type', 'object_type', 'object_name','query']
    df = execute_query(conn_id,query,columns=columns)
    current_date = datetime.now().strftime("%Y%m%d")
    save_file_parquet(df,storage_dir+f'/logistic_logging/logistic_logging_{current_date}.parquet')

with DAG(
    dag_id='batch_load',
    default_args=default_args,
    description='batch load data from Postgres to S3',
    schedule_interval='0 1 * * *',  # 1:00 AM hàng ngày
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['sql', 'batch load'],
) as dag:
    
    load_account = PythonOperator(
        task_id="get_account_data",
        python_callable=get_account_data
    )

    load_categories = PythonOperator(
        task_id="get_categories_data",
        python_callable=get_categories_data
    )

    load_department = PythonOperator(
        task_id="get_department_data",
        python_callable=get_department_data
    )

    load_employee = PythonOperator(
        task_id="get_employee_data",
        python_callable=get_employee_data
    )

    load_payment_type = PythonOperator(
        task_id="get_payment_type_data",
        python_callable=get_payment_type_data
    )

    load_product = PythonOperator(
        task_id="get_product_data",
        python_callable=get_product_data
    )

    load_product_sku = PythonOperator(
        task_id="get_product_sku_data",
        python_callable=get_product_sku_data
    )

    load_supplier = PythonOperator(
        task_id="get_supplier_data",
        python_callable=get_supplier_data
    )

    load_warehouse = PythonOperator(
        task_id="get_warehouse_data",
        python_callable=get_warehouse_data
    )

    load_pos_logging = PythonOperator(
        task_id="get_pos_logging_data",
        python_callable=get_pos_logging_data
    )

    load_erp_logging = PythonOperator(
        task_id="get_erp_logging_data",
        python_callable=get_erp_logging_data
    )

    load_logistic_logging = PythonOperator(
        task_id="get_logistic_logging_data",
        python_callable=get_logistic_logging_data
    )

    load_account >> load_categories >> load_department >> load_employee >> load_payment_type >> load_product >> load_product_sku >> load_supplier >> load_warehouse >> load_pos_logging >> load_erp_logging >> load_logistic_logging

