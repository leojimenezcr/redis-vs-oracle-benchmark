#!/bin/bash

## Requeriments
# Ready to use dockers
# Prerandomized data file

## SETUP ##
SOURCEFILE=$(pwd)/testrecords.csv
DATASIZELIST=(100)
#DATASIZELIST=(1000 10000 100000 1000000)
TESTREPETITIONS=1
LOGFILE=$(pwd)/benchmark.log
CSVFILE=$(pwd)/$(date +%Y%m%d-%H%M)-benchmark.csv

ORACLEHOST=""
ORACLEHOSTPORT=1521
ORACLEDB=""
ORACLEUSER=system
ORACLEPASS=oracle
ORACLEPATH=$(pwd)/oracle-12c

REDISPATH=$(pwd)/redis

RANDOMLINE=0


## FUNCTIONS ##
function take_start_time() {
  echo "Taking time for $DATASIZE records..." >> $LOGFILE
  
  TIME=$(date +%s%3N)
}

function take_end_time() {  
  TIME=$(( $(date +%s%3N) - $TIME ))
  
  echo "Processed $DATASIZE records in $TIME miliseconds." >> $LOGFILE
  echo "Human readable enlapse time: $(( $TIME / 3600000 )) hours, $(( ($TIME % 3600000) / 60000 )) minutes, $(( ($TIME % 60000) / 1000 )) seconds and $(( ($TIME % 1000) % 1000 )) miliseconds." >> $LOGFILE
  echo "$DATASIZE,$TIME" >> $CSVFILE
}

# Oracle functions
function oracle_start() {
  echo "Starting Oracle docker." >> $LOGFILE
  echo -n "oracle," >> $CSVFILE
  cd $ORACLEPATH
  docker-compose up -d
  sleep 10
}

function oracle_stop() {
  echo "Stoping Oracle docker." >> $LOGFILE
  docker-compose down
  sleep 10
  cd ..
}

function oracle_insert(){
  echo "Inserting records" >> $LOGFILE
  
  # SQL script generation
  tail --lines=+$RANDOMLINE $SOURCEFILE | head -n $DATASIZE | awk -F',' '{ print "INSERT INTO ontime VALUES(\x27" $1$2$3$4$5 "\x27, \x27" $1 "\x27, \x27" $2 "\x27, \x27" $3 "\x27, \x27" $4 "\x27, \x27" $5 "\x27, \x27" $6 "\x27, \x27" $7 "\x27, \x27" $8 "\x27, \x27" $9 "\x27, \x27" $10 "\x27, \x27" $11 "\x27, \x27" $12 "\x27, \x27" $13 "\x27, \x27" $14 "\x27, \x27" $15 "\x27, \x27" $16 "\x27, \x27" $17 "\x27, \x27" $18 "\x27, \x27" $19 "\x27, \x27" $20 "\x27, \x27" $21 "\x27, \x27" $22 "\x27);" }' > $ORACLEPATH/oracle-data/testscript.sql

  docker-compose exec oracle-12c sh -c 'echo @/u01/app/oracle/testscript.sql | sqlplus -s system/oracle' &> /dev/null
}

function oracle_clear(){
  echo "Cleaning oracle docker" >> $LOGFILE
  
  docker-compose exec oracle-12c sh -c 'echo "DELETE FROM ontime;" | sqlplus -s system/oracle' &> /dev/null
}


function oracle_sort() {
  echo "Sorting records" >> $LOGFILE
  
  docker-compose exec oracle-12c sh -c 'echo "SELECT id FROM ontime ORDER BY id;" | sqlplus -s system/oracle' &> /dev/null
}

# Redis functions
function redis_start() {
  echo "Starting Redis docker." >> $LOGFILE
  echo -n "redis," >> $CSVFILE
  cd $REDISPATH
  docker-compose up -d
  sleep 10
}

function redis_stop() {
  echo "Stoping Redis docker." >> $LOGFILE
  docker-compose exec redis redis-cli dbsize >> $LOGFILE
  docker-compose exec redis redis-cli llen ontime >> $LOGFILE
  docker-compose exec redis redis-cli FLUSHDB 
  docker-compose down
  sleep 10
  cd ..
}

function redis_insert() {
  echo "Inserting records" >> $LOGFILE

  # SQL script generation
  tail --lines=+$RANDOMLINE $SOURCEFILE | head -n $DATASIZE | awk -F',' '{ print "HSET " $1$2$3$4$5 " Year " $1 " Month " $2 " DayofMonth " $3 " DayofWeek " $4 " DepTime " $5 " CRSDepTime " $6 " ArrTime " $7 " CRSArrTime " $8 " UniqueCarrier " $9 " FlightNum " $10 " TailNum " $11 " ActualElapsedTime " $12 " CRSElapsedTime " $13 " AirTime " $14 " ArrDelay " $15 " DepDelay " $16 " Origin " $17 " Dest " $18 " Distance " $19 " TaxiIn " $20 " TaxiOut " $21 " Cancelled " $22 " \\n \nLPUSH ontime " $1$2$3$4$5 " \\n"}' > $REDISPATH/redis-data/testscript.txt
  ## hace falta añadir literalmente un \n al final del string y añadir el lpush 
  docker-compose exec redis sh -c 'echo $(cat testscript.txt) | redis-cli -c'
}

function redis_sort() {
  echo "Sorting records" >> $LOGFILE
}

## TEST ##
echo "Logging file: $LOGFILE"
echo "Engine,Data size,Time (ms)" > $CSVFILE
echo "Results: $CSVFILE"

for DATASIZE in ${DATASIZELIST[@]}
do
  #for (( TESTITERACTION=1; TESTITERACTION<=$TESTREPETITIONS; TESTITERACTION++ ))
  #do
    echo "Starting test $TESTITERACTION of $TESTREPETITIONS with $DATASIZE records." >> $LOGFILE
    # Random number from 1 to (Source file number of lines - Test data size + 1)
    RANDOMLINE=$( shuf -n1 -i1-$(( $(wc -l < $SOURCEFILE) - $DATASIZE + 1 )) )

    # Oracle test
    #oracle_start
    #oracle_insert
    #take_start_time
    #  oracle_sort
    #take_end_time
    #oracle_clear
    #oracle_stop

    # Redis test
    redis_start  
    redis_insert  
    take_start_time
      redis_sort
    take_end_time  
    redis_stop
    
    #echo "Finished test $TESTITERACTION of $TESTREPETITIONS for $DATASIZE records." >> $LOGFILE
    echo "" >> $LOGFILE
  #done #test repetitions
done #data size list

echo "Finished all tests." >> $LOGFILE
echo "" >> $LOGFILE
exit 0

