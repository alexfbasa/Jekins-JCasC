FROM jenkins/jenkins:lts
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
COPY casc.yaml /var/jenkins_home/casc.yaml

ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
ENV JAVA_HOME_17 /usr/lib/jvm/java-17-openjdk-amd64
ENV MAVEN_HOME /usr/share/maven
ENV PATH $MAVEN_HOME/bin:$JAVA_HOME_17/bin:$PATH

USER root
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    maven

USER jenkins
