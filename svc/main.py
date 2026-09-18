#!/usr/bin/env python3
import os, socket
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def root():
    return jsonify({
        "app": os.getenv("APP_NAME", "unknown"),
        "version": os.getenv("VERSION", "0.0.0"),
        "pod": socket.gethostname()
    })

@app.route('/healthz')
def healthz():
    return '', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
