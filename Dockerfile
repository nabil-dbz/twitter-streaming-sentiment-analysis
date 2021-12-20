FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y \
    python3.8 \
    python-dev \
    software-properties-common \
    python3-pip \
    virtualenv \
    curl \
    nano \
    git

# Install Java
RUN apt update && apt install -y wget && apt install -y default-jdk

# Install Zookeeper
RUN wget https://dlcdn.apache.org/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz &&\
    tar -xzf apache-zookeeper-3.7.0-bin.tar.gz &&\
    mv apache-zookeeper-3.7.0-bin zookeeper &&\
    mkdir zookeeper/data &&\
    echo "tickTime=2000" > zookeeper/conf/zoo.cfg &&\
    echo "dataDir=/zookeeper/data" >> zookeeper/conf/zoo.cfg &&\
    echo "clientPort=2181" >> zookeeper/conf/zoo.cfg &&\
    echo "initLimit=5" >> zookeeper/conf/zoo.cfg &&\
    echo "syncLimit=2" >> zookeeper/conf/zoo.cfg 

# Install Apache Kafka
RUN wget https://archive.apache.org/dist/kafka/0.9.0.0/kafka_2.11-0.9.0.0.tgz &&\
    tar -xzf kafka_2.11-0.9.0.0.tgz &&\
    mv kafka_2.11-0.9.0.0 kafka && \
    sed "s/-XX:+PrintGCTimeStamps //g" -i /kafka/bin/kafka-run-class.sh && \
    sed "s/-XX:+PrintGCDateStamps //g" -i /kafka/bin/kafka-run-class.sh

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get install terraform

COPY ./app /app
WORKDIR /app
