# template_dag.py
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
import yaml
import os
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

def create_task(dag_folder, task_name):
    def task_function(**kwargs):
        script_path = os.path.join(dag_folder, '<PLACEHOLDER_NAME_HERE>_scripts', task_name)
        exec(open(script_path).read())
    return task_function

dag_folder = os.path.dirname(os.path.abspath(__file__))
config = load_config(dag_folder)


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': config['retries'],
    'retry_delay': timedelta(minutes=config['retry_delay']),
}

dag = DAG(
    config['name'],
    default_args=default_args,
    description='A simple tutorial DAG',
    schedule_interval=config['schedule_interval'],
    start_date=datetime(config['start_date_year'], config['start_month_year'], config['start_day_year']),
    catchup=False,
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



previous_task = None
count=0
for script in config['python_scripts']:
    task = PythonOperator(
        task_id=script.split('.')[0],
        python_callable=create_task(dag_folder, script),
        dag=dag,
    )
    if previous_task and count == 0 and config.get('use_kafka_sensor') == True:
        kafka_sensor >> previous_task >> task
    elif previous_task:
        previous_task >> task
    previous_task = task
    count +=1


