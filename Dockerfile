FROM jenkins/jenkins:lts
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

COPY casc.yaml /usr/share/jenkins/ref/casc.yaml
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/casc.yaml

ENV JAVA_HOME_17 /usr/lib/jvm/java-17-openjdk-amd64
ENV MAVEN_HOME /usr/share/maven
ENV PATH $MAVEN_HOME/bin:$JAVA_HOME_17/bin:$PATH

USER root

RUN mkdir -p /tmp/download && \
    curl -L https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz > docker-18.03.1-ce.tgz && \
    tar -xzf docker-18.03.1-ce.tgz -C /tmp/download && \
    rm -rf /tmp/download/docker/dockerd && \
    mv /tmp/download/docker/docker* /usr/local/bin/ && \
    rm -rf /tmp/download && \
    groupadd -g 991 docker && \
    gpasswd -a jenkins docker && \
    usermod -aG docker jenkins

RUN apt-get update && apt-get install -y \
    awscli \
    openjdk-17-jdk \
    maven

RUN apt-get install -y ansible

USER jenkins
