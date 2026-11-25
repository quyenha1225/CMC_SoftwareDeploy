def diagnosticStages() {
    return [
        'Checkout',
        'Check Environment',
        'Prepare',
        'Validate Docker Compose',
        'Backend Test',
        'Frontend Test',
        'SonarQube Analysis',
        'SonarQube Quality Gate',
        'Build Docker Images',
        'MySQL Integration Tests',
        'Export Scan Images',
        'Dependency and Image Scan',
        'Secret Scan',
        'Deploy Local Docker',
        'Deploy Server SSH',
    ]
}

def stageValue(String name, String kind) {
    switch (name) {
        case 'Checkout':
            if (kind == 'state') return env.SMS_STAGE_Checkout
            if (kind == 'detail') return env.SMS_STAGE_Checkout_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Checkout_ERROR
            break
        case 'Check Environment':
            if (kind == 'state') return env.SMS_STAGE_Check_Environment
            if (kind == 'detail') return env.SMS_STAGE_Check_Environment_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Check_Environment_ERROR
            break
        case 'Prepare':
            if (kind == 'state') return env.SMS_STAGE_Prepare
            if (kind == 'detail') return env.SMS_STAGE_Prepare_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Prepare_ERROR
            break
        case 'Backend Test':
            if (kind == 'state') return env.SMS_STAGE_Backend_Test
            if (kind == 'detail') return env.SMS_STAGE_Backend_Test_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Backend_Test_ERROR
            break
        case 'Frontend Test':
            if (kind == 'state') return env.SMS_STAGE_Frontend_Test
            if (kind == 'detail') return env.SMS_STAGE_Frontend_Test_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Frontend_Test_ERROR
            break
        case 'Validate Docker Compose':
            if (kind == 'state') return env.SMS_STAGE_Validate_Docker_Compose
            if (kind == 'detail') return env.SMS_STAGE_Validate_Docker_Compose_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Validate_Docker_Compose_ERROR
            break
        case 'SonarQube Analysis':
            if (kind == 'state') return env.SMS_STAGE_SonarQube_Analysis
            if (kind == 'detail') return env.SMS_STAGE_SonarQube_Analysis_DETAIL
            if (kind == 'error') return env.SMS_STAGE_SonarQube_Analysis_ERROR
            break
        case 'SonarQube Quality Gate':
            if (kind == 'state') return env.SMS_STAGE_SonarQube_Quality_Gate
            if (kind == 'detail') return env.SMS_STAGE_SonarQube_Quality_Gate_DETAIL
            if (kind == 'error') return env.SMS_STAGE_SonarQube_Quality_Gate_ERROR
            break
        case 'Build Docker Images':
            if (kind == 'state') return env.SMS_STAGE_Build_Docker_Images
            if (kind == 'detail') return env.SMS_STAGE_Build_Docker_Images_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Build_Docker_Images_ERROR
            break
        case 'MySQL Integration Tests':
            if (kind == 'state') return env.SMS_STAGE_MySQL_Integration_Tests
            if (kind == 'detail') return env.SMS_STAGE_MySQL_Integration_Tests_DETAIL
            if (kind == 'error') return env.SMS_STAGE_MySQL_Integration_Tests_ERROR
            break
        case 'Export Scan Images':
            if (kind == 'state') return env.SMS_STAGE_Export_Scan_Images
            if (kind == 'detail') return env.SMS_STAGE_Export_Scan_Images_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Export_Scan_Images_ERROR
            break
        case 'Dependency and Image Scan':
            if (kind == 'state') return env.SMS_STAGE_Dependency_and_Image_Scan
            if (kind == 'detail') return env.SMS_STAGE_Dependency_and_Image_Scan_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Dependency_and_Image_Scan_ERROR
            break
        case 'Secret Scan':
            if (kind == 'state') return env.SMS_STAGE_Secret_Scan
            if (kind == 'detail') return env.SMS_STAGE_Secret_Scan_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Secret_Scan_ERROR
            break
        case 'Deploy Local Docker':
            if (kind == 'state') return env.SMS_STAGE_Deploy_Local_Docker
            if (kind == 'detail') return env.SMS_STAGE_Deploy_Local_Docker_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Deploy_Local_Docker_ERROR
            break
        case 'Deploy Server SSH':
            if (kind == 'state') return env.SMS_STAGE_Deploy_Server_SSH
            if (kind == 'detail') return env.SMS_STAGE_Deploy_Server_SSH_DETAIL
            if (kind == 'error') return env.SMS_STAGE_Deploy_Server_SSH_ERROR
            break
        default:
            return null
    }
    return null
}

