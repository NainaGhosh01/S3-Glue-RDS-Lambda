FROM public.ecr.aws/lambda/python:3.9
COPY app/etl.py etl.py
RUN pip install pandas psycopg2-binary boto3
CMD ["etl.handler"]
