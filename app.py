from flask import Flask, render_template, request, redirect, url_for, flash
import subprocess
import os

app = Flask(__name__)
app.secret_key = 'supersecretkey'

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/run_script', methods=['POST'])
def run_script():
    script = request.form['script']
    dag_name = request.form.get('dag_name', '')

    if script == 'create_dag' and not dag_name:
        flash('DAG Name is required for creating DAG.')
        return redirect(url_for('index'))

    try:
        if script == 'create_dag':
            command = ['./create_dag.sh', dag_name]
        else:
            command = ['./' + script + '.sh']
        
        result = subprocess.run(command, capture_output=True, text=True)
        flash(result.stdout)
        if result.stderr:
            flash(result.stderr)
    except Exception as e:
        flash(str(e))

    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081, debug=True)
