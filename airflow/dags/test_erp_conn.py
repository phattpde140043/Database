from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from datetime import datetime

def test_conn():
    hook = PostgresHook(postgres_conn_id="erp_conn")
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT 1;")
    print("✅ PostgreSQL connection OK")
    cursor.close()
    conn.close()

with DAG(
    dag_id="test_erp_conn",
    start_date=datetime(2025, 9, 1),
    schedule_interval=None,
    catchup=False,
) as dag:
    t1 = PythonOperator(
        task_id="test_connection",
        python_callable=test_conn
    )
