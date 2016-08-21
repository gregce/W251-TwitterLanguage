# Exploring the data loaded into Cassandra
### Step 1: Access the data
To write the data into cassandra, we relied heavily on the datastax `cassandra-driver`. Unfortunately, we ran into a significant issue when trying to use this same driver to read from our cluster. Essentially, the driver kept a persistent connection to the cluster, and when multiple sessions were created, failed to appropriately handle GC causing cluster instability and ultimately crashes. This issue is documented in some fashion on stack overflow [here](http://stackoverflow.com/questions/28262400/cassandra-python-driver-errormemory-leak-while-creating-sessions) although no great workaround is presented.

As an alternative, we developed  a bash script to extract a large bulk sample of data (which was not optimal, but ultimately necessary) using the script `iterativey_extract_data.sh`. This allowed us to all work on exactly the same data and ultimately is a representative sample of our total tweets. 

### Step 2: Explore the data in python
We took both a spark and non-spark based approach to accessing the data. Ultimately, the main analysis we conducted and relied on in python was non spark based, but we did experience a significant advantage in processing time when using our spark cluster. 

The main analysis,  `emoji_analysis.ipynb` does a number of things in an attempt to answer the following question:  "Does the usage of an emoticon in a tweet actually reflect the text based sentiment?"

- First there are functions implemented used to walk the directory structure where the data is loaded
- Next we get each tweet exported from specific files
- We then determine the language
- Once that is completed, we find emojis in the tweet based on whether they are positively or negatively encoded 
- We're able to then use a great sentiment analysis library, `vaderSentiment`, to get the sentiment of the actual text and compare it to the count of encoded emoticons identified in each tweet
- Final results related to whether the text sentiment matches the emoticon sentiment is summarized and printed to the console. 

### Step 3: Explore the data in R 
R was used in parallel to the python analysis to investigate more general characteristics of the language used in the tweets. We used R in the following way:
- A much larger representative sample of the data was read into R (~500K tweets across 30 extract files reprsenting a variety of time_zones and time periods - as defined by the 3 archive extract files we had loaded)
- We built a dictionary of all possible Emoticons, they description and value
- We also leveraged a language code library that we could use for decoding the language abbreviations in the tweet itself
- Extensive data cleaning was done on the text -- it was first converted to a consistent encoding scheme, each character was tokenized, and then we subsequently matched our emoticons by character
- Having done this, we were able to then tokenize by word, apply sentiment from Professor Bing's sentiment dictionary we leveraged, to determine the relative sentiment for each tweet
- Finally, we created a number of additional variables that would be useful for visualization -- for example, we determined the type of tweet each example was, we computer character length and removed outliers, etc.
- Graphs were produced interactively that exposed relationships and patterns in the data -- we ultimately leveraged these graphs in our final visualization and details about that process is explained in the Visualization folder of this repo.


