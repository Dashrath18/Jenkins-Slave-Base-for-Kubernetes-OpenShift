FROM centos:7

ENV HOME=/home/jenkins
# In future chnage the verison tag to have latest remoting jar
ARG VERSION=4.7

# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y swap -- remove fakesystemd -- install systemd systemd-libs
RUN yum -y update; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*; \
rm -f /etc/systemd/system/*.wants/*; \
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*; \
rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN yum -y install epel-release
RUN yum -y install git sudo openssh-server openssh-clients curl wget yum zip unzip

RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers

# Install Java 8
RUN yum install -y wget java-1.8.0-openjdk && yum install -y java-1.8.0-openjdk-devel && \
    echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | tee -a /etc/profile && source /etc/profile && echo $JAVA_HOME

# Add Jenkins user and group
RUN groupadd -g 10000 jenkins \
    && useradd -d $HOME -u 10000 -g jenkins jenkins

# Install jenkins jnlp
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod 755 /usr/local/bin/jenkins-slave && chown jenkins:jenkins /usr/local/bin/jenkins-slave

RUN mkdir /home/jenkins/.jenkins \
    && mkdir -p /home/jenkins/agent \
    && chown -R jenkins:jenkins /home/jenkins

VOLUME /home/jenkins/.jenkins
VOLUME /home/jenkins/agent

# Systemd volume
VOLUME ["/sys/fs/cgroup"]

WORKDIR /home/jenkins

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]