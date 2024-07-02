from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta
import os
import subprocess
import yaml
from airflow.sensors.base_sensor_operator import BaseSensorOperator
from airflow.utils.decorators import apply_defaults
from kafka import KafkaConsumer
class KafkaTopicSensor(BaseSensorOperator):
    @apply_defaults
    def __init__(self, topic, bootstrap_servers, group_id, *args, **kwargs):
        super(KafkaTopicSensor, self).__init__(*args, **kwargs)
        self.topic = topic
        self.bootstrap_servers = bootstrap_servers
        self.group_id = group_id

    def poke(self, context):
        consumer = KafkaConsumer(
            self.topic,
            bootstrap_servers=self.bootstrap_servers,
            group_id=self.group_id,
            auto_offset_reset='earliest',
            enable_auto_commit=True
        )
        
        for message in consumer:
            self.log.info(f"Received message: {message.value}")
            consumer.commit()
            return True

        return False
    
def load_config(dag_folder):
    config_file = os.path.join(dag_folder, f'<PLACEHOLDER_NAME_HERE>_configuration.yaml')
    with open(config_file, 'r') as file:
        return yaml.safe_load(file)
dag_folder = os.path.dirname(os.path.abspath(__file__))
config = load_config(dag_folder)

def run_dbt_project():
    dbt_project_dir = os.path.join(os.environ["AIRFLOW_HOME"], "dags", "<PLACEHOLDER_NAME_HERE>_dbt_project")
    
    # Path to the airflow_venv activation script
    venv_activate_script = os.path.join(os.environ["AIRFLOW_HOME"], "airflow_venv", "bin", "activate")
    
    # Command to activate the venv and run dbt
    command = f"source {venv_activate_script} && dbt run"
    
    subprocess.run(command, cwd=dbt_project_dir, shell=True, executable='/bin/bash')

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date':datetime(config['start_date_year'], config['start_month_year'], config['start_day_year']),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': config['retries'],
    'retry_delay': timedelta(minutes=config['retry_delay']),
}

dag = DAG(
    '<PLACEHOLDER_NAME_HERE>',
    default_args=default_args,
    description='A simple DBT DAG',
   schedule_interval=config['schedule_interval'],
   catchup=config.get('catchup'),
)

start = DummyOperator(
    task_id='start',
    dag=dag,
)

run_dbt = PythonOperator(
    task_id='run_dbt',
    python_callable=run_dbt_project,
    dag=dag,
)
if config.get('use_kafka_sensor') == True:
    kafka_sensor = KafkaTopicSensor(
        task_id='kafka_sensor_task',
        topic=config.get('kafka_topic'),
        bootstrap_servers=config.get('kafka_bootstrap_servers'),
        group_id=config.get('kafka_group_id'),
        poke_interval=int(config.get('kafka_poke_interval')),  # Check every 30 seconds
        timeout=int(config.get('kafka_timeout')),  # Timeout after 10 minutes
        dag=dag
    )
    start >> kafka_sensor >> run_dbt
else:   
    start >> run_dbt






# from airflow import DAG
# from airflow.operators.dummy_operator import DummyOperator
# from airflow.operators.python_operator import PythonOperator
# from datetime import datetime, timedelta
# import os
# import subprocess

# def run_dbt_project():
#     dbt_project_dir = os.path.join(os.environ["AIRFLOW_HOME"], "dags", "<PLACEHOLDER_NAME_HERE>_dbt_project")
#     subprocess.run(["dbt", "run"], cwd=dbt_project_dir)

# default_args = {
#     'owner': 'airflow',
#     'depends_on_past': False,
#     'start_date': datetime(2023, 1, 1),
#     'email_on_failure': False,
#     'email_on_retry': False,
#     'retries': 1,
#     'retry_delay': timedelta(minutes=5),
# }

# dag = DAG(
#     '<PLACEHOLDER_NAME_HERE>',
#     default_args=default_args,
#     description='A simple DBT DAG',
#     schedule_interval=timedelta(days=1),
# )

# start = DummyOperator(
#     task_id='start',
#     dag=dag,
# )

# run_dbt = PythonOperator(
#     task_id='run_dbt',
#     python_callable=run_dbt_project,
#     dag=dag,
# )

# start >> run_dbt
