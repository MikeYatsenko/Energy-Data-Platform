from io import StringIO
import pandas as pd
from sqlalchemy import create_engine
import boto3
import datetime


def lambda_handler(event, context):
    s3 = boto3.resource(service_name='s3', region_name='us-east-1', aws_access_key_id=,
                        aws_secret_access_key=)

    bucket_name = 'nuc-s3-bucket'

    csv_file = s3.Object(bucket_name, f'nuclear/{datetime.date.today()}_energy_data.csv').get()
    body = csv_file['Body']
    csv_string = body.read().decode('utf-8')
    df = pd.read_csv(StringIO(csv_string))
    df.drop('Unnamed: 0', axis=1, inplace=True)
    engine = create_engine('postgresql://@terraform-20230413194615999500000001'
                           '.c0yflfvvzy5u.us-west-1.rds.amazonaws.com/postgres')
    df.to_sql('nuclear_data', engine, if_exists='append')
    return 'finished'
