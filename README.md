# Automating Jenkins Setup with Docker and Jenkins Configuration as Code (JCasC)

## Introduction

Jenkins is a widely-used open-source automation server, commonly employed to streamline continuous integration (CI) and
continuous deployment (CD) workflows. Configuring Jenkins typically involves a manual process through a web-based setup
wizard, which can be slow, error-prone, and non-scalable. This project aims to automate the installation and
configuration of Jenkins using Docker and the Jenkins Configuration as Code (JCasC) approach.

JCasC leverages the Configuration as Code plugin, enabling you to define your desired Jenkins configuration state in one
or more YAML files, eliminating the need for the setup wizard. Upon initialization, the Configuration as Code plugin
configures Jenkins according to the specified configuration files, reducing configuration time and minimizing human
errors.

## Step 1: Disabling the Setup Wizard

To create a Docker image of Jenkins with JCasC, follow these steps:

1. Create a Dockerfile with the following lines:

```dockerfile
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
```

These lines download the latest Jenkins version and deploy it without prompting for the admin key.

2. Build the Docker image using the following command:

```sh
docker build -t jenkins:jcasc .
```

You should see an output similar to:

```sh
Successfully built 7566b15547af
Successfully tagged jenkins:jcasc
```

3. Test the image by running it with:

```sh
docker run --name jenkins --rm -p 8080:8080 jenkins:jcasc
```

You should see:

```text
... hudson.WebAppMain$3#run: Jenkins is fully up and running
```

4. Verify that Jenkins is up and running by accessing it in your web browser:

```text
http://server_ip:8080
```

You can also log in to the container to check if the necessary packages were installed correctly:

```sh
docker exec -it container_name /bin/bash
docker exec -u 0 -it container_name /bin/bash # To log in as Root
```

After logging in to the Jenkins web console, you may encounter two warning messages. The first one indicates that you
haven't configured the Jenkins URL, and the second one informs you that you haven't set up any authentication and
authorization schemes, allowing anonymous users full access to your Jenkins instance.

With the setup wizard disabled, the subsequent steps will guide you through using JCasC to replicate these
functionalities. Continue modifying your Dockerfile and JCasC configuration until the red notification icon disappears.

## Step 2: Installing Jenkins Plugins

To use JCasC, you need to install the Configuration as Code plugin. Currently, no plugins are installed. You can confirm
this by navigating to http://server_ip:8080/pluginManager/installed.

Now we’re going to modify your Dockerfile to pre-install a selection of plugins, including the Configuration as Code
plugin.
Obs: If you are not sure what is the plugin name, you can go to Jenkins -> Plugins and search for the plugin you are
looking for, click to open the repository in Jenkins web pages specification and find the ID name.
All the plugins listed will be tagged with the latest version, but you can also specify a desired version, for example:
iD:Version
git: 2.4
Create a text file containing a list of plugins to install
Copy it into the Docker image
Run the jenkins-plugin-cli binary to install the plugins

Add into the Dockerfile

```text
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
```

If you are still running the Jenkins container, stop it.
Now build the image again using building command mentioned earlier.

## Step 3 — Specifying the Jenkins URL

The Jenkins URL is a URL for the Jenkins instance that is routable from the devices that need to access it. For example,
if you’re deploying Jenkins as a node inside a private network, the Jenkins URL may be a private IP address, or a DNS
name that is resolvable using a private DNS server. For this tutorial, it is sufficient to use the server’s IP address (
or 127.0.0.1 for local hosts) to form the Jenkins URL.

You can set the Jenkins URL on the web interface by navigating to server_ip:8080/configure and entering the value in the
Jenkins URL field under the Jenkins Location heading. Here’s how to achieve the same using the Configuration as Code
plugin:

Define the desired configuration of your Jenkins instance inside a declarative configuration file (which we’ll call
casc.yaml).
Copy the configuration file into the Docker image (just as you did for your plugins.txt file).
Set the CASC_JENKINS_CONFIG environment variable to the path of the configuration file to instruct the Configuration as
Code plugin to read it.
First, create a new file named casc.yaml and send it to the container. Also declare the variable.

Now build the image again using building command mentioned earlier.

## Step 4 — Creating a User

So far, your setup has not implemented any authentication and authorization mechanisms. In this step, you will set up a
basic, password-based authentication scheme and create a new user named admin.

