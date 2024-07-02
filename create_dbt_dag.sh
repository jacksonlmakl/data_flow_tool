#!/bin/bash

# create_dbt_dag.sh
DAG_NAME=$1

if [ -z "$DAG_NAME" ]; then
  echo "Usage: ./create_dbt_dag.sh <DAG_NAME>"
  exit 1
fi

# Get the current working directory
CURRENT_DIR=$(pwd)

# Set AIRFLOW_HOME to current directory
export AIRFLOW_HOME="$CURRENT_DIR/airflow_home"

# Activate the Airflow virtual environment
source "$AIRFLOW_HOME/airflow_venv/bin/activate"

# Create external DAGs folder if it doesn't exist
EXTERNAL_DAGS_DIR="$CURRENT_DIR/dags"
mkdir -p "$EXTERNAL_DAGS_DIR/$DAG_NAME"

# Create DBT project structure
DBT_PROJECT_DIR="$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project"

mkdir -p "$DBT_PROJECT_DIR/models"
mkdir -p "$DBT_PROJECT_DIR/models/staging"
mkdir -p "$DBT_PROJECT_DIR/models/marts"
mkdir -p "$DBT_PROJECT_DIR/models/sources"
mkdir -p "$DBT_PROJECT_DIR/seeds"
# mkdir -p "$DBT_PROJECT_DIR/snapshots"
mkdir -p "$DBT_PROJECT_DIR/macros"
# mkdir -p "$DBT_PROJECT_DIR/analyses"
mkdir -p "$DBT_PROJECT_DIR/tests"
mkdir -p "$DBT_PROJECT_DIR/docs"

# Copy template files to new DBT project folder
cp "$CURRENT_DIR/template_dbt/dbt_project.yml" "$DBT_PROJECT_DIR/dbt_project.yml"
cp "$CURRENT_DIR/template_dbt/profiles.yml" "$DBT_PROJECT_DIR/profiles.yml"
cp "$CURRENT_DIR/template_dbt/models" "$DBT_PROJECT_DIR/models"
# cp "$CURRENT_DIR/template_dbt/models/marts/dim_customers.sql" "$DBT_PROJECT_DIR/models/marts/dim_customers.sql"
cp "$CURRENT_DIR/template_dbt/models/marts/core_pokemon.sql" "$DBT_PROJECT_DIR/models/marts/core_pokemon.sql"
cp "$CURRENT_DIR/template_dbt/models/staging/stg_pokemon.sql" "$DBT_PROJECT_DIR/models/staging/stg_pokemon.sql"
cp "$CURRENT_DIR/template_dbt/models/sources/pokemon.yml" "$DBT_PROJECT_DIR/models/sources/pokemon.yml"

cp "$CURRENT_DIR/template_dbt/seeds/my_seed_data.csv" "$DBT_PROJECT_DIR/seeds/my_seed_data.csv"
# cp "$CURRENT_DIR/template_dbt/snapshots/snapshot_orders.sql" "$DBT_PROJECT_DIR/snapshots/snapshot_orders.sql"
cp "$CURRENT_DIR/template_dbt/macros/my_custom_macro.sql" "$DBT_PROJECT_DIR/macros/my_custom_macro.sql"
# cp "$CURRENT_DIR/template_dbt/analyses/my_analysis.sql" "$DBT_PROJECT_DIR/analyses/my_analysis.sql"
cp "$CURRENT_DIR/template_dbt/tests/my_test.sql" "$DBT_PROJECT_DIR/tests/my_test.sql"
cp "$CURRENT_DIR/template_dbt/docs/my_documentation.md" "$DBT_PROJECT_DIR/docs/my_documentation.md"
cp "$CURRENT_DIR/template_dbt/requirements.txt" "$EXTERNAL_DAGS_DIR/$DAG_NAME/requirements.txt"
ln "$EXTERNAL_DAGS_DIR/$DAG_NAME/requirements.txt" "$AIRFLOW_HOME/dags/requirements.txt"