def setStageValue(String name, String kind, String value) {
    switch (name) {
        case 'Checkout':
            if (kind == 'state') env.SMS_STAGE_Checkout = value
            else if (kind == 'detail') env.SMS_STAGE_Checkout_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Checkout_ERROR = value
            break
        case 'Check Environment':
            if (kind == 'state') env.SMS_STAGE_Check_Environment = value
            else if (kind == 'detail') env.SMS_STAGE_Check_Environment_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Check_Environment_ERROR = value
            break
        case 'Prepare':
            if (kind == 'state') env.SMS_STAGE_Prepare = value
            else if (kind == 'detail') env.SMS_STAGE_Prepare_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Prepare_ERROR = value
            break
        case 'Backend Test':
            if (kind == 'state') env.SMS_STAGE_Backend_Test = value
            else if (kind == 'detail') env.SMS_STAGE_Backend_Test_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Backend_Test_ERROR = value
            break
        case 'Frontend Test':
            if (kind == 'state') env.SMS_STAGE_Frontend_Test = value
            else if (kind == 'detail') env.SMS_STAGE_Frontend_Test_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Frontend_Test_ERROR = value
            break
        case 'Validate Docker Compose':
            if (kind == 'state') env.SMS_STAGE_Validate_Docker_Compose = value
            else if (kind == 'detail') env.SMS_STAGE_Validate_Docker_Compose_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Validate_Docker_Compose_ERROR = value
            break
        case 'SonarQube Analysis':
            if (kind == 'state') env.SMS_STAGE_SonarQube_Analysis = value
            else if (kind == 'detail') env.SMS_STAGE_SonarQube_Analysis_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_SonarQube_Analysis_ERROR = value
            break
        case 'SonarQube Quality Gate':
            if (kind == 'state') env.SMS_STAGE_SonarQube_Quality_Gate = value
            else if (kind == 'detail') env.SMS_STAGE_SonarQube_Quality_Gate_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_SonarQube_Quality_Gate_ERROR = value
            break
        case 'Build Docker Images':
            if (kind == 'state') env.SMS_STAGE_Build_Docker_Images = value
            else if (kind == 'detail') env.SMS_STAGE_Build_Docker_Images_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Build_Docker_Images_ERROR = value
            break
        case 'MySQL Integration Tests':
            if (kind == 'state') env.SMS_STAGE_MySQL_Integration_Tests = value
            else if (kind == 'detail') env.SMS_STAGE_MySQL_Integration_Tests_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_MySQL_Integration_Tests_ERROR = value
            break
        case 'Export Scan Images':
            if (kind == 'state') env.SMS_STAGE_Export_Scan_Images = value
            else if (kind == 'detail') env.SMS_STAGE_Export_Scan_Images_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Export_Scan_Images_ERROR = value
            break
        case 'Dependency and Image Scan':
            if (kind == 'state') env.SMS_STAGE_Dependency_and_Image_Scan = value
            else if (kind == 'detail') env.SMS_STAGE_Dependency_and_Image_Scan_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Dependency_and_Image_Scan_ERROR = value
            break
        case 'Secret Scan':
            if (kind == 'state') env.SMS_STAGE_Secret_Scan = value
            else if (kind == 'detail') env.SMS_STAGE_Secret_Scan_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Secret_Scan_ERROR = value
            break
        case 'Deploy Local Docker':
            if (kind == 'state') env.SMS_STAGE_Deploy_Local_Docker = value
            else if (kind == 'detail') env.SMS_STAGE_Deploy_Local_Docker_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Deploy_Local_Docker_ERROR = value
            break
        case 'Deploy Server SSH':
            if (kind == 'state') env.SMS_STAGE_Deploy_Server_SSH = value
            else if (kind == 'detail') env.SMS_STAGE_Deploy_Server_SSH_DETAIL = value
            else if (kind == 'error') env.SMS_STAGE_Deploy_Server_SSH_ERROR = value
            break
        default:
            echo "CI evidence limitation: unknown stage ${name}."
    }
}