Start by opening your casc.yaml file:

In the context of Jenkins, a security realm is simply an authentication mechanism; the local security realm means to use
basic authentication where users must specify their ID/username and password. Other security realms exist and are
provided by plugins. For instance, the LDAP plugin allows you to use an existing LDAP directory service as the
authentication mechanism. The GitHub Authentication plugin allows you to use your GitHub credentials to authenticate via
OAuth.

Note that you’ve also specified allowsSignup: false, which prevents anonymous users from creating an account through the
web interface.

Finally, instead of hard-coding the user ID and password, you are using variables whose values can be filled in at
runtime. This is important because one of the benefits of using JCasC is that the casc.yaml file can be committed into
source control; if you were to store user passwords in plaintext inside the configuration file, you would have
effectively compromised the credentials. Instead, variables are defined using the ${VARIABLE_NAME} syntax, and its value
can be filled in using an environment variable of the same name, or a file of the same name that’s placed inside the
/run/secrets/ directory within the container image.

Next, build a new image to incorporate the changes made to the casc.yaml file:

Then, run the updated Jenkins image whilst passing in the JENKINS_ADMIN_ID and JENKINS_ADMIN_PASSWORD environment
variables via the --env option (replace <password> with a password of your choice):

```commandline
docker run --name jenkins --rm -p 8080:8080 --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD=password jenkins:jcasc
```

## Step 5 — Setting Up Authorization

After setting up the security realm, you must now configure the authorization strategy. In this step, you will use the
Matrix Authorization Strategy plugin to configure permissions for your admin user.

By default, the Jenkins core installation provides us with three authorization strategies:

unsecured: every user, including anonymous users, have full permissions to do everything
legacy: emulates legacy Jenkins (prior to v1.164), where any users with the role admin is given full permissions, whilst
other users, including anonymous users, are given read access.

loggedInUsersCanDoAnything: anonymous users are given either no access or read-only access. Authenticated users have
full permissions to do everything. By allowing actions only for authenticated users, you are able to have an audit trail
of which users performed which actions.

All of these authorization strategies are very crude, and does not afford granular control over how permissions are set
for different users. Instead, you can use the Matrix Authorization Strategy plugin that was already included in your
plugins.txt list. This plugin affords you a more granular authorization strategy, and allows you to set user permissions
globally, as well as per project/job.

The Matrix Authorization Strategy plugin allows you to use the jenkins.authorizationStrategy.globalMatrix.permissions
JCasC property to set global permissions. To use it, open your casc.yaml file:

Next, build a new image to incorporate the changes made to the casc.yaml file:

```commandline
docker run --name jenkins --rm -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --env JENKINS_ADMIN_ID=admin --env JENKINS_ADMIN_PASSWORD="password" jenkins:jcasc
```

You can easily customize all your desired settings in Jenkins Configuration as Code (JCasC). After configuring your
Jenkins environment to your preferences, navigate to the "Manage Jenkins" section and explore the "Jenkins as Code"
feature. Here, you can download the Jenkins YAML configuration file.

Once you have the configuration file, you can further enhance your casc.yaml by specifying various parameters. For
example, you can define settings for tools like Git, JDK, and Maven. JCasC will automatically apply these settings,
streamlining your tool configurations.

## Notes:

The docker image jenkins_jcasc:v3 is running with a docker engine configure.
Make sure you are inside the folder that contains the Dockerfile. Very important detail: In the Dockerfile line 14 - It
is expecting a group number for the docker group:

# groupadd -g 991 docker && \

This group need to be exactly the docker ID number running in your local host. The Jenkins container will connect the
docker sock with your local env socks, like a symbolic link. When Jenkins container runs docker service, it will run it
from your local env. So, you need to check it docker group is already defined in your local system.

```text
cat /etc/group | grep docker
or
getent group docker
e.g output
docker:x:991:user
```

You can run now the image giving a connection between your docker to the container passing "-v" parameter.
```commandline
docker run -d -p 8080:8080 --env JENKINS_ADMIN_ID=admin -v /var/run/docker.sock:/var/run/docker.sock --env
JENKINS_ADMIN_PASSWORD=password112rr -p 50000:50000 alexsimple/jenkins_jcasc:v3
```
