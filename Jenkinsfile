pipeline {
  agent any
  environment {
    AWS_DEFAULT_REGION = 'us-east-1'
    ECR_REPO = 'etl-ecr-repo'
    IMAGE_TAG = 'latest'
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Terraform Init & Apply') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          dir('terraform') {
            sh 'terraform init'
            // Exclude Lambda in first apply
            sh 'terraform apply -auto-approve -target=aws_s3_bucket.etl_bucket -target=aws_db_instance.etl_rds -target=aws_glue_catalog_database.etl_glue_db -target=aws_ecr_repository.etl_ecr_repo -target=aws_iam_role.lambda_exec -target=aws_iam_policy_attachment.lambda_logs'
          }
        }
      }
    }
    stage('Build Docker Image') {
      steps {
        script {
          sh 'docker build -t etl-job .' 
        }
      }
    }
    stage('Push to ECR') {
      steps {
        script {
          sh '''
          aws ecr get-login-password | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
          docker tag etl-job:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
          docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
          '''
        }
      }
    }
    stage('Terraform Apply Lambda') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          dir('terraform') {
            sh 'terraform apply -auto-approve -target=aws_lambda_function.etl_lambda'
          }
        }
      }
    }
    stage('Test Lambda') {
      steps {
        sh 'aws lambda invoke --function-name etl-lambda out.json'
      }
    }
  }
}
