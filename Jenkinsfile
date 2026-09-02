pipeline {
    agent any

    environment {
        TF_DIR = "environments/dev"
        AWS_DEFAULT_REGION = "us-east-1"
        GIT_REPO_OWNER = "qezman"
        GIT_REPO_NAME = "EKS-Platform-Core-Jenkins-Pipeline"
    }

    stages {

        stage('Lint') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check -recursive'
                    sh 'terraform init -backend=false'
                    sh 'terraform validate'
                }
            }
        }

        stage('Plan') {
            steps {
                dir("${TF_DIR}") {
                    withCredentials([file(credentialsId: 'tf-tfvars', variable: 'TFVARS_FILE')]) {
                        sh '''#!/bin/bash
                            set -euo pipefail
                            rm -f terraform.tfvars
                            cp "$TFVARS_FILE" terraform.tfvars
                            terraform plan -no-color -out=tfplan | tee plan_output.txt
                        '''
                    }
                }
            }
        }

        stage('Post Plan to PR') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                dir("${TF_DIR}") {
                    withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            PLAN_OUTPUT=$(cat plan_output.txt | head -c 60000)
                            COMMENT_BODY=$(printf '{"body": "### Terraform Plan\\n\\n\\`\\`\\`\\n%s\\n\\`\\`\\`"}' "$PLAN_OUTPUT")
                            curl -s -X POST \
                              -H "Authorization: token $GITHUB_TOKEN" \
                              -H "Content-Type: application/json" \
                              -d "$COMMENT_BODY" \
                              "https://api.github.com/repos/${GIT_REPO_OWNER}/${GIT_REPO_NAME}/issues/${CHANGE_ID}/comments"
                        '''
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: 'Apply this Terraform plan?', ok: 'Apply'
            }
        }

        stage('Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Helm Upgrade') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        aws eks update-kubeconfig --name eks-platform-new-dev --region us-east-1
                        helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
                          --namespace monitoring --reuse-values
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed (check the stage logs above)'
        }
        success {
            echo 'Pipeline completed successfully.'
        }
    }
}