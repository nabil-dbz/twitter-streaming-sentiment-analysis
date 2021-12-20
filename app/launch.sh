# !/bin/bash
# A simple script that runs the different parts of the application of the final project. 

OPTION=$1
KAFKA_DIR="/kafka/"

if [[ "$OPTION" == "start-zookeeper" ]]
then
    printf "##########################################################################\n"
    printf "########################### Starting Zookeeper ###########################\n"
    printf "##########################################################################\n"
    $KAFKA_DIR/bin/zookeeper-server-start.sh $KAFKA_DIR/config/zookeeper.properties
elif [[ "$OPTION" == "start-kafka" ]]
then
    printf "##########################################################################\n"
    printf "######################### Starting Kafka Broker ##########################\n"
    printf "##########################################################################\n"
    $KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/server.properties
elif [[ "$OPTION" == "deploy-lambda" ]]
then
    printf "##########################################################################\n"
    printf "####################### Deploying Infrastructure #########################\n"
    printf "##########################################################################\n"
    cd infrastructure
    terraform init
    terraform apply -auto-approve
    cd ..
elif [[ "$OPTION" == "clean" ]]
then
    printf "##########################################################################\n"
    printf "####################### Destroying Infrastructure ########################\n"
    printf "##########################################################################\n"
    cd infrastructure
    terraform destroy -auto-approve
    rm -rf sentiment-analysis-pkg
    rm -f sentiment-analysis-pkg.zip
    cd ..
    printf "##########################################################################\n"
    printf "########################## Cleaning Build File ###########################\n"
    printf "##########################################################################\n"
    rm -rf producer/producer
    rm -rf consumer/consumer
elif [[ "$OPTION" == "launch-producer" ]]
then
    printf "##########################################################################\n"
    printf "########################### Launching Producer ###########################\n"
    printf "##########################################################################\n"
    TOPIC_NAME=$2
    N_PARTITION=$3
    TWEETS_FILE="tweets-samples.txt"
    cd producer
    javac -cp "$KAFKA_DIR/libs/*":. TweetsProducer.java -d ./
    java -cp "$KAFKA_DIR/libs/*":. producer.TweetsProducer $TWEETS_FILE $TOPIC_NAME $N_PARTITION
    cd ..
elif [[ "$OPTION" == "create-topic" ]]
then
    printf "##########################################################################\n"
    printf "########################## Creating Kafka Topic ##########################\n"
    printf "##########################################################################\n"
    TOPIC_NAME=$2
    N_PARTITION=$3
    $KAFKA_DIR/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions $N_PARTITION --topic $TOPIC_NAME
elif [[ "$OPTION" == "launch-consumer" ]]
then
    printf "##########################################################################\n"
    printf "########################### Launching Consumer ###########################\n"
    printf "##########################################################################\n"
    TOPIC_NAME=$2
    cd infrastructure
    LAMBDA_GW=$(terraform output -raw base_url)
    cd ../consumer
    javac -cp "$KAFKA_DIR/libs/*":. TweetsConsumer.java -d ./
    java -cp "$KAFKA_DIR/libs/*":. consumer.TweetsConsumer $TOPIC_NAME my-group $LAMBDA_GW
    cd ..
else
    printf "ERROR: \tUknown Option. Please choose of these options:\n"
    printf "\tdeploy-lambda: \t\tto deploy the infrastructure\n"
    printf "\tclean: \t\t\tto destroy the allocated ressources\n"
    printf "\tstart-zookeeper: \tto start the Kafka zookeeper\n"
    printf "\tstart-kafka: \t\tto start the Kafka broker\n"
    printf "\tcreate-topic: \t\tto create a kafka topic\n"
    printf "\tlaunch-producer: \tto launch the TweetsProducer\n"
    printf "\tlaunch-consumer: \tto launch the TweetsConsumer\n"
fi
