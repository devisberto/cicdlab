import socket

from flask import Flask

app = Flask(__name__)

# Example of variable declared in Python code
page_title = "Title set in Python code"

# Get hostname from the machine hosting the app and assign to the hostname variable
hostname = socket.gethostname()

# Webpage showed accessing the webapp
@app.route('/')
def index():
    return f"""
        <h1>{page_title}</h1>
        <p>Hostname: {hostname}</p>
    """

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
