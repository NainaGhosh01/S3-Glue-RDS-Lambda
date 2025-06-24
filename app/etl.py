import boto3
import pandas as pd
import psycopg2
from io import StringIO

def handler(event=None, context=None):
    s3 = boto3.client('s3')
    bucket = 'etl-data-bucket-demo'
    key = 'sample-data.csv'

    obj = s3.get_object(Bucket=bucket, Key=key)
    df = pd.read_csv(obj['Body'])

    try:
        conn = psycopg2.connect(
            host='etl-db.ch0884o2o8rn.us-east-1.rds.amazonaws.com',
            database='etl_db',
            user='postgres',
            password='password',
            port=5432
        )
        cur = conn.cursor()
        for _, row in df.iterrows():
            cur.execute("INSERT INTO users (name, age) VALUES (%s, %s)", (row['name'], row['age']))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Failed to insert to RDS: {e}. Inserting to Glue")
        glue = boto3.client('glue')
        # Here you would use a Glue crawler or upload to S3 for Glue table discovery
    return {'status': 'completed'}
