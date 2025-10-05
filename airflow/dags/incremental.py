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

# --- Config ---
DB_WAL_DIR = "/postgresql/data/pg_wal"  # đường dẫn WAL
BACKUP_DIR = "/path/to/incremental_backup"

# --- Task: Check WAL directory ---
check_wal_dir_cmd = f"""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking WAL directory: {DB_WAL_DIR}"
if [ -d "{DB_WAL_DIR}" ]; then
    if [ -r "{DB_WAL_DIR}" ] && [ -x "{DB_WAL_DIR}" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WAL directory exists and is readable/executable"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WAL directory exists but lacks read/execute permissions"
        
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WAL directory does not exist"
    
fi
"""

# --- Task: Check Backup directory ---
check_backup_dir_cmd = f"""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking Backup directory: {BACKUP_DIR}"
if [ -d "{BACKUP_DIR}" ]; then
    if [ -w "{BACKUP_DIR}" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup directory exists and is writable"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup directory exists but lacks write permissions"
        
    fi
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup directory does not exist, creating it"
    mkdir -p "{BACKUP_DIR}"
    if [ $? -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup directory created successfully"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to create Backup directory"
        
    fi
fi
"""

# --- Task: Backup WAL files ---
incremental_backup_cmd = f"""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting WAL backup"
echo "User and group details: $(id)"
rsync -av --no-times --ignore-existing {DB_WAL_DIR}/ {BACKUP_DIR}/
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WAL backup completed successfully"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WAL backup failed"
    exit 1
fi
"""



with DAG(
    'postgres_incremental_backup',
    default_args=default_args,
    description='Incremental backup PostgreSQL using WAL',
    schedule_interval='0 2 * * *',  # mỗi ngày lúc 02:00 AM
    start_date=datetime(2025, 9, 7),
    catchup=False,
    tags=['backup', 'postgresql']
) as dag:
    
    check_wal_dir_task = BashOperator(
    task_id='check_wal_dir',
    bash_command=check_wal_dir_cmd
    ),

    check_backup_dir_task = BashOperator(
    task_id='check_backup_dir',
    bash_command=check_backup_dir_cmd
    ),
    
    incremental_backup_task = BashOperator(
    task_id='incremental_backup_wal',
    bash_command=incremental_backup_cmd
    )
    check_wal_dir_task >> incremental_backup_task
