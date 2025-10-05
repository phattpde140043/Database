from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

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

# --- Configuration for backup ---
DB_HOST = "host.docker.internal"
DB_PORT = "5432"
POS_DB_NAME = "pos_database"
LOGISTIC_DB_NAME = "logistic_database"
ERP_DB_NAME = "erp_database"
DB_USER = "postgres"
DB_PASSWORD = "Vnptdn2@"
BACKUP_DIR = "/backups/postgres"

# --- Commands ---
create_dir_cmd = f"""
mkdir -p "{BACKUP_DIR}" 2>/tmp/mkdir_error.log || {{ echo "ERROR: Failed to create {BACKUP_DIR}" >&2; cat /tmp/mkdir_error.log >&2; exit 1; }}
if [ -d "{BACKUP_DIR}" ] && [ -w "{BACKUP_DIR}" ]; then
    echo "{BACKUP_DIR} is ready"
else
    echo "ERROR: {BACKUP_DIR} is not writable" >&2
fi
"""

backup_pos_db_cmd = f"""
echo "Backing up {POS_DB_NAME} at $(date)"
export PGPASSWORD={DB_PASSWORD}
psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {POS_DB_NAME} -c 'SELECT 1' 2>/tmp/psql_error.log || {{ echo "ERROR: Failed to connect to {POS_DB_NAME}" >&2; cat /tmp/psql_error.log >&2; exit 1; }}
pg_dump -h {DB_HOST} -p {DB_PORT} -U {DB_USER} --no-sync {POS_DB_NAME} > {BACKUP_DIR}/{POS_DB_NAME}_full_$(date +%Y%m%d).sql 2>/tmp/pg_dump_error.log
pg_dump_status=$?
if [ $pg_dump_status -eq 0 ] && [ -s "{BACKUP_DIR}/{POS_DB_NAME}_full_$(date +%Y%m%d).sql" ]; then
    echo "Backup completed successfully"
else
    echo "ERROR: Backup failed or file is empty" >&2
    cat /tmp/pg_dump_error.log >&2
fi
"""

backup_logistic_db_cmd = f"""
echo "Backing up {LOGISTIC_DB_NAME} at $(date)"
export PGPASSWORD={DB_PASSWORD}
psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {LOGISTIC_DB_NAME} -c 'SELECT 1' 2>/tmp/psql_error.log || {{ echo "ERROR: Failed to connect to {LOGISTIC_DB_NAME}" >&2; cat /tmp/psql_error.log >&2; exit 1; }}
pg_dump -h {DB_HOST} -p {DB_PORT} -U {DB_USER} --no-sync {LOGISTIC_DB_NAME} > {BACKUP_DIR}/{LOGISTIC_DB_NAME}_full_$(date +%Y%m%d).sql 2>/tmp/pg_dump_error.log
pg_dump_status=$?
if [ $pg_dump_status -eq 0 ] && [ -s "{BACKUP_DIR}/{LOGISTIC_DB_NAME}_full_$(date +%Y%m%d).sql" ]; then
    echo "Backup completed successfully"
else
    echo "ERROR: Backup failed or file is empty" >&2
    cat /tmp/pg_dump_error.log >&2
fi
"""

backup_erp_db_cmd = f"""
echo "Backing up {ERP_DB_NAME} at $(date)"
export PGPASSWORD={DB_PASSWORD}
psql -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -d {ERP_DB_NAME} -c 'SELECT 1' 2>/tmp/psql_error.log || {{ echo "ERROR: Failed to connect to {ERP_DB_NAME}" >&2; cat /tmp/psql_error.log >&2; exit 1; }}
pg_dump -h {DB_HOST} -p {DB_PORT} -U {DB_USER} --no-sync {ERP_DB_NAME} > {BACKUP_DIR}/{ERP_DB_NAME}_full_$(date +%Y%m%d).sql 2>/tmp/pg_dump_error.log
pg_dump_status=$?
if [ $pg_dump_status -eq 0 ] && [ -s "{BACKUP_DIR}/{ERP_DB_NAME}_full_$(date +%Y%m%d).sql" ]; then
    echo "Backup completed successfully"
else
    echo "ERROR: Backup failed or file is empty" >&2
    cat /tmp/pg_dump_error.log >&2
fi
"""


# --- Define DAG ---
with DAG(
    'postgres_full_backup',
    default_args=default_args,
    description='Full backup PostgreSQL database weekly',
    schedule_interval='0 2 * * 0',  # 2:00 AM Sunday
    start_date=datetime(2025, 9, 5),
    catchup=False,
    tags=['backup', 'postgresql'],
) as dag:
    create_dir_task = BashOperator(
        task_id='create_backup_dir',
        bash_command=create_dir_cmd,
    )

    backup_pos_db_task = BashOperator(
        task_id='backup_pos_database',
        bash_command=backup_pos_db_cmd,
    )

    backup_logistic_db_task = BashOperator(
        task_id='backup_logistic_database',
        bash_command=backup_logistic_db_cmd,
    )

    backup_erp_db_task = BashOperator(
        task_id='backup_erp_database',
        bash_command=backup_erp_db_cmd,
    )


    create_dir_task >> backup_pos_db_task >> backup_logistic_db_task >> backup_erp_db_task 