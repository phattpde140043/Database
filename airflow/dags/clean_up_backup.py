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

INCREMENTAL_BACKUP_DIR = "/path/to/incremental_backup"
FULL_BACKUP_DIR = "/backups/postgres"

# --- Task: Check Incremental Backup directory ---
check_incremental_dir_cmd = f"""
if [ ! -d "{INCREMENTAL_BACKUP_DIR}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Incremental backup directory does not exist"
    exit 1
elif [ ! -r "{INCREMENTAL_BACKUP_DIR}" ] || [ ! -w "{INCREMENTAL_BACKUP_DIR}" ] || [ ! -x "{INCREMENTAL_BACKUP_DIR}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Incremental backup directory lacks read/write/execute permissions"
    exit 1
fi
"""

# --- Task: Check Full Backup directory ---
check_full_dir_cmd = f"""
if [ ! -d "{FULL_BACKUP_DIR}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Full backup directory does not exist"
    exit 1
elif [ ! -r "{FULL_BACKUP_DIR}" ] || [ ! -w "{FULL_BACKUP_DIR}" ] || [ ! -x "{FULL_BACKUP_DIR}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Full backup directory lacks read/write/execute permissions"
    exit 1
fi
"""

# --- Task: Clean up old Incremental Backup files ---
cleanup_incremental_cmd = f"""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting cleanup of old incremental backup files"
find {INCREMENTAL_BACKUP_DIR}/ -type f -mtime +30 -delete
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup of old incremental backup files completed successfully"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup of old incremental backup files failed"
    exit 1
fi
"""

# --- Task: Clean up old Full Backup files ---
cleanup_full_cmd = f"""
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting cleanup of old full backup files"
find {FULL_BACKUP_DIR}/ -type f -mtime +30 -delete
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup of old full backup files completed successfully"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup of old full backup files failed"
    exit 1
fi
"""

with DAG(
    'cleanup_backup_history',
    default_args=default_args,
    description='clean backup history over retention',
    schedule_interval='0 3 * * *',  # mỗi ngày lúc 03:00 AM
    start_date=datetime(2025, 9, 7),
    catchup=False,
    tags=['backup', 'postgresql']
) as dag:
    
    check_incremental_dir_task = BashOperator(
        task_id='check_incremental_dir',
        bash_command=check_incremental_dir_cmd
    )
    
    check_full_dir_task = BashOperator(
        task_id='check_full_dir',
        bash_command=check_full_dir_cmd
    )

    cleanup_incremental_task = BashOperator(
        task_id='cleanup_old_incremental_files',
        bash_command=cleanup_incremental_cmd
    )
    
    cleanup_full_task = BashOperator(
        task_id='cleanup_old_full_files',
        bash_command=cleanup_full_cmd
    )

    check_incremental_dir_task >> cleanup_incremental_task >> check_full_dir_task >> cleanup_full_task