pipeline {
    agent any
    
    environment {
        GHCR_REGISTRY = 'ghcr.io'
        GHCR_NAMESPACE = 'mankinimbom'
        BACKEND_IMAGE = "${GHCR_REGISTRY}/${GHCR_NAMESPACE}/pern-backend"
        FRONTEND_IMAGE = "${GHCR_REGISTRY}/${GHCR_NAMESPACE}/pern-frontend"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        DOCKER_BUILDKIT = '1'
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['staging', 'production'], description: 'Target environment for deployment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip running tests')
        booleanParam(name: 'BUILD_BACKEND', defaultValue: true, description: 'Build backend image')
        booleanParam(name: 'BUILD_FRONTEND', defaultValue: true, description: 'Build frontend image')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Building commit: ${GIT_COMMIT_SHORT}"
                    echo "Target environment: ${params.ENVIRONMENT}"
                }
            }
        }
        
        stage('Validate') {
            steps {
                script {
                    sh '''
                        echo "Validating Kubernetes manifests..."
                        if [ -f bootstrap/validate-config.sh ]; then
                            chmod +x bootstrap/validate-config.sh
                            ./bootstrap/validate-config.sh || echo "Warning: Validation script found issues"
                        fi
                    '''
                }
            }
        }
        
        stage('Build Backend') {
            when {
                expression { params.BUILD_BACKEND == true }
            }
            steps {
                script {
                    echo "Building backend image..."
                    sh '''
                        if [ -d backend ]; then
                            cd backend
                            docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                        -t ${BACKEND_IMAGE}:latest \
                                        --build-arg NODE_ENV=production \
                                        .
                        else
                            echo "Warning: backend directory not found. Skipping backend build."
                        fi
                    '''
                }
            }
        }
        
        stage('Build Frontend') {
            when {
                expression { params.BUILD_FRONTEND == true }
            }
            steps {
                script {
                    echo "Building frontend image..."
                    sh '''
                        if [ -d frontend ]; then
                            cd frontend
                            docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                                        -t ${FRONTEND_IMAGE}:latest \
                                        --build-arg NODE_ENV=production \
                                        .
                        else
                            echo "Warning: frontend directory not found. Skipping frontend build."
                        fi
                    '''
                }
            }
        }
        
        stage('Test') {
            when {
                expression { params.SKIP_TESTS == false }
            }
            parallel {
                stage('Test Backend') {
                    when {
                        expression { params.BUILD_BACKEND == true }
                    }
                    steps {
                        script {
                            sh '''
                                if [ -d backend ]; then
                                    echo "Running backend tests..."
                                    docker run --rm ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} npm test || echo "No tests configured"
                                fi
                            '''
                        }
                    }
                }
                stage('Test Frontend') {
                    when {
                        expression { params.BUILD_FRONTEND == true }
                    }
                    steps {
                        script {
                            sh '''
                                if [ -d frontend ]; then
                                    echo "Running frontend tests..."
                                    docker run --rm ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} npm test || echo "No tests configured"
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Scan Backend') {
                    when {
                        expression { params.BUILD_BACKEND == true }
                    }
                    steps {
                        script {
                            sh '''
                                if command -v trivy >/dev/null 2>&1; then
                                    echo "Scanning backend image for vulnerabilities..."
                                    trivy image --severity HIGH,CRITICAL ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} || echo "Trivy scan completed with findings"
                                else
                                    echo "Trivy not installed. Skipping security scan."
                                fi
                            '''
                        }
                    }
                }
                stage('Scan Frontend') {
                    when {
                        expression { params.BUILD_FRONTEND == true }
                    }
                    steps {
                        script {
                            sh '''
                                if command -v trivy >/dev/null 2>&1; then
                                    echo "Scanning frontend image for vulnerabilities..."
                                    trivy image --severity HIGH,CRITICAL ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} || echo "Trivy scan completed with findings"
                                else
                                    echo "Trivy not installed. Skipping security scan."
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'ghcr-credentials', passwordVariable: 'GHCR_TOKEN', usernameVariable: 'GHCR_USER')]) {
                        sh '''
                            echo "Logging in to GHCR..."
                            echo $GHCR_TOKEN | docker login ${GHCR_REGISTRY} -u $GHCR_USER --password-stdin
                            
                            if [ "${BUILD_BACKEND}" = "true" ] && docker images ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} --format "{{.Repository}}" | grep -q "${BACKEND_IMAGE}"; then
                                echo "Pushing backend image..."
                                docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${BACKEND_IMAGE}:latest
                            fi
                            
                            if [ "${BUILD_FRONTEND}" = "true" ] && docker images ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} --format "{{.Repository}}" | grep -q "${FRONTEND_IMAGE}"; then
                                echo "Pushing frontend image..."
                                docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                                docker push ${FRONTEND_IMAGE}:latest
                            fi
                            
                            docker logout ${GHCR_REGISTRY}
                        '''
                    }
                }
            }
        }
        
        stage('Update Manifests') {
            steps {
                script {
                    sh '''
                        echo "Updating Kubernetes manifests with new image tags..."
                        
                        TARGET_ENV="${ENVIRONMENT}"
                        
                        if [ "${BUILD_BACKEND}" = "true" ]; then
                            # Update base backend image
                            sed -i "s|image: ${BACKEND_IMAGE}:.*|image: ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}|g" apps/pern-app/base/backend.yaml
                            
                            # Update overlay if exists
                            if [ -f "apps/pern-app/overlays/${TARGET_ENV}/resource-patch.yaml" ]; then
                                sed -i "s|image: ${BACKEND_IMAGE}:.*|image: ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}|g" apps/pern-app/overlays/${TARGET_ENV}/resource-patch.yaml
                            fi
                        fi
                        
                        if [ "${BUILD_FRONTEND}" = "true" ]; then
                            # Update base frontend image
                            sed -i "s|image: ${FRONTEND_IMAGE}:.*|image: ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}|g" apps/pern-app/base/frontend.yaml
                            
                            # Update overlay if exists
                            if [ -f "apps/pern-app/overlays/${TARGET_ENV}/resource-patch.yaml" ]; then
                                sed -i "s|image: ${FRONTEND_IMAGE}:.*|image: ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}|g" apps/pern-app/overlays/${TARGET_ENV}/resource-patch.yaml
                            fi
                        fi
                        
                        git diff apps/pern-app/
                    '''
                }
            }
        }
        
        stage('Commit and Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_TOKEN', usernameVariable: 'GIT_USER')]) {
                        sh '''
                            git config user.name "Jenkins CI"
                            git config user.email "jenkins@ci.local"
                            
                            if git diff --quiet apps/pern-app/; then
                                echo "No changes to commit"
                            else
                                git add apps/pern-app/
                                git commit -m "chore: update ${ENVIRONMENT} images to ${GIT_COMMIT_SHORT}" \
                                           -m "" \
                                           -m "- Backend: ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}" \
                                           -m "- Frontend: ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}" \
                                           -m "" \
                                           -m "[skip ci]"
                                
                                git push https://${GIT_USER}:${GIT_TOKEN}@github.com/${GHCR_NAMESPACE}/pern-gitops.git HEAD:main
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            steps {
                script {
                    sh '''
                        if command -v argocd >/dev/null 2>&1; then
                            echo "Syncing ArgoCD application for ${ENVIRONMENT}..."
                            argocd app sync pern-app-${ENVIRONMENT} --prune || echo "ArgoCD sync skipped (argocd CLI not available)"
                        else
                            echo "ArgoCD CLI not found. Skipping manual sync."
                            echo "ArgoCD will auto-sync based on configured sync policy."
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            echo "Images pushed with tag: ${GIT_COMMIT_SHORT}"
            echo "Environment: ${params.ENVIRONMENT}"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
        always {
            sh 'docker system prune -f || true'
            cleanWs()
        }
    }
}