# Replace placeholder name in dbt_project.yml with the DAG name
sed -i "s/<PLACEHOLDER_NAME_HERE>/$DAG_NAME/g" "$DBT_PROJECT_DIR/dbt_project.yml"

# Copy the template DAG to the external DAG folder
cp "$CURRENT_DIR/template_dbt/configuration.yaml" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_configuration.yaml"

cp "$CURRENT_DIR/template_dbt/template_dbt_dag.py" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py"

sed -i "s/<PLACEHOLDER_NAME_HERE>/$DAG_NAME/g" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py"
# Create a symbolic link in the AIRFLOW_HOME/dags directory
ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py" "$AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"
ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_configuration.yaml" "$AIRFLOW_HOME/dags/${DAG_NAME}_configuration.yaml"


# mkdir "$AIRFLOW_HOME/dags/${DAG_NAME}"

# cp -r "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project/" "$AIRFLOW_HOME/dags/${DAG_NAME}_dbt_project/"
ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project" "$AIRFLOW_HOME/dags/${DAG_NAME}_dbt_project"

# rm -rf "$AIRFLOW_HOME/dags/${DAG_NAME}_dbt_project"/${DAG_NAME}_dag.py

echo "DBT DAG $DAG_NAME created successfully in $EXTERNAL_DAGS_DIR/$DAG_NAME"
echo "Symbolic link created in $AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"

# Check if the symbolic link was created correctly
if [ -L "$AIRFLOW_HOME/dags/${DAG_NAME}_dag.py" ]; then
  echo "Symbolic link verified."
else
  echo "Symbolic link creation failed."
fi

# Activate the DAG by setting 'is_paused' to 'False'

# Set environment variable to silence warnings
export SQLALCHEMY_SILENCE_UBER_WARNING=1

# List the DAGs to ensure the new DAG is registered
airflow dags list

# Unpause the DAG
airflow dags unpause "$DAG_NAME"
echo "DAG $DAG_NAME activated."


#!/bin/bash

# # create_dbt_dag.sh
# DAG_NAME=$1

# if [ -z "$DAG_NAME" ]; then
#   echo "Usage: ./create_dbt_dag.sh <DAG_NAME>"
#   exit 1
# fi

# # Get the current working directory
# CURRENT_DIR=$(pwd)

# # Set AIRFLOW_HOME to current directory
# export AIRFLOW_HOME="$CURRENT_DIR/airflow_home"

# # Activate the Airflow virtual environment
# source "$CURRENT_DIR/airflow_venv/bin/activate"

# # Create external DAGs folder if it doesn't exist
# EXTERNAL_DAGS_DIR="$CURRENT_DIR/dags"
# mkdir -p "$EXTERNAL_DAGS_DIR/$DAG_NAME"

# # Create DBT project structure
# DBT_PROJECT_DIR="$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project"

# mkdir -p "$DBT_PROJECT_DIR/models"
# mkdir -p "$DBT_PROJECT_DIR/models/staging"
# mkdir -p "$DBT_PROJECT_DIR/models/marts"
# mkdir -p "$DBT_PROJECT_DIR/models/sources"
# mkdir -p "$DBT_PROJECT_DIR/seeds"
# # mkdir -p "$DBT_PROJECT_DIR/snapshots"
# mkdir -p "$DBT_PROJECT_DIR/macros"
# # mkdir -p "$DBT_PROJECT_DIR/analyses"
# mkdir -p "$DBT_PROJECT_DIR/tests"
# mkdir -p "$DBT_PROJECT_DIR/docs"

