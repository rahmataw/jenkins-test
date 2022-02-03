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
        TAG_NAME = gitTagName()
        TAG_MESSAGE = gitTagMessage()
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
                expression { 
                  return env.TAG_NAME ==~ /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/
                }
              }
              steps {
                script {
                  sh 'echo "Deploy apps to production with tag ${TAG_NAME}"'
                  sh 'cat README.md'
                }
              }
           }
         }
        }
    }
}

String gitTagName() {
    commit = getCommit()
    if (commit) {
        desc = sh(script: "git describe --tags ${commit} --always", returnStdout: true)?.trim()
        if (isTag(desc)) {
            return desc
        }
    }
    return null
}

/** @return The tag message, or `null` if the current commit isn't a tag. */
String gitTagMessage() {
    name = gitTagName()
    msg = sh(script: "git tag -n10000 -l ${name}", returnStdout: true)?.trim()
    if (msg) {
        return msg.substring(name.size()+1, msg.size())
    }
    return null
}

String getCommit() {
    return sh(script: 'git rev-parse HEAD', returnStdout: true)?.trim()
}

@NonCPS
boolean isTag(String desc) {
    match = desc =~ /.+-[0-9]+-g[0-9A-Fa-f]{6,}$/
    result = !match
    match = null // prevent serialisation
    return result
}
