package consumer;

import java.util.Properties;
import java.util.Arrays;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.ConsumerRecord;

import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

public class TweetsConsumer {

    // Method to encode a string value using `UTF-8` encoding scheme
    private static String encodeValue(String value) {
        try {
            return URLEncoder.encode(value, StandardCharsets.UTF_8.toString());
        } catch (UnsupportedEncodingException ex) {
            throw new RuntimeException(ex.getCause());
        }
    }

    public static void main(String[] args) throws Exception {
        if(args.length < 3){
           System.out.println("Usage: consumer <topic> <groupname> <sentiment-analysis-utl>");
           return;
        }
        // Kafka consumer configuration settings
        String topicName = args[0].toString();
        String groupName = args[1].toString();
        String sentimentAnalysisUrl = args[2].toString();
        Properties props = new Properties();
        
        props.put("bootstrap.servers", "localhost:9092");
        props.put("group.id", groupName);
        props.put("enable.auto.commit", "true");
        props.put("auto.commit.interval.ms", "2000");
        props.put("session.timeout.ms", "30000");
        props.put("auto.offset.reset", "earliest");
        props.put("key.deserializer", 
           "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", 
           "org.apache.kafka.common.serialization.StringDeserializer");
        KafkaConsumer<String, String> consumer = new KafkaConsumer<String, String>(props);
        
        // Kafka Consumer subscribes list of topics here.
        consumer.subscribe(Arrays.asList(topicName));
        
        // Print the topic name
        System.out.println("Subscribed to topic " + topicName);
        
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(100);
            for (ConsumerRecord<String, String> record : records) {
                String processedTweet = encodeValue(record.value());
                
                HttpClient client = HttpClient.newHttpClient();
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(sentimentAnalysisUrl + "/analyze-sentiment?tweet=" + processedTweet))
                        .build();
    
                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

                // Print the offset,key and value for the consumer records.
                System.out.printf("Tweet = %s | Sentiment = %s | Partition = %s\n", 
                                record.value(), response.body().toString(), record.partition());

                Thread.sleep(2000);
            }
        }
    }
}
