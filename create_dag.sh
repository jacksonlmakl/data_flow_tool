#!/bin/bash

# create_dag.sh
DAG_NAME=$1

if [ -z "$DAG_NAME" ]; then
  echo "Usage: ./create_dag.sh <DAG_NAME>"
  exit 1
fi

# Get the current working directory
CURRENT_DIR=$(pwd)

# Set AIRFLOW_HOME to current directory
export AIRFLOW_HOME="$CURRENT_DIR/airflow_home"

# Create external DAGs folder if it doesn't exist
EXTERNAL_DAGS_DIR="$CURRENT_DIR/dags"
mkdir -p "$EXTERNAL_DAGS_DIR/$DAG_NAME/scripts"

# Copy template files to new DAG folder in the external dags directory
cp "$CURRENT_DIR/template_folder/configuration.yaml" "$EXTERNAL_DAGS_DIR/$DAG_NAME/"
cp "$CURRENT_DIR/template_folder/requirements.txt" "$EXTERNAL_DAGS_DIR/$DAG_NAME/"
cp "$CURRENT_DIR/template_folder/scripts/"* "$EXTERNAL_DAGS_DIR/$DAG_NAME/scripts/"

# Replace placeholder name in configuration.yaml with the DAG name
sed -i "s/<PLACEHOLDER_NAME_HERE>/$DAG_NAME/g" "$EXTERNAL_DAGS_DIR/$DAG_NAME/configuration.yaml"
sed -i "s/name: \".*\"/name: \"$DAG_NAME\"/" "$EXTERNAL_DAGS_DIR/$DAG_NAME/configuration.yaml"

# Copy the template DAG to the external DAG folder
cp "$CURRENT_DIR/template_dag.py" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py"

# Create a symbolic link in the AIRFLOW_HOME/dags directory
ln -s "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py" "$AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"

echo "DAG $DAG_NAME created successfully in $EXTERNAL_DAGS_DIR/$DAG_NAME"
echo "Symbolic link created in $AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"

# Activate the DAG by setting 'is_paused' to 'False'
source "$CURRENT_DIR/airflow_venv/bin/activate"

# Set environment variable to silence warnings
export SQLALCHEMY_SILENCE_UBER_WARNING=1

# List the DAGs to ensure the new DAG is registered
airflow dags list

# Unpause the DAG
airflow dags unpause "$DAG_NAME"
echo "DAG $DAG_NAME activated."
