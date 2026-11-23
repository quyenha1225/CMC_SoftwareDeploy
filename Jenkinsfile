
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

def sendDiscord(String stageName, String step, String result) {
    def detail = ''
    if (step) {
        def detailFile = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-${step}.txt"
        if (fileExists(detailFile)) {
            detail = readFile(detailFile).trim()
        }
    } else if (stageName == 'SonarQube Quality Gate') {
        detail = env.SMS_QUALITY_GATE_CHECK ?: ''
    } else if (stageName == 'Check Environment') {
        detail = env.SMS_ENVIRONMENT_CHECK ?: ''
    }
    withEnv(["SMS_BUILD_RESULT=${result}", "SMS_EVENT_STAGE=${stageName}", "SMS_EVENT_CHECK=${detail}"]) {
        def notifier = "sms-discord-${stageName.replaceAll('[^A-Za-z0-9]+', '-') ?: 'summary'}.py"
        dir(pwd(tmp: true)) {
            writeFile file: notifier, text: '''
import json
import os
from pathlib import Path
import re
from urllib.error import HTTPError
from urllib.parse import parse_qsl, urlencode, urlsplit
from urllib.request import Request, urlopen

env = os.environ
result = env["SMS_BUILD_RESULT"]
stage = env.get("SMS_EVENT_STAGE")
fields = [
    f"{env.get('JOB_NAME', 'Jenkins')} #{env.get('BUILD_NUMBER', '?')}",
    "Branch: " + (env.get("SMS_CHECKOUT_BRANCH") or env.get("BRANCH_NAME") or "unknown"),
    "Commit: " + (env.get("IMAGE_TAG") or "unknown"),
]
if stage:
    fields.append("Stage: " + stage)
if env.get("SMS_EVENT_CHECK"):
    fields.append("Check: " + env["SMS_EVENT_CHECK"])
if env.get("SMS_NOTIFICATION_CONTEXT"):
    fields.append(env["SMS_NOTIFICATION_CONTEXT"])
if env.get("SMS_CI_COMPLETED") == "true":
    fields.append("CI: passed")
if env.get("SMS_DEPLOY_COMPLETED") == "true":
    fields.append("CD: deployment and smoke checks passed")
    if env.get("SMS_DEPLOY_STAGE") == "Deploy Server SSH":
        fields.append("Public URL: " + env.get("SMS_SERVER_PUBLIC_URL", ""))
elif result == "STARTED" and stage in {"Deploy Local Docker", "Deploy Server SSH"}:
    fields.append("CD: deployment started")
elif env.get("SMS_DEPLOY_STARTED") == "true":
    fields.append("CD: deployment did not complete")
elif env.get("SMS_CI_COMPLETED") == "true":
    fields.append("CD: not run for this build")
if env.get("BUILD_URL"):
    fields.append("Console: " + env["BUILD_URL"].rstrip("/") + "/console")

payload = {
    "username": "SMS Jenkins",
    "allowed_mentions": {"parse": []},
    "embeds": [{"title": "Jenkins " + result + (" - " + stage if stage else ""),
                "description": chr(10).join(fields)[:4000]}],
}
try:
    webhook = env.get("DISCORD_WEBHOOK_URL", "").strip()
    if not webhook and env.get("SMS_DISCORD_WEBHOOK_FILE"):
        webhook = Path(env["SMS_DISCORD_WEBHOOK_FILE"]).read_text(encoding="utf-8-sig").strip()
    url = urlsplit(webhook)
    if (url.scheme != "https" or url.netloc not in {"discord.com", "discordapp.com", "canary.discord.com", "ptb.discord.com"}
        or not re.fullmatch(r"/api/(?:v[0-9]+/)?webhooks/[0-9]+/[A-Za-z0-9_-]+", url.path)):
        raise ValueError("Invalid Discord webhook configuration")
    query = dict(parse_qsl(url.query))
    query["wait"] = "true"
    request = Request(url._replace(query=urlencode(query), fragment="").geturl(),
                      data=json.dumps(payload).encode("utf-8"),
                      headers={"Content-Type": "application/json", "User-Agent": "SMS-Jenkins/1.0"},
                      method="POST")
    with urlopen(request, timeout=8) as response:
        message = json.load(response)
        print(f"Discord notification delivered (HTTP {response.status}, message {message['id']}).")
except HTTPError as error:
    print(f"Discord notification failed (HTTP {error.code}).")
except (OSError, ValueError, KeyError, RuntimeError) as error:
    print(f"Discord notification failed ({type(error).__name__}). Check the webhook and agent network.")
'''
            runPythonScript(notifier)
        }
    }
}