def recordStage(String name, String state) {
    if (stageValue(name, 'state') != state) {
        setStageValue(name, 'state', state)
        echo "CI stage ${state}: ${name}"
        if (env.SMS_TIMING_DIR) {
            def fileName = name.replaceAll('[^A-Za-z0-9]+', '-')
            def timestamp = new Date().getTime()
            if (state == 'started') {
                writeFile file: "${env.SMS_TIMING_DIR}/stage-${fileName}.start",
                    text: "${name}\n${timestamp}\n", encoding: 'UTF-8'
            } else {
                writeFile file: "${env.SMS_TIMING_DIR}/stage-${fileName}.end",
                    text: "${state}\n${timestamp}\n", encoding: 'UTF-8'
            }
        }
    }
}

def recordStageFailure(String name, String step = '') {
    recordStage(name, 'failed')
    if (name == 'SonarQube Quality Gate') {
        setStageValue(name, 'detail', env.SMS_QUALITY_GATE_CHECK ?: '')
    } else if (name == 'Check Environment') {
        setStageValue(name, 'detail', env.SMS_ENVIRONMENT_CHECK ?: '')
    }
    if (!step) {
        return
    }
    try {
        def detail = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-${step}.txt"
        if (fileExists(detail)) {
            setStageValue(name, 'detail', readFile(detail).trim().take(250))
        }
        if (fileExists(detail + '.error')) {
            setStageValue(name, 'error', readFile(file: detail + '.error', encoding: 'UTF-8').trim())
        }
    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
        throw interrupted
    } catch (Exception ignored) {
        echo "CI evidence limitation: detail for ${name} was unavailable."
    }
}

def runPythonScript(String arguments) {
    if (isUnix()) {
        sh "python3 ${arguments}"
    } else {
        bat "call \"${env.WORKSPACE}/scripts/jenkins-python.cmd\" ${arguments}"
    }
}

