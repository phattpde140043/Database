from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

# --- Default arguments ---
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['your_email@example.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=10),
}

# --- DAG ---
dag = DAG(
    'postgres_full_backup',
    default_args=default_args,
    description='Full backup PostgreSQL database weekly',
    schedule_interval='0 2 * * 0',  # 02:00 AM mỗi Chủ Nhật
    start_date=datetime(2025, 9, 7),
    catchup=False,
    tags=['backup', 'postgresql'],
)

# --- Bash command to backup ---
# Lưu ý: thay thông tin DB
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "mydatabase"
DB_USER = "myuser"
DB_PASSWORD = "mypassword"
BACKUP_DIR = "/path/to/backup/directory"

backup_cmd = f"""
export PGPASSWORD={DB_PASSWORD}
pg_dump -h {DB_HOST} -p {DB_PORT} -U {DB_USER} {DB_NAME} \
| gzip > {BACKUP_DIR}/{DB_NAME}_full_$(date +%Y%m%d).sql.gz
"""

# --- Backup task ---
backup_task = BashOperator(
    task_id='full_backup_postgres',
    bash_command=backup_cmd,
    dag=dag,
)