# # Copy template files to new DBT project folder
# cp "$CURRENT_DIR/template_dbt/dbt_project.yml" "$DBT_PROJECT_DIR/dbt_project.yml"
# cp "$CURRENT_DIR/template_dbt/profiles.yml" "$DBT_PROJECT_DIR/profiles.yml"
# cp "$CURRENT_DIR/template_dbt/models" "$DBT_PROJECT_DIR/models"
# # cp "$CURRENT_DIR/template_dbt/models/marts/dim_customers.sql" "$DBT_PROJECT_DIR/models/marts/dim_customers.sql"
# cp "$CURRENT_DIR/template_dbt/models/marts/core_pokemon.sql" "$DBT_PROJECT_DIR/models/marts/core_pokemon.sql"
# cp "$CURRENT_DIR/template_dbt/models/staging/stg_pokemon.sql" "$DBT_PROJECT_DIR/models/staging/stg_pokemon.sql"
# cp "$CURRENT_DIR/template_dbt/models/sources/pokemon.yml" "$DBT_PROJECT_DIR/models/sources/pokemon.yml"

# cp "$CURRENT_DIR/template_dbt/seeds/my_seed_data.csv" "$DBT_PROJECT_DIR/seeds/my_seed_data.csv"
# # cp "$CURRENT_DIR/template_dbt/snapshots/snapshot_orders.sql" "$DBT_PROJECT_DIR/snapshots/snapshot_orders.sql"
# cp "$CURRENT_DIR/template_dbt/macros/my_custom_macro.sql" "$DBT_PROJECT_DIR/macros/my_custom_macro.sql"
# # cp "$CURRENT_DIR/template_dbt/analyses/my_analysis.sql" "$DBT_PROJECT_DIR/analyses/my_analysis.sql"
# cp "$CURRENT_DIR/template_dbt/tests/my_test.sql" "$DBT_PROJECT_DIR/tests/my_test.sql"
# cp "$CURRENT_DIR/template_dbt/docs/my_documentation.md" "$DBT_PROJECT_DIR/docs/my_documentation.md"

# # Replace placeholder name in dbt_project.yml with the DAG name
# sed -i "s/<PLACEHOLDER_NAME_HERE>/$DAG_NAME/g" "$DBT_PROJECT_DIR/dbt_project.yml"

# # Copy the template DAG to the external DAG folder
# cp "$CURRENT_DIR/template_dbt/template_dbt_dag.py" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py"

# sed -i "s/<PLACEHOLDER_NAME_HERE>/$DAG_NAME/g" "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py"
# # Create a symbolic link in the AIRFLOW_HOME/dags directory
# ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dag.py" "$AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"


# # mkdir "$AIRFLOW_HOME/dags/${DAG_NAME}"

# cp -r "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project" "$AIRFLOW_HOME/dags/${DAG_NAME}_dbt_project"
# # Create a symbolic link in the AIRFLOW_HOME/dags directory
# ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project/" "$AIRFLOW_HOME/dags/${DAG_NAME}/${DAG_NAME}_dbt_project/"
# ln -sf "$EXTERNAL_DAGS_DIR/$DAG_NAME/${DAG_NAME}_dbt_project/profiles.yaml" "$AIRFLOW_HOME/dags/${DAG_NAME}/${DAG_NAME}_dbt_project/profiles.yaml"



# rm -rf "$AIRFLOW_HOME/dags/${DAG_NAME}_dbt_project"/${DAG_NAME}_dag.py

# echo "DBT DAG $DAG_NAME created successfully in $EXTERNAL_DAGS_DIR/$DAG_NAME"
# echo "Symbolic link created in $AIRFLOW_HOME/dags/${DAG_NAME}_dag.py"

# # Check if the symbolic link was created correctly
# if [ -L "$AIRFLOW_HOME/dags/${DAG_NAME}_dag.py" ]; then
#   echo "Symbolic link verified."
# else
#   echo "Symbolic link creation failed."
# fi

# # Activate the DAG by setting 'is_paused' to 'False'

# # Set environment variable to silence warnings
# export SQLALCHEMY_SILENCE_UBER_WARNING=1

# # List the DAGs to ensure the new DAG is registered
# airflow dags list

# # Unpause the DAG
# airflow dags unpause "$DAG_NAME"
# echo "DAG $DAG_NAME activated."
