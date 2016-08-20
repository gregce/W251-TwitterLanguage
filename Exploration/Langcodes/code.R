# CLEAR WORKSPACE
rm(list=ls())

# LOAD LIBRARIES
library(dplyr)
library(tidytext)
library(ggplot2)
library(lubridate)
library(cowplot)
library(plotly)
library(stringr)
library(scales)

setwd("~/MIDS/DATASCI_W251/build_tweet_viz")

# Create a routine to programmatically read all data into memory
# 
# files <- list.files()
# pattern <- "(.psv)"
# #files we care about
# files <- files[grepl(pattern, files)]
# 
# tweets <- read.csv("tweets1.psv", sep = "|", skip = 3, stringsAsFactors = FALSE, strip.white = TRUE)
# names(tweets) <- c("id","timestamp","user","text","language","followers_count","friends_count","time_zone","entities","source_file")
# 
# # Modify Source Data
# tweets <- tweets %>%
#   ## filter data that gets read in incorrectly
#   mutate(incorrect = ifelse(grepl(".bz2", source_file),0,1)
#          , decoded_text = iconv(text, "latin1", "ASCII", "byte")) %>%
#   filter(incorrect==0)
# 
# for (file in files[2:(length(files))]){
#   print(paste("beginning to read in", file))
#   
#   tweets_tmp <- read.csv(file, sep = "|", skip = 3, stringsAsFactors = FALSE, strip.white = TRUE)
#   names(tweets_tmp) <- c("id","timestamp","user","text","language","followers_count","friends_count","time_zone","entities","source_file")
#   
#   if (nchar(row.names(tweets_tmp)[1])==1) {
#     tweets_tmp <- tweets_tmp %>%
#       ## filter data that gets read in incorrectly
#       mutate( incorrect = ifelse(grepl(".bz2", source_file),0,1)
#              , incorrect = ifelse(is.integer(followers_count), 0, incorrect)
#              , decoded_text = iconv(text, "latin1", "ASCII", "byte")
#              , followers_count = as.character(followers_count)
#              , friends_count = as.character(friends_count)
#              , id = as.character(id)) %>%
#       filter(incorrect==0) 
#     
#     print("starting to bind!")
#     tweets <- bind_rows(tweets, tweets_tmp)
#     print(paste0("total dataset size in memory: ", pryr::object_size(tweets)))
#     
#   } else {
#     print(paste("read in validation failed for ", file," moving to next file"))
#     }
# }
# 
# #save(tweets, file = "raw_tweets.rda")
# 
# tweets <- tweets %>%
# select(id, timestamp, user, text, language, followers_count
#        ,friends_count, time_zone, source_file, decoded_text) %>%
# filter(nchar(timestamp)<50) %>%
# mutate( isDate = ifelse(is.Date(as.Date(timestamp)),1,0)
#       , followers_count = as.integer(followers_count)
#       , friends_count = as.integer(friends_count)) %>%
# filter(isDate==1) %>%
# mutate(timestamp2 = ymd_hms(timestamp)) %>%
# na.omit()
# 
# tweets$timeonly <- as.numeric(tweets$timestamp2 - trunc(tweets$timestamp2, "days"))

## What we're trying to figure out and visualize

# Different parts of the United States / World communicate differently (in tweets on twitter)
# Different languages may tend to use more emojis
# Derive a proportionate measure comparing the length of text to the count of emojis by language / timezone

#save(tweets2, file = "tweets.rda")

# Read in emoticons for decoding purposes

load(file = "raw_tweets.rda")
# File 1
decode1 <- read.csv("Emoticons/emoticonsList.txt",  sep = " ", stringsAsFactors = FALSE)

decode1 <- decode1 %>%
  mutate(decoded_character = iconv(Native, "latin1", "ASCII", "byte")) %>%
  select(Description,  Native, Bytes, decoded_character)

names(decode1) <- c("description", "native", "bytes", "decoded_character")

#write.csv(decode, "/Users/gregce/cxda/emoticonDictionary.csv")

# File 2
decode2 <- read.csv("Emoticons/emDict.csv", sep = ";" , stringsAsFactors = FALSE)
names(decode2) <- c("description", "native", "bytes", "decoded_character")

decode <- dplyr::bind_rows(decode1, decode2)

# langcode
languages <- read.csv("Langcodes/lang.csv",  sep = ",", stringsAsFactors = FALSE, strip.white = TRUE )
names(languages) <- c("language","longlanguage")


# get emoticons translated for joining 
raw.tweets_emoticons <- tweets %>% 
  #dplyr::slice(1:50000) %>%
  select(id, text, decoded_text) %>%
  tidytext::unnest_tokens(character, text, token="characters") %>%
  mutate(decoded_character = iconv(character, "latin1", "ASCII", "byte")) %>%
  filter(character != decoded_character) %>%
  inner_join(decode) %>%
  select(id, native, description) %>%
  group_by(id, native, description) %>%
  summarise(emoticon_count = n())

save(raw.tweets_emoticons, file = "tweet_emoticons.Rda")

summary_agg.tweets_emoticons <- raw.tweets_emoticons %>%
  group_by(id) %>%
summarise(emoticon_count = n())

tweets_emoticons <- tweets %>%
  left_join(summary_agg.tweets_emoticons) %>%
  mutate(emoticon_count = ifelse(is.na(emoticon_count), 0, emoticon_count))

