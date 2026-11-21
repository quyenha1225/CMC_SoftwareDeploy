
def runPythonScript(String arguments) {
    if (isUnix()) {
        sh "python3 ${arguments}"
    } else {
        bat "\"${env.PYTHON_EXE}\" ${arguments}"
    }
}

def executeStep(String step) {
    def detailFile = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-${step}.txt"
    withEnv(["IMAGE_TAG=${env.IMAGE_TAG ?: 'local'}", "SMS_CI_DETAIL_FILE=${detailFile}"]) {
        runPythonScript("scripts/ci.py ${step}")
    }
}

def runLocalCommand(String command) {
    if (isUnix()) {
        sh command
    } else {
        bat command
    }
}

def configureDocker() {
    if (!isUnix() && !env.SMS_CI_BUILDER) {
        env.SMS_CI_BUILDER = 'sms-jenkins-linux'
    }
    if (env.SMS_DOCKER_CONTEXT) {
        env.DOCKER_CONTEXT = env.SMS_DOCKER_CONTEXT
    } else if (env.SMS_DOCKER_HOST) {
        env.DOCKER_CONTEXT = ''
        env.DOCKER_HOST = env.SMS_DOCKER_HOST
    } else if (!isUnix() && !env.DOCKER_CONTEXT && !env.DOCKER_HOST) {
        env.DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
    }
}

def executeParallelStep(String stageName, String step) {
    try {
        executeStep(step)
    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
        throw interrupted
    } catch (Exception failure) {
        notifyDiscord(stageName, step, 'FAILURE')
        throw failure
    }
}

def notifyDiscord(String stageName = '', String step = '', String result = '') {
    result = result ?: currentBuild.currentResult
    if (!stageName && result == 'SUCCESS' && env.SMS_DEPLOY_COMPLETED != 'true') {
        return
    }
    try {
        withCredentials([string(credentialsId: 'sms-discord-webhook', variable: 'DISCORD_WEBHOOK_URL')]) {
            def detail = ''
            if (step) {
                def detailFile = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-${step}.txt"
                if (fileExists(detailFile)) {
                    detail = readFile(detailFile).trim()
                }
            } else if (stageName == 'Deploy Local Docker') {
                detail = env.SMS_DEPLOY_CHECK ?: ''
            } else if (stageName == 'SonarQube Quality Gate') {
                detail = env.SMS_QUALITY_GATE_CHECK ?: ''
            } else if (stageName == 'Check Environment') {
                detail = env.SMS_ENVIRONMENT_CHECK ?: ''
            }
            withEnv(["SMS_BUILD_RESULT=${result}",
                     "SMS_FAILED_STAGE=${stageName}", "SMS_FAILED_CHECK=${detail}"]) {
                def notifier = "sms-discord-${stageName.replaceAll('[^A-Za-z0-9]+', '-') ?: 'summary'}.py"
                dir(pwd(tmp: true)) {
                    writeFile file: notifier, text: '''
import json
import os
from urllib.error import HTTPError
from urllib.request import Request, urlopen

env = os.environ
fields = [
    f"{env.get('JOB_NAME', 'Jenkins')} #{env.get('BUILD_NUMBER', '?')}",
    "Branch: " + (env.get("BRANCH_NAME") or env.get("GIT_BRANCH") or "unknown"),
    "Commit: " + (env.get("IMAGE_TAG") or "unknown"),
]
if env.get("SMS_FAILED_STAGE"):
    fields.append("Stage: " + env["SMS_FAILED_STAGE"])
if env.get("SMS_FAILED_CHECK"):
    fields.append("Check: " + env["SMS_FAILED_CHECK"])
if env.get("SMS_DEPLOY_COMPLETED") == "true":
    fields.append("Local Docker deployment and smoke checks passed")
if env.get("BUILD_URL"):
    fields.append("Console: " + env["BUILD_URL"].rstrip("/") + "/console")

payload = {
    "username": "SMS Jenkins",
    "allowed_mentions": {"parse": []},
    "embeds": [{"title": "Jenkins " + env["SMS_BUILD_RESULT"] +
                         (" - " + env["SMS_FAILED_STAGE"] if env.get("SMS_FAILED_STAGE") else ""),
                "description": chr(10).join(fields)[:4000]}],
}
try:
    request = Request(env["DISCORD_WEBHOOK_URL"].strip(),
                      data=json.dumps(payload).encode("utf-8"),
                      headers={"Content-Type": "application/json", "User-Agent": "SMS-Jenkins/1.0"},
                      method="POST")
    with urlopen(request, timeout=8) as response:
        print(f"Discord notification delivered (HTTP {response.status}).")
except HTTPError as error:
    print(f"Discord notification failed (HTTP {error.code}).")
except (OSError, ValueError):
    print("Discord notification failed. Check webhook configuration and network access.")
'''
                    runPythonScript(notifier)
                }
            }
        }
    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
        throw interrupted
    } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException missing) {
        echo 'CI/CD Discord credential sms-discord-webhook is missing or is not accessible to this job. Add it as Secret text.'
    } catch (Exception ignored) {
        echo 'CI/CD Discord notifier could not run. Check Secret text binding, Python and the Jenkins agent.'
    }
}

