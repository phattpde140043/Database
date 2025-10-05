from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator

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

    # Task 1: Tính tháng và năm
def compute_next_month(**kwargs):
    now = datetime.today()
    year = now.year
    month = now.month
    if month == 12:
        next_month = 1
        next_year = year + 1
    else:
        next_month = month + 1
        next_year = year
    # Truyền dữ liệu qua XCom
    return {'year': next_year, 'month': next_month}


# Task 2: Tạo partition dựa trên tham số nhận từ Task 1
def create_partition_for_purchase_orders(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="erp_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('purchase_orders', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close()


def create_partition_for_purchase_order_items(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="erp_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('purchase_order_items', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close() 

def create_partition_for_financial_transactions(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="erp_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('financial_transactions', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close()    

def create_partition_for_delivery_tracking(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="logistic_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('delivery_tracking', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close() 

def create_partition_for_shipments(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="logistic_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('shipments', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close() 

def create_partition_for_orders(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="pos_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('orders', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close() 

def create_partition_for_order_items(**kwargs):
    ti = kwargs['ti']
    params = ti.xcom_pull(task_ids='compute_next_month')
    year = params['year']
    month = params['month']
    hook = PostgresHook(postgres_conn_id="pos_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT create_monthly_partition(%s, %s, %s);",
        ('order_items', year, month)
    )
    result = cursor.fetchone()
    print(f"📌 Partition created for {year}-{month}: {result[0] if result else None}")

    cursor.close()
    conn.commit()
    conn.close() 


# --- Define DAG ---
with DAG(
    dag_id='monthly_create_partition',
    default_args=default_args,
    description='Run SQL function yo create partition at 2:00 AM on the 1st of each month',
    schedule_interval='0 22 28 * *',  # 10:00 PM ngày 28 mỗi tháng
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['sql', 'monthly'],
) as dag:

    task_compute_month = PythonOperator(
        task_id='compute_next_month',
        python_callable=compute_next_month,
        provide_context=True
    )

    task_create_partition_1 = PythonOperator(
        task_id='create_partition_for_purchase_orders',
        python_callable=create_partition_for_purchase_orders,
        provide_context=True
    )

    task_create_partition_2 = PythonOperator(
        task_id='create_partition_for_purchase_order_items',
        python_callable=create_partition_for_purchase_order_items,
        provide_context=True
    )

    task_create_partition_3 = PythonOperator(
        task_id='create_partition_for_financial_transactions',
        python_callable=create_partition_for_financial_transactions,
        provide_context=True
    )

    task_create_partition_4 = PythonOperator(
        task_id='create_partition_for_delivery_tracking',
        python_callable=create_partition_for_delivery_tracking,
        provide_context=True
    )

    task_create_partition_5 = PythonOperator(
        task_id='create_partition_for_shipments',
        python_callable=create_partition_for_shipments,
        provide_context=True
    )

    task_create_partition_6 = PythonOperator(
        task_id='create_partition_for_orders',
        python_callable=create_partition_for_orders,
        provide_context=True
    )

    task_create_partition_7 = PythonOperator(
        task_id='create_partition_for_order_items',
        python_callable=create_partition_for_order_items,
        provide_context=True
    )    

    # Thiết lập thứ tự task
    task_compute_month >> task_create_partition_1 >> task_create_partition_2>> task_create_partition_3>> task_create_partition_4>> task_create_partition_5>> task_create_partition_6>> task_create_partition_7