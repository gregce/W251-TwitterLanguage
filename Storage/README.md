# Storing Twitter Data in our 9 node cluster
### Step 1: Source and extract the Data
Data was downloaded simultaneously from the Twitter Spritzer Archive Team site which contains a 1% sample of all captured Tweets. We ultimately leveraged the following tar archives:
- [twitter-stream-2015-06](https://archive.org/details/archiveteam-twitter-stream-2015-06): 43.2gb compressed, 345 gb uncompressed
- [twitter-stream-2015-09](https://archive.org/download/archiveteam-twitter-stream-2015-09/archiveteam-twitter-stream-2015-09.tar):  30 gb compressed, 240 gb uncompressed
- [twitter-stream-2016-02](https://archive.org/details/archiveteam-twitter-stream-2015-06):  33.8gb compressed, 270 gb uncompressed

A sample to download and extract the data that was executed via a cssxh under a tmux session would be similar to: `wget https://archive.org/download/archiveteam-twitter-stream-2015-09/archiveteam-twitter-stream-2015-09.tar && tar xvzf archiveteam-twitter-stream-2015-09.tar`

Due to the size of these files, and the relatively poor network connection observed from the nodes, each download and untar operation could take quite a while (> 5 hours in our experience). We carefully ran each process in a tmux session to ensure that any SSH connection failure would not impedede progress

### Step 2: Configure Cassandra Keyspace
After we sourced each of the archvies, it was necessary to create a keyspace across our 9 nodes and to create the requisite column families necessary to store the data. 

With regards to the keyspace, we probably under replicated the data but were a bit constrained on disk space and so chose a NetworkTopologyStrategy of 2 (meaning each record would be duplicated across 2 machines). In retropsect, a NetworkTopologyStrategy of 3 would have probably been wise.

We took a relatively simple approach to schema creation and pre-emptively limited the tweets to only the releveant data that we assumed would be necessary for analysis. These columns included the following (types also listed):
 - id bigint
 - timestamp timestamp
 - user varchar
 - text varchar
 - lang varchar
 - followers_count bigint
 - friends_count bigint
 - time_zone varchar
 - entities varchar
 - file varchar
 
This reduced schema allowed us to load less actual data than the JSON payload actually contained and sped up the rest of the actual data load and following analysis. 

Additionally, due to the fact we read about how long trivial opeartions like `select count(*)` take when the cluster grows in size, we created another column family to capture ETL details, called `tweets_etl`. This, in additiion to onscreen logging, proved beneficial to track the status of the jobs as they were executing and to give us a sense of how much data we read vs. actually loaded. 

The schema for this column family was as follows:
- log_time varchar PRIMARY KEY
- file varchar
- time_elapsed float
- read_tweets bigint
- written_tweets bigint

### Step 3: Load the data in parallel across machines
A script, `load_cassandra1.py` was created and used for initial benchmarking of how long the load process would take. We determined that each machine was capable of loading (read, parse, write) ~50K tweets in ~3 minutes. We also determined that there was no discernible slowdown when these scripts were executed in parallel across multiple nodes (we used p2, p3 & p6 for this). The above script was copied and modifided across each node and executed in a separate tmux session to allow for long runtimes. Our ETL table shows that a directory walk for a single day in a single archive (each archive has as many directories as there are days in that month) took between 3 - 5 hours to load. 