pipeline {
    agent {
        label 'sms-docker'
    }

    environment {
        DOCKER_BUILDKIT = '1'

        // Python 3.12 trên máy Windows của bạn.
        // Nếu chuyển máy Jenkins, cần cập nhật đường dẫn này.
        PYTHON_EXE = 'C:\\Users\\Admin\\AppData\\Local\\Programs\\Python\\Python312\\python.exe'
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
            defaultValue: true,
            description: 'Chạy SonarQube trên build nhánh. Có thể tắt khi chạy thủ công.'
        )
    }

    stages {

        stage('Checkout') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Checkout')
                    }
                }
            }

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

        stage('Check Environment') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Check Environment')
                    }
                }
            }

            steps {
                script {
                    configureDocker()
                    env.SMS_ENVIRONMENT_CHECK = 'Python, Docker CLI, Docker Compose and Java'
                    if (isUnix()) {
                        sh '''
                            python3 --version
                            docker --version
                            docker compose version
                            java -version
                        '''
                    } else {
                        bat '''
                            "%PYTHON_EXE%" --version
                            docker --version
                            docker compose version
                            java -version
                        '''
                    }
                    env.SMS_ENVIRONMENT_CHECK = 'Connect to the configured Docker Engine (Linux containers)'
                    def dockerOs = (isUnix()
                        ? sh(script: 'docker info --format "{{.OSType}}"', returnStdout: true)
                        : bat(script: '@docker info --format "{{.OSType}}"', returnStdout: true)).trim()
                    if (dockerOs != 'linux') {
                        error("The Docker Engine must be in Linux container mode. Detected: ${dockerOs}")
                    }
                    env.SMS_DOCKER_READY = 'true'
                }
            }
        }

        stage('Prepare') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Prepare', 'prepare')
                    }
                }
            }

            steps {
                executeStep('prepare')
            }
        }

        stage('Tests') {
            failFast true
            parallel {

                stage('Backend Test') {
                    steps {
                        script {
                            executeParallelStep('Backend Test', 'backend')
                        }
                    }
                }

                stage('Frontend Test') {
                    steps {
                        script {
                            executeParallelStep('Frontend Test', 'frontend')
                        }
                    }
                }
            }
        }

        stage('Validate Docker Compose') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Validate Docker Compose')
                    }
                }
            }

            steps {
                withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {
                    runLocalCommand(
                        'docker compose -f compose.yaml config --quiet'
                    )
                }
            }
        }

        stage('SonarQube Analysis') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('SonarQube Analysis', 'sonar')
                    }
                }
            }

            when {
                allOf {
                    expression {
                        params.RUN_SONAR
                    }
                    not {
                        changeRequest()
                    }
                }
            }

            steps {
                withSonarQubeEnv('sonarqube') {
                    executeStep('sonar')
                }
            }
        }

        stage('SonarQube Quality Gate') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('SonarQube Quality Gate')
                    }
                }
            }

            when {
                allOf {
                    expression {
                        params.RUN_SONAR
                    }
                    not {
                        changeRequest()
                    }
                }
            }

            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def gate = waitForQualityGate()
                        env.SMS_QUALITY_GATE_CHECK = "Quality gate status: ${gate.status}"

                        if (gate.status != 'OK') {
                            error("SonarQube Quality Gate: ${gate.status}")
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Build Docker Images', 'build')
                    }
                }
            }

            steps {
                // Build backend, frontend và migration.
                // Build context được giữ ở thư mục gốc repository.
                executeStep('build')
            }
        }

        stage('MySQL Integration Tests') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('MySQL Integration Tests', 'mysql')
                    }
                }
            }

            steps {
                // Database CI riêng, không sử dụng database local.
                executeStep('mysql')
            }
        }

        stage('Security Scan') {
            failFast true
            parallel {

                stage('Dependency and Image Scan') {
                    steps {
                        script {
                            executeParallelStep('Dependency and Image Scan', 'security')
                        }
                    }
                }

                stage('Secret Scan') {
                    steps {
                        script {
                            executeParallelStep('Secret Scan', 'secrets')
                        }
                    }
                }
            }
        }

        stage('Deploy Local Docker') {
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Deploy Local Docker')
                    }
                }
            }

            when {
                allOf {
                    expression {
                        def currentBranch = (
                            env.BRANCH_NAME ?: env.GIT_BRANCH ?: ''
                        ).replaceFirst(/^origin\//, '')

                        return currentBranch in ['quyen/admin', 'develop']
                    }

                    not {
                        changeRequest()
                    }
                }
            }

            steps {
                script {

                    // Khởi tạo cấu hình local nếu chưa có.
                    env.SMS_DEPLOY_CHECK = 'Initialize or validate local Docker configuration'
                    if (!fileExists('.env')) {
                        runPythonScript('scripts/docker.py init')
                    } else {
                        runPythonScript('scripts/docker.py config')
                    }

                    withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {

                        // Kiểm tra stack hiện tại.
                        env.SMS_DEPLOY_CHECK = 'Inspect the local Docker stack'
                        def running = isUnix()
                            ? sh(
                                script: 'docker compose -f compose.yaml ps --status running -q db backend',
                                returnStdout: true
                            ).trim()
                            : bat(
                                script: '@docker compose -f compose.yaml ps --status running -q db backend',
                                returnStdout: true
                            ).trim()

                        // Backup trước khi cập nhật nếu database và backend đang chạy.
                        if (running.readLines().size() >= 2) {
                            env.SMS_DEPLOY_CHECK = 'Back up local database and files'
                            echo 'Existing local stack detected. Creating backup.'

                            runPythonScript('scripts/docker.py backup')
                        }

                        // Khởi chạy các image đã được build ở stage trước.
                        env.SMS_DEPLOY_CHECK = 'Start frontend and backend, wait for health checks'
                        runLocalCommand(
                            'docker compose -f compose.yaml up -d --no-build --wait --wait-timeout 300 frontend backend'
                        )

                        // Provision dữ liệu demo theo cấu hình local.
                        env.SMS_DEPLOY_CHECK = 'Provision local demo accounts'
                        runLocalCommand(
                            'docker compose -f compose.yaml --profile tools run --rm provision'
                        )

                        // Kiểm tra frontend, backend và SQL integrity.
                        env.SMS_DEPLOY_CHECK = 'Run HTTP, role login and SQL smoke checks'
                        runPythonScript('scripts/docker.py smoke')
                        env.SMS_DEPLOY_COMPLETED = 'true'

                        // Hiển thị trạng thái các container.
                        env.SMS_DEPLOY_CHECK = 'Read Docker container status'
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
                artifacts: 'artifacts/reports/**/*,backend/target/site/jacoco/**/*,frontend/coverage/**/*',
                allowEmptyArchive: true
            )
        }

        success {
            echo "CI completed for ${env.IMAGE_TAG ?: 'unknown commit'}."

            script {
                def currentBranch = (
                    env.BRANCH_NAME ?: env.GIT_BRANCH ?: ''
                ).replaceFirst(/^origin\//, '')

                if (env.SMS_DEPLOY_COMPLETED == 'true') {
                    echo 'Local Docker deployment completed.'
                } else {
                    echo "CI completed. Deployment skipped for branch: ${currentBranch}"
                }
            }
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and archived reports.'

            script {
                if (env.SMS_DOCKER_READY != 'true') {
                    echo 'Docker logs unavailable because the Docker Engine preflight did not pass.'
                } else if (isUnix()) {
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

        cleanup {
            script {
                notifyDiscord()
            }
        }
    }
}
