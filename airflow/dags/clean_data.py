from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from airflow.utils.trigger_rule import TriggerRule

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

def execute_query(conn_id,query):
    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchone()
    print(result)
    cursor.close()
    conn.commit()
    conn.close()


def clean_order_items():
    conn_id ="pos_conn"
    query = "select delete_old_order_items() ;"
    execute_query(conn_id,query)

def clean_orders():
    conn_id ="pos_conn"
    query = "select delete_old_orders_without_items() ;"
    execute_query(conn_id,query)

def clean_sku():
    conn_id ="pos_conn"
    query = "select cleanup_soft_deleted_skus() ;"
    execute_query(conn_id,query)

def clean_products():
    conn_id ="pos_conn"
    query = "select cleanup_soft_deleted_products() ;"
    execute_query(conn_id,query)

def clean_categories():
    conn_id ="pos_conn"
    query = "select cleanup_soft_deleted_categories() ;"
    execute_query(conn_id,query)

def clean_old_delivery_tracking():
    conn_id ="logistic_conn"
    query = "select cleanup_old_delivery_tracking() ;"
    execute_query(conn_id,query)

def clean_old_shipments():
    conn_id ="logistic_conn"
    query = "select cleanup_old_shipments() ;"
    execute_query(conn_id,query)

def clean_old_warehouses():
    conn_id ="erp_conn"
    query = "select cleanup_old_warehouses() ;"
    execute_query(conn_id,query)

def clean_old_purchase_order_items():
    conn_id ="erp_conn"
    query = "SELECT cleanup_old_purchase_order_items();"
    execute_query(conn_id,query)

def clean_old_purchase_orders():
    conn_id ="erp_conn"
    query = "SELECT cleanup_old_purchase_orders();"
    execute_query(conn_id,query)

def clean_old_suppliers():
    conn_id ="erp_conn"
    query = "SELECT cleanup_old_suppliers();"
    execute_query(conn_id,query)

def clean_old_financial_transactions():
    conn_id ="erp_conn"
    query = "SELECT cleanup_old_financial_transactions();"
    execute_query(conn_id,query)

def clean_old_employees():
    conn_id ="erp_conn"
    query = "SELECT cleanup_old_employees();"
    execute_query(conn_id,query)


with DAG(
    dag_id='clean_data',
    default_args=default_args,
    description='clean data out of retention',
    schedule_interval='0 1 * * *',  # 1:00 AM hàng ngày
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['sql', 'clean data'],
) as dag:
    t1 = PythonOperator(
        task_id="clean_order_items",
        python_callable=clean_order_items
    )

    t2 = PythonOperator(
        task_id="clean_orders",
        python_callable=clean_orders,
        trigger_rule=TriggerRule.ALL_DONE
    )

    t3 = PythonOperator(
        task_id="clean_sku",
        python_callable=clean_sku,
        trigger_rule=TriggerRule.ALL_DONE
    )

    t4 = PythonOperator(
        task_id="clean_products",
        python_callable=clean_products,
        trigger_rule=TriggerRule.ALL_DONE
    )

    t5 = PythonOperator(
        task_id="clean_categories",
        python_callable=clean_categories,
        trigger_rule=TriggerRule.ALL_DONE
    )  

    t6 = PythonOperator(
        task_id="clean_old_delivery_tracking",
        python_callable=clean_old_delivery_tracking,
        trigger_rule=TriggerRule.ALL_DONE
    )

    t7 = PythonOperator(
        task_id="clean_old_shipments",
        python_callable=clean_old_shipments,
        trigger_rule=TriggerRule.ALL_DONE
    )  

    t8 = PythonOperator(
        task_id="clean_old_purchase_order_items",
        python_callable=clean_old_purchase_order_items,
        trigger_rule=TriggerRule.ALL_DONE
    )      

    t9 = PythonOperator(
        task_id="clean_old_purchase_orders",
        python_callable=clean_old_purchase_orders,
        trigger_rule=TriggerRule.ALL_DONE
    )  

    t10 = PythonOperator(
        task_id="clean_old_suppliers",
        python_callable=clean_old_suppliers,
        trigger_rule=TriggerRule.ALL_DONE
    )  

    t11 = PythonOperator(
        task_id="clean_old_financial_transactions",
        python_callable=clean_old_financial_transactions,
        trigger_rule=TriggerRule.ALL_DONE
    )  

    t12 = PythonOperator(
        task_id="clean_old_employees",
        python_callable=clean_old_employees,
        trigger_rule=TriggerRule.ALL_DONE
    )  


    t1>>t2>>t3>>t4>>t5>>t6>>t7>>t8>>t9>>t10>>t11>>t12