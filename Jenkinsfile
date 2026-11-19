// CI/CD tự động bằng Docker, chạy được trên Linux/WSL lẫn Windows. CHƯA deploy VPS.
// Thay thế Jenkinsfile cũ (bản cũ vẫn còn trong git: git show HEAD:Jenkinsfile).
def run(String cmd) { if (isUnix()) { sh cmd } else { bat cmd } }
def runSafe(String cmd) { try { run(cmd) } catch (e) { echo "Bỏ qua lỗi: ${e.message}" } }

pipeline {
  agent any
  options { timestamps(); timeout(time: 30, unit: 'MINUTES'); disableConcurrentBuilds() }
  // Jenkins local không nhận được webhook GitHub -> quét repo 2 phút/lần.
  triggers { pollSCM('H/2 * * * *') }
  parameters {
    booleanParam(name: 'RUN_SONAR', defaultValue: false, description: 'Bật khi đã có SonarQube server và đã cấu hình tên "sonarqube" trong Jenkins')
    booleanParam(name: 'RUN_STACK', defaultValue: true,  description: 'Chạy docker compose local sau khi build')
  }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Test') {
      parallel {
        stage('Backend') {
          steps { dir('backend') { script {
            if (isUnix()) { sh 'chmod +x mvnw && ./mvnw -B verify' } else { bat 'mvnw.cmd -B verify' }
          } } }
        }
        stage('Frontend') {
          steps { dir('frontend') { script { run('npm ci && npm run lint && npm run test:ci && npm run build') } } }
        }
        stage('Scripts') {
          steps { dir('scripts') { script { run((isUnix() ? 'python3' : 'python') + ' -m unittest discover -s tests') } } }
        }
      }
    }

    stage('Validate compose') {
      steps { script {
        run('docker compose -f compose.yaml config -q')
        run('docker compose -f compose.yaml -f compose.prod.yaml config -q')
      } }
    }

    stage('SonarQube') {
      when { expression { params.RUN_SONAR } }
      steps {
        withSonarQubeEnv('sonarqube') { script { run('sonar-scanner') } }
        timeout(time: 5, unit: 'MINUTES') { waitForQualityGate abortPipeline: true }
      }
    }

    stage('Docker build') {
      steps { script {
        run("docker build -t sms-backend:${env.BUILD_NUMBER} -t sms-backend:latest backend")
        run("docker build -t sms-frontend:${env.BUILD_NUMBER} -t sms-frontend:latest frontend")
      } }
    }

    stage('Run stack (local)') {
      when { expression { params.RUN_STACK } }
      steps { script {
        run('docker compose -f compose.yaml up -d --build')
        run('docker compose -f compose.yaml ps')
      } }
    }
  }
  post {
    failure { script { runSafe('docker compose -f compose.yaml logs --tail=100') } }
    cleanup { script { runSafe('docker image prune -f') } }
  }
}
