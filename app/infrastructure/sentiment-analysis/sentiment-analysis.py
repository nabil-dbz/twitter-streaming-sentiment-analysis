import json
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from textblob import TextBlob

def get_sentiment_vader(tweet):
    nltk.data.path.append('/tmp')
    nltk.download('vader_lexicon', download_dir='/tmp')
    sentiment_intensity_analyzer = SentimentIntensityAnalyzer()
    score = sentiment_intensity_analyzer.polarity_scores(tweet)
    return score.get('compound')

def get_sentiment_textblob(tweet):
    return TextBlob(tweet).sentiment.polarity

'''
from flair.models import TextClassifier
from flair.data import Sentence
def get_sentiment_flair(tweet):
    flair_sentiment = TextClassifier.load('en-sentiment')
    sentence = Sentence(tweet)
    flair_sentiment.predict(sentence)
    return sentence.labels[0].to_dict()['value'] == 'POSITIVE'
'''
    
def handler(event, context):
    tweet: str = event['queryStringParameters']['tweet']
    print('Received tweet is: ' + tweet)

    vader_sentiment     = get_sentiment_vader(tweet)
    textblob_sentiment  = get_sentiment_textblob(tweet)

    sentiment = 'POSITIVE' if (vader_sentiment + textblob_sentiment)/2 > 0 else 'NEGATIVE'
    
    analysis_response = { 
        'sentiment': sentiment 
    }

    response_object = {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
        },
        'body': json.dumps(analysis_response)
    }

    return response_object
