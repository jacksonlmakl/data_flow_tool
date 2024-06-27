sudo apt-get update
sudo apt-get install python3-pip
sudo apt-get install python3-venv

python3 -m venv ui_venv
source ui_venv/bin/activate
pip3 install flask
python3 app.py &