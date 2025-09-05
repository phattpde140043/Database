from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['your_email@example.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=10),
}

dag = DAG(
    'postgres_incremental_backup',
    default_args=default_args,
    description='Incremental backup PostgreSQL using WAL',
    schedule_interval='0 2 * * *',  # mỗi ngày lúc 02:00 AM
    start_date=datetime(2025, 9, 7),
    catchup=False,
    tags=['backup', 'postgresql'],
)

# --- Config ---
DB_WAL_DIR = "/var/lib/postgresql/data/pg_wal"  # đường dẫn WAL
BACKUP_DIR = "/path/to/incremental_backup"

# --- Task: backup WAL files ---
incremental_backup_cmd = f"""
rsync -av --ignore-existing {DB_WAL_DIR}/ {BACKUP_DIR}/
"""

incremental_backup_task = BashOperator(
    task_id='incremental_backup_wal',
    bash_command=incremental_backup_cmd,
    dag=dag,
)
