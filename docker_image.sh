#!/bin/bash

IMAGE_NAME=${1:-"jacksonmakl/data_flow_tool"}
IMAGE_VERSION=${2:-"latest"}
CONTAINER_NAME=${3:-"airflow_container"}

# Navigate to the data_flow_tool directory
cd data_flow_tool

# Define the output file
OUTPUT_FILE="secrets.yaml"

# Clear the output file if it exists
> $OUTPUT_FILE

# Find all secrets.yaml files in the dags directory and its subdirectories
find dags -type f -name 'secrets.yaml' | while read -r file; do
    # Append the contents of each secrets.yaml to the master file
    echo "Processing $file..."
    cat "$file" >> $OUTPUT_FILE
    # echo -e "\n---\n" >> $OUTPUT_FILE  # Optional: Add a separator between files for clarity
done


# Define the path to the virtual environment
VENV_DIR="airflow_home/airflow_venv"

# Define the output file for the requirements
OUTPUT_FILE="requirements.txt"

# Check if the virtual environment directory exists
if [ ! -d "$VENV_DIR" ]; then
  echo "Virtual environment directory $VENV_DIR does not exist."
  exit 1
fi

# Check if entry_point.sh exists
if [ ! -f "entry_point.sh" ]; then
  echo "entry_point.sh does not exist in the current directory."
  exit 1
fi

# Make entry_point.sh executable
chmod +x entry_point.sh

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Find every requirements.txt file in the dags directory and its subdirectories
find dags -name 'requirements.txt' | while read requirements_file; do
    echo "Installing packages from $requirements_file"
    pip install -r "$requirements_file"
done

# Generate the requirements.txt file
pip freeze > "$OUTPUT_FILE"

# Deactivate the virtual environment
deactivate

echo "Requirements have been saved to $OUTPUT_FILE"

# Remove pkg_resources from requirements.txt if present
sed -i "s/pkg_resources==0.0.0/ /g" $OUTPUT_FILE


# tar -czvf airflow_home.tar.gz airflow_home
tar --exclude='airflow_home/airflow_venv' --dereference -czvf airflow_home.tar.gz airflow_home

# Create a Dockerfile if it doesn't exist
cat <<EOF > Dockerfile
# Use the official Airflow image with Python 3.8
FROM apache/airflow:2.5.1-python3.8

# Set environment variables
ENV AIRFLOW_HOME=/opt/airflow
ENV PIP_USER=false
ENV HOME=/root

USER airflow
# Create necessary directories and set permissions
# USER root
# RUN mkdir -p /opt/airflow/logs /opt/airflow/dags && \
#     chown -R airflow: /opt/airflow

# Copy everything from the current directory to the working directory in the Docker image
# COPY . /opt/airflow/
# Copy the tarball into the Docker image
COPY requirements.txt /opt/airflow/requirements.txt
COPY airflow_home.tar.gz /opt/airflow/
COPY entry_point.sh  /opt/airflow/
# Ensure entry_point.sh is executable
USER root
RUN chmod +x /opt/airflow/entry_point.sh
USER airflow

RUN tar -xzvf /opt/airflow/airflow_home.tar.gz -C /opt/airflow && rm /opt/airflow/airflow_home.tar.gz
RUN rm -rf /opt/airflow/dags
RUN cp -rf /opt/airflow/airflow_home/dags/ /opt/airflow/
RUN rm -rf /opt/airflow/airflow_home

COPY secrets.yaml /opt/airflow/dags/secrets.yaml
COPY secrets.yaml /opt/airflow/secrets.yaml

# Install python3-venv if it's not installed
USER root
RUN apt-get update && apt-get install -y python3-venv

# Switch to the airflow user
# USER airflow

# Create the virtual environment
RUN python3 -m venv /opt/airflow/airflow_venv

# Upgrade pip and install dependencies
RUN /opt/airflow/airflow_venv/bin/pip install --upgrade pip
RUN /opt/airflow/airflow_venv/bin/pip install dbt dbt-snowflake
RUN /opt/airflow/airflow_venv/bin/pip install kafka-python
RUN /opt/airflow/airflow_venv/bin/pip install -r /opt/airflow/requirements.txt