def executeStep(String step, String deploymentCommand = '') {
    def detailFile = "${pwd(tmp: true)}/sms-${env.BUILD_NUMBER}-${step}.txt"
    withEnv(["IMAGE_TAG=${env.IMAGE_TAG ?: 'local'}", "SMS_CI_DETAIL_FILE=${detailFile}",
             "SMS_CI_TIMING_FILE=${env.SMS_TIMING_DIR}/work-${step}.jsonl"]) {
        def command = deploymentCommand ? "--deploy ${deploymentCommand}" : step
        runPythonScript("scripts/jenkins_reports.py ${command}")
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
        recordStageFailure(stageName, step)
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
    def stageSummary = diagnosticStages().collect {
        def state = stageValue(it, 'state') ?: (result == 'SUCCESS' ? 'skipped' : 'not run')
        def check = stageValue(it, 'detail')
        return "${state.toUpperCase()} | ${it}" + (check ? " | ${check}" : '')
    }.join('\n')
    def errors = diagnosticStages().collect { stageValue(it, 'error') }.findAll { it }.join('\n')
    withEnv(["SMS_BUILD_RESULT=${result}", "SMS_EVENT_STAGE=${stageName}", "SMS_EVENT_CHECK=${detail}",
             "SMS_STAGE_SUMMARY=${stageSummary}", "SMS_BUILD_DURATION_MS=${currentBuild.duration}",
             "SMS_BUILD_STARTED_MS=${currentBuild.startTimeInMillis}",
             "SMS_STAGE_ERRORS=${errors}"]) {
        def notifier = "sms-discord-${stageName.replaceAll('[^A-Za-z0-9]+', '-') ?: 'summary'}.py"
        dir(pwd(tmp: true)) {
            writeFile file: notifier, text: '''
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError
from urllib.parse import parse_qsl, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

env = os.environ
result = env["SMS_BUILD_RESULT"]
stage = env.get("SMS_EVENT_STAGE")
commit = env.get("IMAGE_TAG", "")
if re.fullmatch(r"[0-9a-f]{40}", commit):
    commit = f"[{commit[:12]}](https://github.com/quyenha1225/CMC_SoftwareDeploy/commit/{commit})"
duration = int(env.get("SMS_BUILD_DURATION_MS", 0)) / 1000
if not duration and env.get("SMS_BUILD_STARTED_MS"):
    duration = max(0, time.time() - int(env["SMS_BUILD_STARTED_MS"]) / 1000)
fields = [
    f"{env.get('JOB_NAME', 'Jenkins')} #{env.get('BUILD_NUMBER', '?')}",
    f"Duration: {int(duration)}s",
    "Branch: " + (env.get("SMS_CHECKOUT_BRANCH") or env.get("BRANCH_NAME") or "unknown"),
    "Commit: " + (commit or "unknown"),
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

summary = env.get("SMS_SUCCESS_REPORTS", "").splitlines()
if env.get("QUALITY_GATE_PASSED") == "true":
    summary.append("SonarQube Quality Gate: OK")
if env.get("SMS_IMAGES_BUILT") == "true":
    summary.append("Docker images: built")
if env.get("SMS_IMAGES_PUBLISHED") == "true":
    summary.append("Docker images: published")
if result == "ABORTED":
    fields.append("Build cancelled. See Jenkins for the cancellation source.")
if result == "NOT_BUILT":
    fields.append("Build did not execute. See Jenkins for details.")
embed_fields = []
if env.get("SMS_STAGE_SUMMARY") and result != "STARTED":
    embed_fields.append({"name": "Stages", "value": env["SMS_STAGE_SUMMARY"][:800]})
if env.get("SMS_STAGE_ERRORS") and result != "STARTED":
    embed_fields.insert(0, {"name": "Evidence", "value": env["SMS_STAGE_ERRORS"][:800]})
if summary:
    embed_fields.append({"name": "Checks and images", "value": chr(10).join(summary)[:800]})
payload = {
    "username": "SMS Jenkins",
    "allowed_mentions": {"parse": []},
    "embeds": [{"title": "Jenkins " + result + (" - " + stage if stage else ""),
                "description": chr(10).join(fields)[:2800],
                "color": {"SUCCESS": 0x2ecc71, "FAILURE": 0xe74c3c, "UNSTABLE": 0xf1c40f,
                          "STARTED": 0x3498db}.get(result, 0x7f8c8d),
                "fields": embed_fields}],
}

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

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
    opener = build_opener(NoRedirect)
    for attempt in range(2):
        try:
            with opener.open(request, timeout=4) as response:
                message = json.load(response)
                print(f"Discord notification delivered (HTTP {response.status}, message {message['id']}).")
            break
        except HTTPError as error:
            delay = float(error.headers.get("Retry-After", "1"))
            if attempt or error.code not in (429, 503) or not 0 <= delay <= 2:
                raise
            time.sleep(delay)
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
    if (result == 'SUCCESS' && fileExists('scripts/jenkins_reports.py')) {
        try {
            withEnv(["SMS_BUILD_STARTED_MS=${currentBuild.startTimeInMillis}"]) {
                env.SMS_SUCCESS_REPORTS = isUnix()
                    ? sh(script: 'python3 scripts/jenkins_reports.py --summary', returnStdout: true).trim()
                    : bat(script: '@call scripts/jenkins-python.cmd scripts/jenkins_reports.py --summary', returnStdout: true).trim()
            }
        } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException interrupted) {
            throw interrupted
        } catch (Exception ignored) {
            echo 'CI evidence limitation: success report details unavailable.'
        }
    }
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

def transferIncident() {
    if (env.SMS_INCIDENT_ATTEMPTED != 'true' && currentBuild.currentResult in ['FAILURE', 'UNSTABLE', 'ABORTED', 'NOT_BUILT']
            && !env.CHANGE_ID && !env.TAG_NAME
            && env.SMS_CHECKOUT_BRANCH in ['quyen/admin', 'develop']
            && fileExists('scripts/jenkins_incident.py')) {
        env.SMS_INCIDENT_ATTEMPTED = 'true'
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
                         "SMS_JENKINS_INGEST_URL=${ingestUrl}",
                         "SMS_BUILD_STARTED_MS=${currentBuild.startTimeInMillis}",
                         "SMS_BUILD_DURATION_MS=${currentBuild.duration}"]) {
                    runPythonScript('scripts/jenkins_incident.py')
                    env.SMS_INCIDENT_ACCEPTED = 'true'
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

pipeline {
    agent {
        label 'sms-docker'
    }

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
            defaultValue: true,
            description: 'Chạy SonarQube trên build nhánh. Có thể tắt khi chạy thủ công.'
        )
    }

    stages {

        stage('Checkout') {
            post {
                success { script { recordStage('Checkout', 'passed') } }
                aborted { script { recordStage('Checkout', 'aborted') } }
                unstable { script { recordStage('Checkout', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Checkout')
                    }
                }
            }

            steps {
                script {
                    env.SMS_TIMING_DIR = "${pwd(tmp: true)}/sms-timings-${env.BUILD_NUMBER}"
                    recordStage('Checkout', 'started')
                    def checkedOut = checkout(scm)
                    ['artifacts/reports', 'artifacts/ci-assets', 'backend/target/surefire-reports',
                     'backend/target/site/jacoco', 'frontend/coverage'].each { path ->
                        dir(path) { deleteDir() }
                    }
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
                    env.SMS_REPORTS_READY = 'true'

                    echo "Building commit: ${env.IMAGE_TAG} on ${env.SMS_CHECKOUT_BRANCH ?: 'unknown branch'}"
                    notifyDiscord('Checkout', '', 'STARTED')
                }
            }
        }

        stage('Check Environment') {
            post {
                success { script { recordStage('Check Environment', 'passed') } }
                aborted { script { recordStage('Check Environment', 'aborted') } }
                unstable { script { recordStage('Check Environment', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Check Environment', 'preflight')
                    }
                }
            }

            steps {
                script { recordStage('Check Environment', 'started') }
                script {
                    configureDocker()
                    env.SMS_ENVIRONMENT_CHECK = 'Validate the Jenkins agent and Docker Linux Engine'
                    executeStep('preflight')
                    env.SMS_DOCKER_READY = 'true'
                }
            }
        }

        stage('Prepare') {
            post {
                success { script { recordStage('Prepare', 'passed') } }
                aborted { script { recordStage('Prepare', 'aborted') } }
                unstable { script { recordStage('Prepare', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Prepare', 'prepare')
                    }
                }
            }

            steps {
                script { recordStage('Prepare', 'started') }
                executeStep('prepare')
            }
        }

        stage('Validate Docker Compose') {
            post {
                success { script { recordStage('Validate Docker Compose', 'passed') } }
                aborted { script { recordStage('Validate Docker Compose', 'aborted') } }
                unstable { script { recordStage('Validate Docker Compose', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Validate Docker Compose', 'monitoring-config')
                    }
                }
            }

            steps {
                script { recordStage('Validate Docker Compose', 'started') }
                withEnv(["IMAGE_TAG=${env.IMAGE_TAG}"]) {
                    runLocalCommand(
                        'docker compose -f compose.yaml -f compose.monitoring.yaml --profile monitoring config --quiet'
                    )
                }
                executeStep('monitoring-config')
            }
        }

        stage('Tests') {
            failFast true
            parallel {

                stage('Backend Test') {
                    post {
                        success { script { recordStage('Backend Test', 'passed') } }
                        aborted { script { recordStage('Backend Test', 'aborted') } }
                        unstable { script { recordStage('Backend Test', 'unstable') } }
                    }
                    steps {
                        script { recordStage('Backend Test', 'started') }
                        script {
                            executeParallelStep('Backend Test', 'backend')
                        }
                    }
                }

                stage('Frontend Test') {
                    post {
                        success { script { recordStage('Frontend Test', 'passed') } }
                        aborted { script { recordStage('Frontend Test', 'aborted') } }
                        unstable { script { recordStage('Frontend Test', 'unstable') } }
                    }
                    steps {
                        script { recordStage('Frontend Test', 'started') }
                        script {
                            executeParallelStep('Frontend Test', 'frontend')
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            post {
                success { script { recordStage('SonarQube Analysis', 'passed') } }
                aborted { script { recordStage('SonarQube Analysis', 'aborted') } }
                unstable { script { recordStage('SonarQube Analysis', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('SonarQube Analysis', 'sonar')
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
                script { recordStage('SonarQube Analysis', 'started') }
                withSonarQubeEnv('sonarqube') {
                    executeStep('sonar')
                }
            }
        }

        stage('SonarQube Quality Gate') {
            post {
                success { script { recordStage('SonarQube Quality Gate', 'passed') } }
                aborted { script { recordStage('SonarQube Quality Gate', 'aborted') } }
                unstable { script { recordStage('SonarQube Quality Gate', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('SonarQube Quality Gate')
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
                script { recordStage('SonarQube Quality Gate', 'started') }
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
                success { script { recordStage('Build Docker Images', 'passed') } }
                aborted { script { recordStage('Build Docker Images', 'aborted') } }
                unstable { script { recordStage('Build Docker Images', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Build Docker Images', 'build')
                    }
                }
            }

            steps {
                script { recordStage('Build Docker Images', 'started') }
                // Build backend, frontend và migration.
                // Build context được giữ ở thư mục gốc repository.
                executeStep('build')
                script { env.SMS_IMAGES_BUILT = 'true' }
            }
        }

        stage('MySQL Integration Tests') {
            post {
                success { script { recordStage('MySQL Integration Tests', 'passed') } }
                aborted { script { recordStage('MySQL Integration Tests', 'aborted') } }
                unstable { script { recordStage('MySQL Integration Tests', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('MySQL Integration Tests', 'mysql')
                    }
                }
            }

            steps {
                script { recordStage('MySQL Integration Tests', 'started') }
                // Database CI riêng, không sử dụng database local.
                executeStep('mysql')
            }
        }

        stage('Export Scan Images') {
            post {
                success { script { recordStage('Export Scan Images', 'passed') } }
                aborted { script { recordStage('Export Scan Images', 'aborted') } }
                unstable { script { recordStage('Export Scan Images', 'unstable') } }
                failure { script { recordStageFailure('Export Scan Images', 'scan-export') } }
            }
            steps {
                script { recordStage('Export Scan Images', 'started') }
                executeStep('scan-export')
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
                    post {
                        success { script { recordStage('Dependency and Image Scan', 'passed') } }
                        aborted { script { recordStage('Dependency and Image Scan', 'aborted') } }
                        unstable { script { recordStage('Dependency and Image Scan', 'unstable') } }
                    }
                    steps {
                        script { recordStage('Dependency and Image Scan', 'started') }
                        script {
                            executeParallelStep('Dependency and Image Scan', 'security')
                        }
                    }
                }

                stage('Secret Scan') {
                    post {
                        success { script { recordStage('Secret Scan', 'passed') } }
                        aborted { script { recordStage('Secret Scan', 'aborted') } }
                        unstable { script { recordStage('Secret Scan', 'unstable') } }
                    }
                    steps {
                        script { recordStage('Secret Scan', 'started') }
                        script {
                            executeParallelStep('Secret Scan', 'secrets')
                        }
                    }
                }
            }
        }

        stage('Deploy Local Docker') {
            post {
                success { script { recordStage('Deploy Local Docker', 'passed') } }
                aborted { script { recordStage('Deploy Local Docker', 'aborted') } }
                unstable { script { recordStage('Deploy Local Docker', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Deploy Local Docker', 'deploy-local')
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
                script { recordStage('Deploy Local Docker', 'started') }
                script {
                    if (env.SMS_CI_COMPLETED != 'true' || env.QUALITY_GATE_PASSED != 'true') {
                        error('Local deployment requires successful CI and SonarQube Quality Gate.')
                    }
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
                success { script { recordStage('Deploy Server SSH', 'passed') } }
                aborted { script { recordStage('Deploy Server SSH', 'aborted') } }
                unstable { script { recordStage('Deploy Server SSH', 'unstable') } }
                failure {
                    script {
                        recordStageFailure('Deploy Server SSH', env.SMS_SERVER_CHECK ?: '')
                    }
                }
            }
            steps {
                script { recordStage('Deploy Server SSH', 'started') }
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
                        env.SMS_SERVER_CHECK = 'server-preflight'
                        executeStep('server-preflight', 'check-target')
                        env.SMS_SERVER_CHECK = 'publish'
                        executeStep('publish')
                        env.SMS_IMAGES_PUBLISHED = 'true'
                        env.SMS_SERVER_CHECK = 'server-rollout'
                        executeStep('server-rollout', 'remote --manifest artifacts/reports/release.json')
                    }
                    env.SMS_DEPLOY_COMPLETED = 'true'
                }
            }
        }
    }

    post {

        always {
            script {
                if (env.SMS_REPORTS_READY == 'true') {
                    catchError(buildResult: 'FAILURE', catchInterruptions: false,
                               message: 'Could not remove this build-specific temporary scan archives') {
                        executeStep('cleanup-assets')
                    }

                    if (env.SMS_DEPLOY_STAGE == 'Deploy Local Docker' &&
                            env.SMS_DEPLOY_COMPLETED != 'true' && env.SMS_DOCKER_READY == 'true') {
                        catchError(buildResult: 'FAILURE', catchInterruptions: false,
                                   message: 'Could not collect logs from the local deployment') {
                            executeStep('deploy-local-logs')
                        }
                    }
                    try {
                        junit(
                            testResults: 'backend/target/surefire-reports/*.xml,frontend/coverage/junit.xml',
                            allowEmptyResults: true
                        )
                    } finally {
                        try {
                            withEnv(["SMS_BUILD_RESULT=${currentBuild.currentResult}"]) {
                                runPythonScript('scripts/jenkins_reports.py --timings')
                            }
                        } finally {
                            archiveArtifacts(
                                artifacts: 'artifacts/reports/**/*,backend/target/site/jacoco/**/*,frontend/coverage/**/*',
                                allowEmptyArchive: true
                            )
                        }
                    }
                } else {
                    echo 'CI evidence limitation: checkout and report initialization did not complete.'
                }
            }
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
        }

        cleanup {
            script {
                transferIncident()
                if (env.SMS_INCIDENT_ACCEPTED != 'true') {
                    notifyDiscord()
                }
            }
        }
    }
}
