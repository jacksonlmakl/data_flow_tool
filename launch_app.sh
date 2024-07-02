#!/bin/bash

# Define the virtual environment directory and the Flask app
VENV_DIR="ui_env"
APP_FILE="app.py"
REQUIREMENTS_FILE="requirements.txt"
PORT=8081

# Create the virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $VENV_DIR
else
    echo "Virtual environment already exists."
fi

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

pip install flask
pip install flask-httpauth
# Run the Flask app in the background
echo "Running Flask app in the background..."
nohup python $APP_FILE > flask_app.log 2>&1 &

echo "Flask app is running on port $PORT. Check flask_app.log for details."

# #!/bin/bash

# # Define the virtual environment directory and the Flask app
# VENV_DIR="ui_env"
# APP_FILE="app.py"
# REQUIREMENTS_FILE="app_requirements.txt"
# PORT=8081

# # Create the virtual environment
# if [ ! -d "$VENV_DIR" ]; then
#     echo "Creating virtual environment..."
#     python3 -m venv $VENV_DIR
# else
#     echo "Virtual environment already exists."
# fi

# # Activate the virtual environment
# source $VENV_DIR/bin/activate

# # Upgrade pip
# echo "Upgrading pip..."
# pip install --upgrade pip

# pip install flask

# # Run the Flask app in the background
# echo "Running Flask app in the background..."
# nohup python $APP_FILE > flask_app.log 2>&1 &

# echo "Flask app is running on port $PORT. Check flask_app.log for details."