rm(tweets)

#View(tweets_emoticons[tweets_emoticons$id=="605271676184457216",])

# Get NRC sentiment for the tidytext package
bing <- sentiments %>%
  filter(lexicon == "bing") %>%
  dplyr::select(word, sentiment)

# Get just the words from our tweets
reg <- "([^A-Za-z\\d#@']|'(?![A-Za-z\\d#@]))"

tweet_words <- tweets_emoticons %>%
  #slice(1:50000) %>%
  select(id, text) %>%
  filter(!str_detect(text, '^"')) %>%
  mutate(text = str_replace_all(text, "https://t.co/[A-Za-z\\d]+|&amp;", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]")) %>%
  ## don't stop there, join on sentiment!
  left_join(bing, by = "word") %>%
  group_by(id, sentiment) %>%
  mutate(count = n()) %>%
  ungroup() %>%
  distinct(id, sentiment, count) 

words_by_id <- tweet_words %>%
  group_by(id) %>%
  mutate(total_words = n()) %>%
  ungroup() %>%
  distinct(id, total_words)

sentiment_by_id_quant <- tweet_words %>%
  mutate(sent_rating = ifelse(sentiment == 'positive', 1, -1)
         ,sent_rating = ifelse(is.na(sentiment), 0, sent_rating)) %>%
  group_by(id) %>%
  summarise(avg_sentiment = mean(sent_rating)
            , total_sentiment = sum(sent_rating)) 
  
  tweets_emoticons_sentiment <- tweets_emoticons %>%
  left_join(sentiment_by_id_quant) %>%
  mutate(avg_sentiment = ifelse(is.na(avg_sentiment), 0, avg_sentiment)
         ,total_sentiment = ifelse(is.na(total_sentiment), 0, total_sentiment)) %>%
  left_join(words_by_id) %>%
  mutate(total_words = ifelse(is.na(total_words), 0, total_words)) %>%
  left_join(languages) %>%
  mutate( longlanguage = ifelse(is.na(longlanguage), "English", longlanguage)
          , has_hashtag = ifelse(grepl("#", text), 1, 0)
          , is_retweet = ifelse(substring(text,1,2) == "RT", 1, 0)
          , is_response = ifelse(grepl("@", text), 1, 0))

rm(tweets_emoticons)

save(tweets_emoticons_sentiment, file ="tweet_emoticon_sentiment.Rda")

load("tweet_emoticon_sentiment.Rda")

optimized_for_viz <- tweets_emoticons_sentiment %>%
  select(id, user
         , followers_count, friends_count, time_zone
         , timestamp2, timeonly, month, wday, emoticon_count
         , avg_sentiment, total_sentiment, total_words, longlanguage
         , has_hashtag, is_retweet, is_response)

save(optimized_for_viz, file ="optimized_for_viz.Rda")

load("optimized_for_viz.Rda")


#http://juliasilge.com/blog/Joy-to-the-World/

fancy_scientific <- function(l) {
  # turn in to character string in scientific notation
  l <- format(l, scientific = TRUE)
  # quote the part before the exponent to keep all the digits
  l <- gsub("^(.*)e", "'\\1'e", l)
  # turn the 'e+' into plotmath format
  l <- gsub("e", "%*%10^", l)
  # return this as an expression
  parse(text=l)
}

## plots
p <- ggplot(data = tweets, aes(x = timeonly)) +
  geom_histogram(aes(fill = ..count..)) +
  #cowplot::theme_cowplot() +
  theme(legend.position = "none") +
  xlab("Time") + ylab("Number of tweets") + 
  scale_x_datetime(breaks = date_breaks("3 hours"), 
                   labels = date_format("%H:00")) +
  scale_fill_gradient(low = "midnightblue", high = "aquamarine4")

ggplotly(p)

p2 <- ggplot(data = tweets, aes(x = wday)) +
  geom_bar(aes(fill = ..count..)) +
  #cowplot::theme_cowplot() +
  theme(legend.position = "none") +
  xlab("Day or Week") + ylab("Number of tweets") + 
  scale_fill_gradient(low = "midnightblue", high = "aquamarine4")

ggplotly(p2)


p3 <- ggplot(data = tweets_emoticons_sentiment, aes(x = emoticon_count)) +
  geom_bar(aes(fill = ..count..)) +
  facet_grid(total_sentiment ~ wday) +
  cowplot::theme_cowplot() +
  theme(legend.position = "none") +
  xlab("Average Sentiment") + ylab("Number of tweets (Log)") + 
  scale_y_log10() +
  scale_fill_gradient(low = "midnightblue", high = "aquamarine4") 

ggplotly(p3)

p4 <- ggplot(data = optimized_for_viz, aes(x = emoticon_count, y = avg_sentiment)) +
  geom_point(aes(text = paste("Total Words:", total_words)), size = 4) +
  geom_smooth(aes(colour = wday, fill = wday)) + facet_wrap(~ wday)

p <- ggplot(optimized_for_viz, aes(x = emoticon_count, y = avg_sentiment)) +
  geom_point(alpha = 0.3)

ggplot(optimized_for_viz, aes(x = emoticon_count, y = avg_sentiment)) + 
  stat_binhex()


ggplotly(p4)