def notifyDiscord(String stageName = '', String step = '', String result = '') {
    result = result ?: currentBuild.currentResult
    try {
        try {
            withCredentials([string(credentialsId: 'sms-discord-webhook', variable: 'DISCORD_WEBHOOK_URL')]) {
                sendDiscord(stageName, step, result)
            }
        } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException missing) {
            try {
                withCredentials([file(credentialsId: 'sms-discord-webhook', variable: 'SMS_DISCORD_WEBHOOK_FILE')]) {
                    sendDiscord(stageName, step, result)
                }
            } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException missingFile) {
                if (!env.CHANGE_ID && !env.TAG_NAME && env.SMS_DISCORD_WEBHOOK_FILE &&
                    (env.SMS_CHECKOUT_BRANCH in ['quyen/admin', 'develop'])) {
                    sendDiscord(stageName, step, result)
                } else {
                    echo 'CI/CD Discord credential sms-discord-webhook is missing or inaccessible. Use Secret text or Secret file.'
                }
            }
        }
    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
        throw interrupted
    } catch (Exception ignored) {
        echo 'CI/CD Discord notifier could not run. Check credential binding, Python and the Jenkins agent.'
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
                script {
                    def checkedOut = checkout(scm)
                    env.SMS_CHECKOUT_BRANCH = (
                        env.BRANCH_NAME ?: checkedOut.GIT_BRANCH ?: env.GIT_BRANCH ?: ''
                    ).replaceFirst(/^refs\/(remotes\/|heads\/)/, '').replaceFirst(/^origin\//, '')
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

                    echo "Building commit: ${env.IMAGE_TAG} on ${env.SMS_CHECKOUT_BRANCH ?: 'unknown branch'}"
                    notifyDiscord('Checkout', '', 'STARTED')
                }
            }
        }

        stage('Check Environment') {
            post {
                unsuccessful {
                    script {
                        def detailFile = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-docker-ready.txt"
                        notifyDiscord('Check Environment', fileExists(detailFile) ? 'docker-ready' : '')
                    }
                }
            }

            steps {
                script {
                    configureDocker()
                    def checks = [
                        'Python': isUnix() ? 'python3 --version' : '"%PYTHON_EXE%" --version',
                        'Docker CLI': 'docker --version',
                        'Docker Compose': 'docker compose version',
                        'Java': 'java -version'
                    ]
                    checks.each { name, command ->
                        env.SMS_ENVIRONMENT_CHECK = "${name}: ${command}"
                        runLocalCommand(command)
                    }
                    env.SMS_ENVIRONMENT_CHECK = 'Connect to the configured Docker Linux Engine'
                    executeStep('docker-ready')
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
                        notifyDiscord('Validate Docker Compose', 'monitoring-config')
                    }
                }
            }

            steps {
                withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {
                    runLocalCommand(
                        'docker compose -f compose.yaml -f compose.monitoring.yaml --profile monitoring config --quiet'
                    )
                }
                executeStep('monitoring-config')
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
                            withSonarQubeEnv(installationName: 'sonarqube', envOnly: true) {
                                runPythonScript('scripts/sonar_gate_details.py')
                            }
                            error("SonarQube Quality Gate: ${gate.status}")
                        }
                        env.QUALITY_GATE_PASSED = 'true'
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
            post {
                success {
                    script {
                        env.SMS_CI_COMPLETED = 'true'
                    }
                }
            }

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
                        notifyDiscord('Deploy Local Docker', 'deploy-local')
                    }
                }
            }

            when {
                allOf {
                    expression {
                        return env.JOB_BASE_NAME != 'SMS-CICD-Server' &&
                            env.SMS_CHECKOUT_BRANCH in ['quyen/admin', 'develop']
                    }

                    not {
                        changeRequest()
                    }
                    not {
                        buildingTag()
                    }
                }
            }

            steps {
                script {
                    env.SMS_DEPLOY_STARTED = 'true'
                    env.SMS_DEPLOY_STAGE = 'Deploy Local Docker'
                    notifyDiscord('Deploy Local Docker', '', 'STARTED')
                    executeStep('deploy-local')
                    env.SMS_DEPLOY_COMPLETED = 'true'
                }
            }
        }

        stage('Deploy Server SSH') {
            when {
                allOf {
                    expression {
                        return env.JOB_BASE_NAME == 'SMS-CICD-Server' &&
                            env.SMS_CHECKOUT_BRANCH == (env.SMS_SERVER_BRANCH ?: 'develop')
                    }
                    not { changeRequest() }
                    not { buildingTag() }
                }
            }
            post {
                unsuccessful {
                    script {
                        notifyDiscord('Deploy Server SSH', 'publish')
                    }
                }
            }
            steps {
                script {
                    if (env.SMS_CI_COMPLETED != 'true' || env.QUALITY_GATE_PASSED != 'true') {
                        error('Server deployment requires successful CI and SonarQube Quality Gate.')
                    }
                    env.SMS_DEPLOY_STAGE = 'Deploy Server SSH'
                    env.SMS_DEPLOY_STARTED = 'true'
                    notifyDiscord('Deploy Server SSH', '', 'STARTED')
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'sms-server-ssh',
                                keyFileVariable: 'DEPLOY_KEY', usernameVariable: 'DEPLOY_USER'),
                        file(credentialsId: 'sms-server-known-hosts', variable: 'DEPLOY_KNOWN_HOSTS')
                    ]) {
                        runPythonScript('scripts/deploy.py check-target')
                        executeStep('publish')
                        runPythonScript('scripts/deploy.py remote --manifest artifacts/reports/release.json')
                    }
                    env.SMS_DEPLOY_COMPLETED = 'true'
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
                if (env.SMS_DEPLOY_COMPLETED == 'true') {
                    echo "${env.SMS_DEPLOY_STAGE} completed."
                } else {
                    echo "CI completed. Deployment skipped for branch: ${env.SMS_CHECKOUT_BRANCH ?: 'unknown'}"
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
                notifyDiscord(env.SMS_DEPLOY_COMPLETED == 'true' ? env.SMS_DEPLOY_STAGE : '')
                if (currentBuild.currentResult in ['FAILURE', 'UNSTABLE', 'ABORTED', 'NOT_BUILT']
                        && !env.CHANGE_ID && !env.TAG_NAME
                        && env.SMS_CHECKOUT_BRANCH in ['quyen/admin', 'develop']
                        && fileExists('scripts/jenkins_incident.py')) {
                    def ingestUrl = env.SMS_JENKINS_INGEST_URL
                    if (!ingestUrl && !isUnix() && env.JOB_BASE_NAME == 'SMS-CICD') {
                        ingestUrl = 'http://127.0.0.1:8088/api/ops/jenkins-incidents'
                    }
                    if (!ingestUrl) {
                        echo 'AI incident transfer skipped: set SMS_JENKINS_INGEST_URL in the Jenkins agent environment.'
                    } else try {
                        withCredentials([
                            usernamePassword(credentialsId: 'sms-jenkins-console-reader',
                                    usernameVariable: 'SMS_JENKINS_CONSOLE_USER',
                                    passwordVariable: 'SMS_JENKINS_CONSOLE_TOKEN'),
                            string(credentialsId: 'sms-jenkins-incident-token',
                                    variable: 'SMS_JENKINS_INGEST_TOKEN')
                        ]) {
                            withEnv(["SMS_JENKINS_BUILD_RESULT=${currentBuild.currentResult}",
                                     "SMS_JENKINS_INGEST_URL=${ingestUrl}"]) {
                                runPythonScript('scripts/jenkins_incident.py')
                            }
                        }
                    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
                        throw interrupted
                    } catch (org.jenkinsci.plugins.credentialsbinding.impl.CredentialNotFoundException missing) {
                        echo 'AI incident transfer requires Jenkins credentials sms-jenkins-console-reader and sms-jenkins-incident-token.'
                    } catch (Exception ignored) {
                        echo 'AI incident transfer did not complete. The console remains available in Jenkins for replay.'
                    }
                }
            }
        }
    }
}
