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
        dir('terraform') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve'
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
    stage('Deploy Lambda') {
      steps {
        dir('terraform') {
          sh 'terraform apply -auto-approve -target=aws_lambda_function.etl_lambda'
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
