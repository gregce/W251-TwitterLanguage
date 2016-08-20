#!/bin/bash

timezones=( "'Eastern Time (US & Canada)'" "'Pacific Time (US & Canada)'" "'Central Time (US & Canada)'" "'Asia/Shanghai'" "'Asia/Kolkata'" "'America/Sao_Paulo'" "'Europe/Paris'" )
times=( "'2015-06-01 00:00:00+0000'" "'2015-09-01 00:00:00+0000'" "'2016-02-01 00:00:00+0000'" )

COUNTER=0
for j in "${times[@]}"
do
for i in "${timezones[@]}"
do
        let COUNTER=COUNTER+1
	tmp1='cqlsh --request-timeout 3600 192.155.215.6 -e "select id, timestamp, user, text, lang, followers_count, friends_count, time_zone, entities, file  from twitter_final.tweets where time_zone = '$i
	tmp2=$tmp1' and timestamp > '$j
	tmp3=$tmp2' limit 50000" > /data/tweets'$COUNTER
	tmp4=$tmp3'.psv '

        echo "Extracting Data for "$i" at time greater than "$j" into file tweets"$COUNTER".psv"
	#eval $tmp4

done
done