# Set the working directory
WORKDIR /opt/airflow

# Set the entrypoint
ENTRYPOINT ["/opt/airflow/entry_point.sh"]
EOF

# Build the Docker image
sudo docker build -t $IMAGE_NAME:$IMAGE_VERSION .

# Stop and remove any existing container with the same name
sudo docker rm -f $CONTAINER_NAME || true

# Run the new container
# sudo docker run -d --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_VERSION

echo "Docker Image Built Successfully"
exit 0







# #!/bin/bash

# IMAGE_NAME=${1:-"jacksonmakl/data_flow_tool"}
# IMAGE_VERSION=${2:-"latest"}
# CONTAINER_NAME=${3:-"airflow_container"}

# # Navigate to the data_flow_tool directory
# cd data_flow_tool

# # Define the path to the virtual environment
# VENV_DIR="airflow_home/airflow_venv"

# # Define the output file for the requirements
# OUTPUT_FILE="requirements.txt"

# # Check if the virtual environment directory exists
# if [ ! -d "$VENV_DIR" ]; then
#   echo "Virtual environment directory $VENV_DIR does not exist."
#   exit 1
# fi

# # Check if entry_point.sh exists
# if [ ! -f "entry_point.sh" ]; then
#   echo "entry_point.sh does not exist in the current directory."
#   exit 1
# fi

# # Make entry_point.sh executable
# chmod +x entry_point.sh

# # Activate the virtual environment
# source "$VENV_DIR/bin/activate"

# # Find every requirements.txt file in the dags directory and its subdirectories
# find dags -name 'requirements.txt' | while read requirements_file; do
#     echo "Installing packages from $requirements_file"
#     pip install -r "$requirements_file"
# done

# # Generate the requirements.txt file
# pip freeze > "$OUTPUT_FILE"

# # Deactivate the virtual environment
# deactivate

# echo "Requirements have been saved to $OUTPUT_FILE"

# # Remove pkg_resources from requirements.txt if present
# sed -i "s/pkg_resources==0.0.0/ /g" $OUTPUT_FILE

# # Create a Dockerfile if it doesn't exist
# cat <<EOF > Dockerfile
# # Use the official Airflow image with Python 3.8
# FROM apache/airflow:2.5.1-python3.8

# # Set environment variables
# ENV AIRFLOW_HOME=/opt/airflow
# ENV PIP_USER=false
# ENV HOME=/root

# # Create necessary directories and set permissions
# USER root
# RUN mkdir -p /opt/airflow/logs /opt/airflow/dags && \
#     chown -R airflow: /opt/airflow

# # Copy everything from the current directory to the working directory in the Docker image
# COPY . /opt/airflow/

# # Ensure entry_point.sh is executable
# RUN chmod +x /opt/airflow/entry_point.sh

# # Install python3-venv if it's not installed
# RUN apt-get update && apt-get install -y python3-venv

# # Switch to the airflow user
# USER airflow

# # Create the virtual environment
# RUN python3 -m venv /opt/airflow/airflow_venv

# # Upgrade pip and install dependencies
# RUN /opt/airflow/airflow_venv/bin/pip install --upgrade pip
# RUN /opt/airflow/airflow_venv/bin/pip install dbt dbt-snowflake
# RUN /opt/airflow/airflow_venv/bin/pip install -r /opt/airflow/requirements.txt

# # Set the working directory
# WORKDIR /opt/airflow

# # Set the entrypoint
# ENTRYPOINT ["/opt/airflow/entry_point.sh"]
# EOF

# # Build the Docker image
# sudo docker build -t $IMAGE_NAME:$IMAGE_VERSION .

# # Stop and remove any existing container with the same name
# sudo docker rm -f $CONTAINER_NAME || true

# # Run the new container
# # sudo docker run -d --name $CONTAINER_NAME $IMAGE_NAME:$IMAGE_VERSION

# echo "Docker Image Built Successfully"
# exit 0

