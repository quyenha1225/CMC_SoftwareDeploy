
def executeStep(String step) {
    withEnv(["IMAGE_TAG=${env.IMAGE_TAG ?: 'local'}"]) {
        if (isUnix()) {
            sh "python3 scripts/ci.py ${step}"
        } else {
            bat "python scripts\\ci.py ${step}"
        }
    }
}

def runLocalCommand(String command) {
    if (isUnix()) {
        sh command
    } else {
        bat command
    }
}

pipeline {
    agent { label 'sms-docker' }

    environment {
        DOCKER_BUILDKIT = '1'
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        timeout(time: 90, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        // Dự phòng nếu GitHub webhook chưa được cấu hình.
        pollSCM('H/2 * * * *')
    }

    parameters {
        booleanParam(
            name: 'RUN_SONAR',
            defaultValue: false,
            description: 'Bật khi Jenkins đã cấu hình SonarQube server tên sonarqube.'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = isUnix()
                        ? sh(
                            script: 'git rev-parse HEAD',
                            returnStdout: true
                        ).trim()
                        : bat(
                            script: '@git rev-parse HEAD',
                            returnStdout: true
                        ).trim()

                    if (!(env.IMAGE_TAG ==~ /[0-9a-f]{40}/)) {
                        error('Không lấy được Git commit SHA hợp lệ.')
                    }

                    echo "Building commit: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Prepare') {
            steps {
                executeStep('prepare')
            }
        }

        stage('Tests') {
            parallel {
                stage('Backend Test') {
                    steps {
                        executeStep('backend')
                    }
                }

                stage('Frontend Test') {
                    steps {
                        executeStep('frontend')
                    }
                }
            }
        }

        stage('Validate Docker Compose') {
            steps {
                withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {
                    runLocalCommand(
                        'docker compose -f compose.yaml config --quiet'
                    )
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                allOf {
                    expression { params.RUN_SONAR }
                    not { changeRequest() }
                }
            }

            steps {
                withSonarQubeEnv('sonarqube') {
                    executeStep('sonar')
                }
            }
        }

        stage('SonarQube Quality Gate') {
            when {
                allOf {
                    expression { params.RUN_SONAR }
                    not { changeRequest() }
                }
            }

            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def gate = waitForQualityGate()

                        if (gate.status != 'OK') {
                            error("SonarQube Quality Gate: ${gate.status}")
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                // ci.py build đã build đủ backend, frontend và migration.
                // Build context là thư mục gốc repository.
                executeStep('build')
            }
        }

        stage('MySQL Integration Tests') {
            steps {
                // Dùng database CI riêng, không đụng database local.
                executeStep('mysql')
            }
        }

        stage('Security Scan') {
            parallel {
                stage('Dependency and Image Scan') {
                    steps {
                        executeStep('security')
                    }
                }

                stage('Secret Scan') {
                    steps {
                        executeStep('secrets')
                    }
                }
            }
        }

        stage('Deploy Local Docker') {
    when {
        allOf {
            expression {
                def currentBranch = (
    env.BRANCH_NAME ?: env.GIT_BRANCH ?: ''
).replaceFirst(/^origin\//, '')

if (currentBranch in ['quyen/admin', 'develop']) {
    echo 'CI/CD completed: Local Docker deployment executed.'
} else {
    echo "CI completed. Deployment skipped for branch: ${currentBranch}"
}

                return currentBranch in ['quyen/admin', 'develop']
            }
            not { changeRequest() }
        }
    }

            steps {
                script {
                    // Tạo .env và secrets lần đầu nếu máy Jenkins chưa có.
                    if (!fileExists('.env')) {
                        runLocalCommand(
                            isUnix()
                                ? 'python3 scripts/docker.py init'
                                : 'python scripts\\docker.py init'
                        )
                    }

                    withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {
                        // Nếu stack cũ đang chạy, backup trước khi migration/deploy.
                        def running = isUnix()
                            ? sh(
                                script: 'docker compose -f compose.yaml ps --status running -q db backend',
                                returnStdout: true
                            ).trim()
                            : bat(
                                script: '@docker compose -f compose.yaml ps --status running -q db backend',
                                returnStdout: true
                            ).trim()

                        if (running.readLines().size() >= 2) {
                            echo 'Existing local stack detected. Creating backup.'
                            runLocalCommand(
                                isUnix()
                                    ? 'python3 scripts/docker.py backup'
                                    : 'python scripts\\docker.py backup'
                            )
                        }

                        // Chạy image đã build và kiểm thử ở các stage trước.
                        // Compose tự khởi động DB và migration theo depends_on.
                        runLocalCommand(
                            'docker compose -f compose.yaml up -d --no-build --wait --wait-timeout 300 frontend backend'
                        )

                        // Provision dữ liệu demo theo cấu hình local.
                        runLocalCommand(
                            'docker compose -f compose.yaml --profile tools run --rm provision'
                        )

                        // Kiểm tra frontend, backend readiness và SQL integrity.
                        runLocalCommand(
                            isUnix()
                                ? 'python3 scripts/docker.py --production smoke'
                                : 'python scripts\\docker.py --production smoke'
                        )

                        runLocalCommand(
                            'docker compose -f compose.yaml ps'
                        )
                    }
                }
            }
        }
    }

    post {
        always {
            junit(
                testResults: 'backend/target/surefire-reports/*.xml,frontend/coverage/junit.xml',
                allowEmptyResults: true
            )

            archiveArtifacts(
                artifacts: 'artifacts/reports/**/*,backend/target/site/jacoco/**,frontend/coverage/**',
                allowEmptyArchive: true
            )
        }

        success {
            echo "CI completed for ${env.IMAGE_TAG ?: 'unknown commit'}."

            script {
                if (env.BRANCH_NAME == 'develop') {
                    echo 'Local Docker deployment completed.'
                } else {
                    echo 'Validation completed. Deployment is restricted to develop.'
                }
            }
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and archived reports.'

            script {
                if (isUnix()) {
                    sh(
                        script: 'docker compose -f compose.yaml logs --tail=100',
                        returnStatus: true
                    )
                } else {
                    bat(
                        script: 'docker compose -f compose.yaml logs --tail=100',
                        returnStatus: true
                    )
                }
            }
        }
    }
}
