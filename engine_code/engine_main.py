from datetime import datetime
import aiohttp
import asyncio
import pandas as pd
from aiohttp.client_exceptions import ContentTypeError
from datetime import date
import boto3
from io import StringIO
import time


api_key = 'Gg24TpEKJrrcywG1cQlZxq4hPrln5uzu6YJaqtCK'
regions = ['CAL', 'CENT', 'MIDA', 'NE', 'NY', 'NW', 'SE', 'SW', 'ERCO', 'TEX', 'TVA', 'ISNE']
service_name = 's3'
region_name = 'us-west-1'
aws_access_key_id = 'AKIAUNZCPOZY535FSZXO'
aws_secret_access_key = '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'
bucket_name = 'nuc-s3-bucket'


def get_list_urls(fuel_type_marker):
    urls = [f'https://api.eia.gov/v2/electricity/rto/fuel-type-data/data/?api_key={api_key}&frequency=hourly&data[' \
            f'0]=value&facets[respondent][]={region}&facets[fueltype][]={fuel_type_marker}&start=2023-02-20T00&end=2023-02-26T00&sort[0][' \
            f'column]=period&sort[0][direction]=desc&offset=0&length=5000' for region
            in
            regions]
    return urls


async def get_data_from_one_url(session, url):
    async with session.get(url) as r:
        return await r.json()


async def get_all(session, urls):
    tasks = []
    for url in urls:
        task = asyncio.create_task(get_data_from_one_url(session, url))
        tasks.append(task)
    results = await asyncio.gather(*tasks)
    return results


async def main_async(urls):
    async with aiohttp.ClientSession() as session:
        try:
            data = await get_all(session, urls)
        except ContentTypeError:
            return await main_async(urls)
        return data


def data_transformer_1(parsed_list):
    df_dict = {}
    for i in parsed_list:
        data = i['response']['data']
        generating_data = [i['value'] for i in data]
        df_dict.update({data[0]['respondent-name']: generating_data})
    df = pd.DataFrame(df_dict, index=None)
    return df


def calculate_median_and_upload_to_s3(df, prefix):
    frames = []
    for column in df.columns:
        sum = df[column]
        x = round(sum.groupby(sum.index // 24).mean(), 2)
        frames.append(x)
    result_df = pd.concat(frames, axis=1)
    date_range = pd.date_range(start="2023-02-20", end="2023-02-26")
    result_df.insert(0, "Date_Pulled", date.today())
    result_df.insert(1, "Date", date_range)
    csv_buffer = StringIO()
    result_df.to_csv(csv_buffer)
    s3 = boto3.resource(service_name=service_name, region_name=region_name,
                        aws_secret_access_key=aws_secret_access_key, aws_access_key_id=aws_access_key_id)
    s3.Object(bucket_name, f'{prefix}/{datetime.today().date()}_energy_data_{prefix}.csv').put(Body=csv_buffer.getvalue())
    return True


def pulling_function_nuclear():
    urls = get_list_urls('NUC')
    result = asyncio.run(main_async(urls))
    print('Parsing done for nuclear data')
    x = (data_transformer_1(result))
    calculate_median_and_upload_to_s3(x, 'nuclear')
    print('NUCLEAR dataset created and loaded')


def pulling_function_solar():
    urls = get_list_urls('SUN')
    result = asyncio.run(main_async(urls))
    print('Parsing done for solar data')
    x = (data_transformer_1(result))
    calculate_median_and_upload_to_s3(x, 'solar')
    print('SOLAR dataset created and loaded')


def pulling_function_wind():
    urls = get_list_urls('WND')
    result = asyncio.run(main_async(urls))
    print('Parsing done for wind data')
    x = (data_transformer_1(result))
    calculate_median_and_upload_to_s3(x, 'wind')
    print('WIND dataset created and loaded')


if __name__ == "__main__":
    pulling_function_nuclear()
    pulling_function_solar()

