import csv
import boto3
import datetime
import psycopg2

SQL1 = """CREATE TABLE solar_data(
    index int,
    date_pulled text,
    date text,
    california double precision,
    central double precision,
    mid_atlantic double precision,
    new_england double precision,
    new_york double precision,
    northeast double precision,
    southeast double precision,
    southwest double precision,
    erct double precision,
    texas double precision, 
    tennessee double precision
);"""

SQL2 = """
DELETE FROM solar_data
WHERE date_pulled = %s;
"""

SQL3 = """INSERT INTO solar_data(index, date_pulled, date, california, central, mid_atlantic, new_england, 
            new_york, northeast, southeast, southwest, erct, texas, tennessee) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""


def lambda_handler(event, context):
    conn = psycopg2.connect(
        host="put here rds endpoint",
        database="postgres",
        user="mikeyatsenko",
        password="yatsenkomike13",
        port='5432'
    )
    current_date = str(datetime.date.today())
    cur = conn.cursor()
    cur.execute(SQL2, (current_date,))
    conn.commit()

    s3 = boto3.resource(service_name='s3', region_name='us-east-1', aws_access_key_id="",
                        aws_secret_access_key="")

    bucket_name = 'nuc-s3-bucket'

    csv_file = s3.Object(bucket_name, f'solar/{datetime.date.today()}_energy_data_solar.csv').get()
    data = csv_file['Body'].read().decode('utf-8').splitlines()  # 3
    records = csv.reader(data)  # 4
    next(records)
    for row in records:
        cur.execute(SQL3, (
            row[0], row[1], row[2], row[3], row[4], row[5], row[6],
            row[7], row[8], row[9], row[10], row[11], row[12], row[13]))

    conn.commit()
    conn.close()
    print('finished')
    return True
