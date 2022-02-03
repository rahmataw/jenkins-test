pipeline {
    agent {
        label 'ENDEUS'
    }
    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }
    environment {
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short=8 HEAD").trim()
        //TAG_NAME = gitTagName()
        //TAG_MESSAGE = gitTagMessage()
    }
    stages {
        stage('Deploy Apps') {
          parallel {
            stage('Deploy Apps: Staging') {
              when {
                expression {
                   return env.GIT_BRANCH == "origin/main"
                 }
              }
              steps {
                script {
                  sh 'echo "Deploy apps to staging on branch master and tag ${TAG_NAME}"'
                }
              }
            }
           stage('Deploy Apps: Production') {
              when {
                buildingTag()
              }
              steps {
                script {
                  sh 'echo "Deploy apps to production with tag ${TAG_NAME}"'
                }
              }
           }
         }
        }
    }
}
