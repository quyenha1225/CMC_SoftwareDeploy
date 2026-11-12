// Configure a trusted Jenkins agent with Java 21, Node 22+, Python 3 and Linux Docker.
def executeStep(String step) {
    if (isUnix()) { sh "python3 scripts/ci.py ${step}" }
    else { bat "call scripts\\jenkins-python.cmd scripts/ci.py ${step}" }
}
def deployEnvironment(String target) {
    withCredentials([sshUserPrivateKey(credentialsId: 'vps-ssh', keyFileVariable: 'DEPLOY_KEY', usernameVariable: 'DEPLOY_USER'), file(credentialsId: 'vps-known-hosts', variable: 'DEPLOY_KNOWN_HOSTS')]) {
        withEnv(["DEPLOY_TARGET=${target}"]) {
            if (isUnix()) { sh 'python3 scripts/deploy.py remote --manifest artifacts/reports/release.json' }
            else { bat 'call scripts\\jenkins-python.cmd scripts/deploy.py remote --manifest artifacts/reports/release.json' }
        }
    }
}
pipeline {
    agent { label 'sms-docker' }
    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 90, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }
    parameters {
        string(name: 'REGISTRY_NAMESPACE', defaultValue: '', description: 'Example: ghcr.io/your-organization; required for trusted release builds')
        booleanParam(name: 'DEPLOY_STAGING', defaultValue: false, description: 'Enable after VPS staging is provisioned')
        booleanParam(name: 'DEPLOY_PRODUCTION', defaultValue: false, description: 'Only main/release tag, with manual approval')
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = isUnix() ? sh(script:'git rev-parse HEAD',returnStdout:true).trim() : bat(script:'@git rev-parse HEAD',returnStdout:true).trim()
                    env.REGISTRY_NAMESPACE = params.REGISTRY_NAMESPACE
                }
            }
        }
        stage('Prepare') { steps { script { executeStep('prepare') } } }
        stage('Backend Test + Coverage') { steps { script { executeStep('backend') } } }
        stage('Frontend Lint + Test + Build') { steps { script { executeStep('frontend') } } }
        stage('SonarQube') {
            when { expression { !env.CHANGE_FORK } }
            steps { withSonarQubeEnv('sonarqube') { script { executeStep('sonar') } } }
        }
        stage('Quality Gate') {
            when { expression { !env.CHANGE_FORK } }
            steps {
                timeout(time: 15, unit: 'MINUTES') { waitForQualityGate abortPipeline: true }
                script { env.QUALITY_GATE_PASSED = 'true' }
            }
        }
        stage('Image Build') { steps { script { executeStep('build') } } }
        stage('MySQL Integration + Restore + Restart') { steps { script { executeStep('mysql') } } }
        stage('Dependency + Secret + Image Scan') { steps { script { executeStep('security'); executeStep('secrets') } } }
        stage('Publish Immutable Images') {
            when { allOf { not { changeRequest() }; anyOf { branch 'develop'; branch 'main'; buildingTag() } } }
            steps {
                withCredentials([usernamePassword(credentialsId:'registry-push',usernameVariable:'REGISTRY_USER',passwordVariable:'REGISTRY_PASSWORD')]) {
                    script {
                        env.DOCKER_CONFIG = pwd() + '/.local/docker-auth'
                        if (isUnix()) { sh 'python3 scripts/registry_login.py' }
                        else { bat 'call scripts\\jenkins-python.cmd scripts/registry_login.py' }
                        try { executeStep('publish') }
                        finally {
                            if (isUnix()) { sh 'python3 scripts/registry_login.py --logout' }
                            else { bat 'call scripts\\jenkins-python.cmd scripts/registry_login.py --logout' }
                        }
                    }
                }
            }
        }
        stage('Deploy Staging + Smoke') {
            when { allOf { branch 'develop'; expression { params.DEPLOY_STAGING }; not { changeRequest() } } }
            steps { script { deployEnvironment('staging') } }
        }
        stage('Production Approval') {
            when { allOf { expression { params.DEPLOY_PRODUCTION }; not { changeRequest() }; anyOf { branch 'main'; tag 'v*' } } }
            steps {
                timeout(time:30,unit:'MINUTES') {
                    script {
                        def approval = input message:'Approve scanned digests, verified backup/restore and compatible DB migration?', submitter:'sms-release-approvers', submitterParameter:'RELEASE_APPROVER'
                        env.RELEASE_APPROVER = approval instanceof Map ? approval.RELEASE_APPROVER : approval.toString()
                    }
                }
            }
        }
        stage('Deploy Production + Smoke') {
            when { allOf { expression { params.DEPLOY_PRODUCTION }; not { changeRequest() }; anyOf { branch 'main'; tag 'v*' } } }
            steps { script { deployEnvironment('production') } }
        }
    }
    post {
        always {
            junit allowEmptyResults:true, testResults:'backend/target/surefire-reports/*.xml,frontend/coverage/junit.xml'
            archiveArtifacts allowEmptyArchive:true, artifacts:'artifacts/reports/**,backend/target/site/jacoco/**,frontend/coverage/lcov.info'
            // Passwords, private files, .env, SQL dumps and demo credentials are never archived.
        }
        failure { echo 'Pipeline failed. No subsequent publish/deploy stages are allowed.' }
        success { echo 'All executed gates passed. External deployment runs only when configured/approved.' }
    }
}
