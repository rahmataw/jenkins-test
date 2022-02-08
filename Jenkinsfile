// PR: image tag naming variable
pipeline {
    agent {
        label 'ENDEUS'
    }
    options {
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }
    environment {
        BUCKET_NAME = 'kurio-deployment-history'
        GOOGLE_APPLICATION_CREDENTIALS = 'k8s/gs.json'
        PROJECT_NAME = 'alcatraz'
        PROJECT_URL = 'https://github.com/KurioApp/alcatraz.git'
        REGISTRY_URL = 'asia.gcr.io'
        REPOSITORY = 'kurio-dev/alcatraz'

        GITHUB_OAUTH = credentials('GITHUB_OAUTH')
        GS_SA = credentials('GS_SA')
        GS_SA_JSON = credentials('GS_SA_JSON')
        K8S_TOKEN = credentials('K8S_TOKEN')
        KK_SYSENG = credentials('KK_SYSENG')

        BUILD_TIMESTAMP = sh(returnStdout: true, script: 'date -u +"%Y-%m-%dT%H:%M:%SZ"').trim()
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short=8 HEAD").trim()
        TAG_NAME = gitTagName()
        TAG_MESSAGE = gitTagMessage()

    }
    stages {
        stage('Execute: make') {
            steps {
                script {
                    echo 'docker-compose -f docker-compose.jenkins.yaml run --rm builder'
                }
            }
            post {
              always {
                script {
                  echo 'docker-compose -f docker-compose.jenkins.yaml down'
                }
              }
            }
         }
        stage('Build and Push Image') {
          parallel {
            stage('Build and push image Staging') {
              when {
                expression {
                   return env.GIT_BRANCH == "origin/main"
                 }
              }
              steps {
                script {
                  echo 'docker login -u _json_key -p "${GS_SA}" https://${REGISTRY_URL}'

                  //def imageBuild = docker.build("${REGISTRY_URL}/${REPOSITORY}","-f k8s/Dockerfile .")
                  //imageBuild.push("${GIT_COMMIT_SHORT}")
                  //imageBuild.push("${GIT_COMMIT_SHORT}-${BUILD_NUMBER}")
                }
              }
            }
            stage('Build and push image Production') {
              when {
                tag "v*"
              }
              steps {
                script {
                  echo 'docker login -u _json_key -p "${GS_SA}" https://${REGISTRY_URL}'

                  //def imageBuild = docker.build("${REGISTRY_URL}/${REPOSITORY}","-f k8s/Dockerfile .")
                  //imageBuild.push("${TAG_NAME}")
                  //imageBuild.push("${TAG_NAME}-${BUILD_NUMBER}")
                }
              }
            }
          }
        }

        stage('Scan vulnerability') {
          parallel {
            stage('Scan vulnerability on Staging') {
              when {
                expression {
                   return env.GIT_BRANCH == "origin/main"
                 }
              }
              environment { IMAGE_TAG = "${GIT_COMMIT_SHORT}-${BUILD_NUMBER}" }
              steps {
                script {
                  echo 'cp ${GS_SA_JSON} k8s/gs.json'
                  echo 'docker-compose -f docker-compose.jenkins.yaml run --rm trivy'
                }
              }
              post { 
                always { 
                  echo 'docker rmi ${REGISTRY_URL}/${REPOSITORY}:${GIT_COMMIT_SHORT}'
                  echo 'docker rmi ${REGISTRY_URL}/${REPOSITORY}:${GIT_COMMIT_SHORT}-${BUILD_NUMBER}'
                  echo 'rm -rf k8s/gs.json'
                }
              }
            }
            stage('Scan vulnerability on Production') {
              when {
                tag "v*"
              }
              environment { IMAGE_TAG = "${TAG_NAME}-${BUILD_NUMBER}" }
              steps {
                script {
                  echo 'cp ${GS_SA_JSON} k8s/gs.json'
                  echo 'docker-compose -f docker-compose.jenkins.yaml run --rm trivy'
                }
              }
              post { 
                always { 
                  echo 'docker rmi ${REGISTRY_URL}/${REPOSITORY}:${GIT_COMMIT_SHORT}'
                  echo 'docker rmi ${REGISTRY_URL}/${REPOSITORY}:${GIT_COMMIT_SHORT}-${BUILD_NUMBER}'
                  echo 'rm -rf k8s/gs.json'
                }
              }
            }
          }
        }

        stage('Configure deployment') {
          parallel {
            stage('Configure deployment on Staging') {
              when {
                expression {
                   return env.GIT_BRANCH == "origin/main"
                 }
              }
              environment { 
                IMAGE_TAG = "${GIT_COMMIT_SHORT}-${BUILD_NUMBER}"
                ENV_INFRA = 'staging'
              }
              steps {
                script {
                  echo 'curl  --header "Authorization: token ${KK_SYSENG}" \
                        --header "Accept: application/vnd.github.v3.raw" \
                        --remote-name \
                        --location https://api.github.com/repos/pigletsquid/Kube/contents/k8s-endeus/${PROJECT_NAME}/${ENV_INFRA}/deployment.yaml'
                  echo '''sed -i "s/TMP_IMAGE_VERSION/${IMAGE_TAG}/g" deployment.yaml'''
                  echo '''sed -i "s/TMP_DEP_CHECKSUM/$(sha256sum deployment.yaml|cut -d ' ' -f 1)/g" deployment.yaml'''
                }
              }
            }
            stage('Configure deployment on Production') {
              when {
                tag "v*"
              }
              environment {
                IMAGE_TAG = "${TAG_NAME}-${BUILD_NUMBER}"
                ENV_INFRA = 'production'
              }
              steps {
                script {
                  echo 'curl --header "Authorization: token ${KK_SYSENG}" \
                        --header "Accept: application/vnd.github.v3.raw" \
                        --remote-name \
                        --location https://api.github.com/repos/pigletsquid/Kube/contents/k8s-endeus/${PROJECT_NAME}/${ENV_INFRA}/deployment.yaml'
                  echo '''sed -i "s/TMP_IMAGE_VERSION/${IMAGE_TAG}/g" deployment.yaml'''
                  echo '''sed -i "s/TMP_DEP_CHECKSUM/$(sha256sum deployment.yaml|cut -d ' ' -f 1)/g" deployment.yaml'''
                }
              }
            }
          }
        }
        stage('Deploy Apps') {
          parallel {
            stage('Deploy Apps: Staging') {
              when {
                expression {
                   return env.GIT_BRANCH == "origin/main"
                 }
              }
              environment { ENV_INFRA = 'staging' }
              steps {
                script {
                  withKubeCredentials([
                    [credentialsId: 'K8S_TOKEN', serverUrl: 'https://103.50.216.99:6443'] ]) {
                      sh 'kubectl get pod -n staging'
                    }
                  echo 'Upload deployment manifest to GCS'
                  echo 'cp ${GS_SA_JSON} k8s/gs.json'
                  echo 'docker run -e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
                      -v ${PWD}:/tmp/builder/ \
                      -w /tmp/builder --rm gcr.io/cloud-builders/gcs-uploader \
                      --location gs://${BUCKET_NAME}/${PROJECT_NAME}/${ENV_INFRA}/${BUILD_TIMESTAMP}/ deployment.yaml'
                }
              }
              post { 
                always { 
                  echo 'rm -rf k8s/gs.json'
                }
              }
            }
            stage('Deploy Apps: Production') {
              when {
                tag "v*"
              }
              environment { ENV_INFRA = 'staging' }
              steps {
                script {
                  withKubeCredentials([
                    [credentialsId: 'K8S_TOKEN', serverUrl: 'https://103.50.216.100:6443'] ]) {
                      sh 'kubectl get pod -n production'
                    }
                  echo 'Upload deployment manifest to GCS'
                  echo 'cp ${GS_SA_JSON} k8s/gs.json'
                  echo 'docker run -e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
                  -v ${PWD}:/tmp/builder/ \
                  -w /tmp/builder --rm gcr.io/cloud-builders/gcs-uploader \
                  --location gs://${BUCKET_NAME}/${PROJECT_NAME}/${ENV_INFRA}/${BUILD_TIMESTAMP}/ deployment.yaml'
                }
              }
              post { 
                always { 
                  echo 'rm -rf k8s/gs.json'
                }
              }
            }
         }
        }
    }
    post {
    success {
      script {
        env.GIT_COMMIT_MSG = sh (script: 'git log -1 --pretty=%B ${GIT_COMMIT}', returnStdout: true).trim()
        def attachments = [
          [
          		"fallback": "$JOB_NAME execution #$BUILD_NUMBER",
          		"color": "danger",
          		"fields": [
          			[
          				"title": "Failed execution",
          				"value": "<$BUILD_URL|Execution #$BUILD_NUMBER $GIT_COMMIT_MSG>",
          				"short": true
                ],
          			[
          				"title": "Pipeline",
          				"value": "<$JOB_URL|$JOB_NAME>",
          				"short": true
                ],
          			[
          				"title": "Branch",
          				"value": "$GIT_BRANCH",
          				"short": true
                ],
          			[
          				"title": "Project",
          				"value": "<$PROJECT_URL|$PROJECT_NAME>",
          				"short": true
                ]
          		]
          ]
        ]
        slackSend (tokenCredentialId: 'jenkins-notif-test', teamDomain: 'jenkins-notifgroup', channel: '#jenkins', botUser: true, color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", attachments: attachments)
      }
    }

    failure {
      slackSend (tokenCredentialId: 'jenkins-notif-test', teamDomain: 'jenkins-notifgroup', channel: '#jenkins', botUser: true, color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
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
