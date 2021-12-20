package producer;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.LinkedList;
import java.util.Properties;
import java.util.Queue;
import java.util.Scanner;

import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class TweetsProducer {
    public static void main(String[] args) throws Exception {

        if (args.length < 3) {
            System.out.println("Usage: producer <filename> <topic> <npartition>");
            return;
        }

        Queue<String> tweets = new LinkedList<>();
        try {
            File myFile = new File(args[0].toString());
            Scanner myReader = new Scanner(myFile);
            
            while (myReader.hasNextLine()) {
                String data = myReader.nextLine();
                tweets.add(data);
            }

            myReader.close();
        } catch (FileNotFoundException e) {
            System.out.println("The file is not found.");
            e.printStackTrace();
            return;
        }

        System.out.println("All the tweets have been read successfully!");
        Thread.sleep(2000);
        
        // Assign topicName to string variable
        String topicName = args[1].toString();
        
        // Create instance for properties to access producer configs   
        Properties props = new Properties();
        
        // Assign localhost id
        props.put("bootstrap.servers", "localhost:9092");
        
        // Set acknowledgements for producer requests.      
        props.put("acks", "all");
      
        // If the request fails, the producer can automatically retry,
        props.put("retries", 0);
      
        // Specify buffer size in config
        props.put("batch.size", 16384);
      
        // Reduce the no of requests less than 0   
        props.put("linger.ms", 1);
      
        // The buffer.memory controls the total amount of memory available to the producer for buffering.   
        props.put("buffer.memory", 33554432);
      
        props.put("key.serializer", 
            "org.apache.kafka.common.serialization.StringSerializer");
         
        props.put("value.serializer", 
            "org.apache.kafka.common.serialization.StringSerializer");
      
        Producer<String, String> producer = new KafkaProducer<String, String>(props);

        Integer counter = 0;
        while (!tweets.isEmpty()) {
            for (int partitionId = 0; partitionId < Integer.parseInt(args[2]); partitionId++) {
                if (tweets.isEmpty()) {
                    continue;
                }
                String currentTweet = tweets.poll();
                producer.send(new ProducerRecord<String, String>(topicName, partitionId, Integer.toString(counter), currentTweet));
                System.out.println("The tweet that has been produced is: " + currentTweet);
                Thread.sleep(1000);
            }
        }

        System.out.println("Tweets sent successfully!");
        producer.close();
    }
}
