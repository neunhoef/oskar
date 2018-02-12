pipeline {
    agent {
        label 'linux&&test'
    }
    parameters {
        string(name: 'ARANGODB_BRANCH', defaultValue: 'devel', description: 'Branch of main repository',)
        string(name: 'ENTERPRISE_BRANCH', defaultValue: 'devel', description: 'Branch of enterprise repository',)
    }
    stages {
        stage('Test') {
            steps {
                withEnv([
                    "ARANGODB_BRANCH=${params.ARANGODB_BRANCH}",
                    "ENTERPRISE_BRANCH=${params.ENTERPRISE_BRANCH}",
                ]) {
                    sh "jenkins/runPRtest.fish"
                }
            }
        }
    }

    post {
        always {
            sh "jenkins/moveResultsToWorkspace.fish"
        }
    }
}
