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
        'Publish Verified Release',
        'Import Verified Release',
        'Deploy Local Docker',
        'Deploy Server SSH',
    ]
}

def stageKey(String name, String kind) {
    if (!(name in diagnosticStages()) || !(kind in ['state', 'detail', 'error'])) {
        error("Unknown CI diagnostic field: ${name}/${kind}")
    }
    return 'SMS_STAGE_' + name.replaceAll('[^A-Za-z0-9]+', '_') +
        (kind == 'state' ? '' : '_' + kind.toUpperCase())
}

def stageValue(String name, String kind) {
    return env[stageKey(name, kind)]
}

def setStageValue(String name, String kind, String value) {
    env[stageKey(name, kind)] = value
}

def runsCI() {
    return env.SMS_PIPELINE_MODE in ['FULL', 'CI_ONLY']
}

def releaseBranch() {
    return env.SMS_CHECKOUT_BRANCH in ['quyen/admin', 'develop'] &&
        !env.CHANGE_ID && !env.TAG_NAME
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
        runPythonScript('scripts/jenkins_notify.py')
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

    // Configure GitHub push / fallback polling on the CI owner job ONLY.
    // FULL runs CI once and deploys automatically. The server job is reserved for explicit retries.

    parameters {
        choice(name: 'PIPELINE_MODE', choices: ['FULL', 'CI_ONLY', 'DEPLOY_LOCAL_ONLY', 'DEPLOY_SERVER_ONLY'],
               description: 'FULL automatically deploys after CI passes; CD-only requires an explicit verified release.')
        string(name: 'RELEASE_BUILD', defaultValue: '', description: 'Exact SMS-CICD build number for CD-only')
        string(name: 'RELEASE_SHA', defaultValue: '', description: 'Full commit SHA for CD-only')
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
                    env.SMS_PIPELINE_MODE = params.PIPELINE_MODE ?: 'FULL'
                    if (env.JOB_NAME == 'SMS-CICD-Server' && env.SMS_PIPELINE_MODE != 'DEPLOY_SERVER_ONLY') {
                        error('Server job accepts only DEPLOY_SERVER_ONLY; disable its SCM triggers.')
                    }
                    if (env.SMS_PIPELINE_MODE == 'DEPLOY_SERVER_ONLY' && env.JOB_NAME != 'SMS-CICD-Server') {
                        error('Use the dedicated server deployment job.')
                    }
                    if (env.SMS_PIPELINE_MODE in ['FULL', 'DEPLOY_LOCAL_ONLY'] && env.JOB_NAME != 'SMS-CICD') {
                        error('Local deployment requires the SMS-CICD job.')
                    }
                    if (env.SMS_PIPELINE_MODE in ['DEPLOY_LOCAL_ONLY', 'DEPLOY_SERVER_ONLY']) {
                        if (!(params.RELEASE_BUILD ==~ /[1-9][0-9]{0,9}/) || !(params.RELEASE_SHA ==~ /[0-9a-f]{40}/)) {
                            error('Provide an exact release build number and full SHA.')
                        }
                        env.RELEASE_BUILD = params.RELEASE_BUILD
                        env.RELEASE_SHA = params.RELEASE_SHA
                    }
                    def checkedOut = checkout(scm)
                    ['artifacts/reports', 'artifacts/ci-assets', 'backend/target/surefire-reports',
                     'backend/target/site/jacoco', 'backend/target/sonar', 'frontend/coverage'].each { path ->
                        dir(path) { deleteDir() }
                    }
                    env.SMS_CHECKOUT_BRANCH = (
                        env.BRANCH_NAME ?: checkedOut.GIT_BRANCH ?: env.GIT_BRANCH ?: ''
                    ).replaceFirst(/^refs\/(remotes\/|heads\/)/, '').replaceFirst(/^origin\//, '')
                    if (!runsCI()) {
                        if (!releaseBranch() || (env.SMS_PIPELINE_MODE == 'DEPLOY_SERVER_ONLY' &&
                                env.SMS_CHECKOUT_BRANCH != (env.SMS_SERVER_BRANCH ?: 'quyen/admin'))) {
                            error('Deployment branch is not allowed.')
                        }
                        // Check membership in the configured branch before detaching to the exact release.
                        if (isUnix()) {
                            sh "git merge-base --is-ancestor ${env.RELEASE_SHA} HEAD && git checkout --detach ${env.RELEASE_SHA}"
                        } else {
                            bat "git merge-base --is-ancestor ${env.RELEASE_SHA} HEAD && git checkout --detach ${env.RELEASE_SHA}"
                        }
                    }
                    if (env.SMS_PIPELINE_MODE == 'FULL' && !releaseBranch()) {
                        env.SMS_PIPELINE_MODE = 'CI_ONLY'
                        echo 'Unapproved branch, PR or tag: CI only; no deployment.'
                    }
                    if (env.SMS_PIPELINE_MODE == 'FULL' && !params.RUN_SONAR) {
                        error('FULL requires enabled SonarQube.')
                    }
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
                    executeStep(runsCI() ? 'preflight' : 'docker-ready')
                    env.SMS_DOCKER_READY = 'true'
                }
            }
        }

        stage('Prepare') {
            when { expression { runsCI() } }
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
            when { expression { runsCI() } }
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
            when { expression { runsCI() } }
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
                        runsCI() && params.RUN_SONAR
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
                        runsCI() && params.RUN_SONAR
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
                        withSonarQubeEnv(installationName: 'sonarqube', envOnly: true) {
                            withEnv(['SMS_RECORD_SONAR_EVIDENCE=true']) {
                                runPythonScript('scripts/sonar_gate_details.py')
                            }
                        }
                        env.QUALITY_GATE_PASSED = 'true'
                    }
                }
            }
        }

        stage('Build Docker Images') {
            when { expression { runsCI() } }
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
            when { expression { runsCI() } }
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
            when { expression { runsCI() } }
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
            when { expression { runsCI() } }
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

        stage('Publish Verified Release') {
            when {
                expression {
                    runsCI() && releaseBranch() && env.JOB_NAME == 'SMS-CICD' && params.RUN_SONAR
                }
            }
            post {
                success { script { recordStage('Publish Verified Release', 'passed') } }
                aborted { script { recordStage('Publish Verified Release', 'aborted') } }
                failure { script { recordStageFailure('Publish Verified Release', 'seal-release') } }
            }
            steps {
                script {
                    recordStage('Publish Verified Release', 'started')
                    if (currentBuild.currentResult != 'SUCCESS' || env.SMS_CI_COMPLETED != 'true' ||
                            env.QUALITY_GATE_PASSED != 'true') {
                        error('Release requires every CI gate to pass.')
                    }
                    executeStep('publish')
                    executeStep('seal-release')
                    archiveArtifacts artifacts: 'artifacts/reports/verified-release.json,artifacts/reports/*.json,backend/target/surefire-reports/TEST-*.xml,frontend/coverage/junit.xml',
                        allowEmptyArchive: false, fingerprint: true
                    env.SMS_IMAGES_PUBLISHED = 'true'
                }
            }
        }

        stage('Import Verified Release') {
            when { expression { !runsCI() } }
            post {
                success { script { recordStage('Import Verified Release', 'passed') } }
                aborted { script { recordStage('Import Verified Release', 'aborted') } }
                failure { script { recordStageFailure('Import Verified Release', 'promote-release') } }
            }
            steps {
                script {
                    recordStage('Import Verified Release', 'started')
                    withCredentials([usernamePassword(credentialsId: 'sms-jenkins-console-reader',
                        usernameVariable: 'SMS_JENKINS_CONSOLE_USER', passwordVariable: 'SMS_JENKINS_CONSOLE_TOKEN')]) {
                        executeStep('promote-release')
                    }
                    env.SMS_RELEASE_IMPORTED = 'true'
                    env.QUALITY_GATE_PASSED = 'true'
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
                        if (env.SMS_PIPELINE_MODE == 'FULL' && env.SMS_IMAGES_PUBLISHED == 'true') {
                            writeFile file: 'artifacts/reports/local-deploy-failed.json',
                                text: """{"commit":"${env.IMAGE_TAG}","build":"${env.BUILD_NUMBER}","stage":"Deploy Local Docker"}"""
                        }
                    }
                }
            }

            when {
                allOf {
                    expression {
                        return env.JOB_NAME == 'SMS-CICD' &&
                            env.SMS_PIPELINE_MODE in ['FULL', 'DEPLOY_LOCAL_ONLY'] && releaseBranch()
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
                    if ((env.SMS_IMAGES_PUBLISHED != 'true' && env.SMS_RELEASE_IMPORTED != 'true') || env.QUALITY_GATE_PASSED != 'true') {
                        error('Local deployment requires a verified release.')
                    }
                    env.SMS_DEPLOY_STARTED = 'true'
                    env.SMS_DEPLOY_STAGE = 'Deploy Local Docker'
                    notifyDiscord('Deploy Local Docker', '', 'STARTED')
                    lock(resource: 'sms-deploy-local') {
                        executeStep('deploy-local')
                    }
                    env.SMS_DEPLOY_COMPLETED = 'true'
                }
            }
        }

        stage('Deploy Server SSH') {
            when {
                allOf {
                    expression {
                        return releaseBranch() && env.SMS_CHECKOUT_BRANCH == (env.SMS_SERVER_BRANCH ?: 'quyen/admin') &&
                            ((env.JOB_NAME == 'SMS-CICD' && env.SMS_PIPELINE_MODE == 'FULL') ||
                             (env.JOB_NAME == 'SMS-CICD-Server' && env.SMS_PIPELINE_MODE == 'DEPLOY_SERVER_ONLY'))
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
                        if (env.SMS_PIPELINE_MODE == 'FULL' && env.SMS_IMAGES_PUBLISHED == 'true') {
                            writeFile file: 'artifacts/reports/server-deploy-failed.json',
                                text: """{"commit":"${env.IMAGE_TAG}","build":"${env.BUILD_NUMBER}","stage":"Deploy Server SSH"}"""
                        }
                    }
                }
            }
            steps {
                script { recordStage('Deploy Server SSH', 'started') }
                script {
                    if (env.QUALITY_GATE_PASSED != 'true' ||
                            (env.SMS_PIPELINE_MODE == 'FULL' ? env.SMS_IMAGES_PUBLISHED != 'true' : env.SMS_RELEASE_IMPORTED != 'true')) {
                        error('Server deployment requires a verified release.')
                    }
                    // Local success must never be reported as server success if SSH fails.
                    env.SMS_DEPLOY_COMPLETED = 'false'
                    env.SMS_DEPLOY_STAGE = 'Deploy Server SSH'
                    env.SMS_DEPLOY_STARTED = 'true'
                    notifyDiscord('Deploy Server SSH', '', 'STARTED')
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'sms-server-ssh',
                                keyFileVariable: 'DEPLOY_KEY', usernameVariable: 'DEPLOY_USER'),
                        file(credentialsId: 'sms-server-known-hosts', variable: 'DEPLOY_KNOWN_HOSTS')
                    ]) {
                        lock(resource: 'sms-deploy-server') {
                            env.SMS_SERVER_CHECK = 'server-preflight'
                            executeStep('server-preflight', 'check-target')
                            env.SMS_SERVER_CHECK = 'server-rollout'
                            executeStep('server-rollout', 'remote --manifest artifacts/reports/release.json')
                        }
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
                                artifacts: 'artifacts/reports/**/*,backend/target/site/jacoco/**/*,backend/target/surefire-reports/TEST-*.xml,frontend/coverage/**/*',
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
            echo "${env.SMS_PIPELINE_MODE} completed for ${env.IMAGE_TAG ?: 'unknown commit'}."

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
