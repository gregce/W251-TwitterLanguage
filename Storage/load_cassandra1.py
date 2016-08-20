import bz2
import json
from cassandra.cluster import Cluster
import os
from time import gmtime, strftime, time
import sys

def get_directories(path):
    l = []
    for root, directories, filenames in os.walk(path):
        for directory in directories:
            l.append(os.path.join(root, directory))
    return(l)

def loop_through_data(path):
    l = []
    for root, directories, filenames in os.walk(path):
        for directory in directories:
            os.path.join(root, directory) 
        for filename in filenames: 
             l.append(os.path.join(root, filename))
    return(l)

#loop de-loop!
#create a cassandra cluster
cluster = Cluster(['192.155.215.14'])
session = cluster.connect('twitter_final')

l = get_directories("/data/2016/02")[0:29]
l.sort()

for idx, day in enumerate(l[0:9]):

    #get a list of files for the current day in the loop
    day_l = loop_through_data(day)

    status = 50000
    read_tweets = 0
    written_tweets = 0

    start = time()

    log = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    print "------------------------------------------------------------------"
    print "%s: Began to processes data for day %s" % (log, day)
    print "------------------------------------------------------------------"

    for index, item in enumerate(day_l):

        bz_file = bz2.BZ2File(item)
        line_list = bz_file.readlines()
    
        #for each json in the list, attempt to insert it
        for i in range(0,len(line_list)):
            
            read_tweets += 1
            try:
                tweet_id = json.loads(line_list[i])['id']
                timestamp = json.loads(line_list[i])['timestamp_ms']
                screen_name = json.loads(line_list[i])['user']['screen_name'].encode("utf-8")
                text = json.loads(line_list[i])['text'].encode('utf-8')
                lang = str(json.loads(line_list[i])['lang'])
                followers_count = json.loads(line_list[i])['user']['followers_count']
                friends_count = json.loads(line_list[i])['user']['friends_count']
                time_zone = str(json.loads(line_list[i])['user']['time_zone'])
                entities = str(json.loads(line_list[i])['entities'])

                session.execute(
                    """
                    INSERT INTO tweets (id, timestamp, user, text, lang
                                          , followers_count, friends_count, time_zone
                                          , entities, file)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (tweet_id, timestamp, screen_name, text, lang
                   , followers_count, friends_count, time_zone, entities, item)
                )

                written_tweets +=1 

                if written_tweets % status == 0:
                    log = strftime("%Y-%m-%d %H:%M:%S", gmtime())
                    print "%s: Inserted %s tweets into cassandra" % (log, written_tweets)

            except KeyError:
                pass

    end = time()
    
    time_elapsed = end - start

    log_time = strftime("%Y-%m-%d %H:%M:%S", gmtime())

    session.execute("""
                    INSERT INTO tweets_etl (log_time, file, time_elapsed, read_tweets, written_tweets)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (log_time, day, time_elapsed, read_tweets, written_tweets))
