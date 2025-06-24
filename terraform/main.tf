provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "lambda_logs"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "etl_bucket" {
  bucket = "etl-data-bucket-demo"
  force_destroy = true
}

resource "aws_db_instance" "etl_rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  identifier           = "etl-db"
  db_name              = "etl_db"
  username             = "postgres"
  password             = "password"
  publicly_accessible  = true
  skip_final_snapshot  = true
}

resource "aws_glue_catalog_database" "etl_glue_db" {
  name = "etl_glue_db"
}

resource "aws_ecr_repository" "etl_ecr_repo" {
  name = "etl-ecr-repo"
}

resource "aws_lambda_function" "etl_lambda" {
  function_name = "etl-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.etl_ecr_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 60
}

output "s3_bucket_name" {
  value = aws_s3_bucket.etl_bucket.id
}

output "rds_endpoint" {
  value = aws_db_instance.etl_rds.endpoint
}

output "glue_db_name" {
  value = aws_glue_catalog_database.etl_glue_db.name
}

output "lambda_name" {
  value = aws_lambda_function.etl_lambda.function_name
}
