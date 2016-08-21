
## creating a keyspace 
 CREATE KEYSPACE twitter_final
  WITH REPLICATION = {'class' : 'NetworkTopologyStrategy', 'dc1' : 2};

## creating a table to hold all of our tweets
CREATE TABLE twitter_final.tweets (
    id bigint,
    timestamp timestamp,
    user varchar,
    text varchar,
    lang varchar,
    followers_count bigint,
    friends_count bigint,
    time_zone varchar,
    entities varchar,
    file varchar,
    PRIMARY KEY(time_zone, timestamp, user)
);

CREATE TABLE twitter_final.tweets_etl (
    log_time varchar PRIMARY KEY,
    file varchar,
    time_elapsed float,
    read_tweets bigint,
    written_tweets bigint
);

## check keyspaces

SELECT * FROM system.schema_keyspaces;


CREATE INDEX lang
   ON twitter_final.tweets (lang);

CREATE INDEX ON twitter_final.tweets (zip);


