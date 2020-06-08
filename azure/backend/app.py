import os

from flask import Flask
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session


app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/mysqltest')
def mysql_test():

    engine = create_engine(os.environ['DATABASE_URL'])
    session_obj = sessionmaker(bind=engine)
    session = scoped_session(session_obj)

    return ''.join(session.execute('SELECT VERSION();').fetchone())

# CORS Headers
@app.after_request
def after_request(response):
    header = response.headers
    header['Access-Control-Allow-Origin'] = '*'
    return response
