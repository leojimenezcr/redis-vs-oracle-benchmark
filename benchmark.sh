#!/bin/bash

## Requeriments
# Ready to use dockers
# Prerandomized data file

## SETUP ##
#DATASIZELIST=(1000)
DATASIZELIST=(1000 5000 10000 50000 100000 500000 1000000)
TESTREPETITIONS=10

SOURCEFILE=$(pwd)/testrecords.csv
LOGFILE=$(pwd)/benchmark.log
ERRLOGFILE=$(pwd)/benchmark-errors.log
CSVFILE=$(pwd)/resultados/$(date +%Y%m%d-%H%M)-benchmark.csv

ORACLEPATH=$(pwd)/oracle-12c
REDISPATH=$(pwd)/redis

RANDOMLINE=0


## FUNCTIONS ##
function take_start_time() {
  #echo "Taking time for $DATASIZE records." >> $LOGFILE
  
  TIME=$(date +%s%N)
}

function take_end_time() {  
  TIME=$(( $(date +%s%N) - $TIME ))
  
  echo "  Enlapse time: $TIME nanoseconds." >> $LOGFILE
  echo "  Enlapse time (human readable): \
$(( $TIME / 3600000000000 )) hours, \
$(( ($TIME % 3600000000000) / 60000000000 )) minutes, \
$(( ($TIME % 60000000000) / 1000000000 )) seconds, \
$(( ($TIME % 1000000000) / 1000000 )) milliseconds, \
$(( ($TIME % 1000000) / 1000 )) microseconds and \
$(( ($TIME % 1000) % 1000 )) nanoseconds" >> $LOGFILE
  echo "$DATASIZE,$TIME" >> $CSVFILE
}

# Oracle functions
function oracle_start() {
  echo -n "Starting Oracle docker" >> $LOGFILE
  cd $ORACLEPATH
  docker-compose up -d 2>&1 > /dev/null

  while ! docker-compose logs | grep -q "Database ready"
  do
    sleep 1
    echo -n "." >> $LOGFILE
  done
  
  echo " OK" >> $LOGFILE
}

function oracle_insert_script_generation(){
  echo -n "Generating insert script... " >> $LOGFILE
  tail --lines=+$RANDOMLINE $SOURCEFILE | head -n $DATASIZE | awk -F',' '{ print "INSERT INTO ontime VALUES(\x27" $1$2$3$4$5 "\x27, \x27" $1 "\x27, \x27" $2 "\x27, \x27" $3 "\x27, \x27" $4 "\x27, \x27" $5 "\x27, \x27" $6 "\x27, \x27" $7 "\x27, \x27" $8 "\x27, \x27" $9 "\x27, \x27" $10 "\x27, \x27" $11 "\x27, \x27" $12 "\x27, \x27" $13 "\x27, \x27" $14 "\x27, \x27" $15 "\x27, \x27" $16 "\x27, \x27" $17 "\x27, \x27" $18 "\x27, \x27" $19 "\x27, \x27" $20 "\x27, \x27" $21 "\x27, \x27" $22 "\x27);" }' > $ORACLEPATH/oracle-data/testscript.sql
  echo "OK" >> $LOGFILE
}

function oracle_insert(){
  echo -n "Inserting records... " >> $LOGFILE
  echo -n "oracle,insert," >> $CSVFILE
  docker-compose exec oracle-12c sh -c 'echo @/u01/app/oracle/testscript.sql | sqlplus -s system/oracle' 2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function oracle_insert_validate() {
  echo -n "Inserted $(docker-compose exec oracle-12c sh -c 'echo "SELECT COUNT(ID) FROM ontime;" | sqlplus -s system/oracle' | tr -dc '[:digit:]') records" >> $LOGFILE
  if [ $(docker-compose exec oracle-12c sh -c 'echo "SELECT COUNT(ID) FROM ontime;" | sqlplus -s system/oracle' | tr -dc '[:digit:]') -lt $(( $DATASIZE/100*85 )) ]
  then
    echo " ERROR!" >> $LOGFILE
    echo "" >> $LOGFILE
    echo "Error inserting records" >> $ERRLOGFILE
    exit 1
  fi
  
  echo " ACCEPTED" >> $LOGFILE
}

function oracle_sort() {
  echo -n "Sorting records... " >> $LOGFILE  
  echo -n "oracle,sort," >> $CSVFILE
  docker-compose exec oracle-12c sh -c 'echo "SELECT id FROM ontime ORDER BY id;" | sqlplus -s system/oracle' 2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function oracle_clear(){
  echo -n "Cleaning docker... " >> $LOGFILE
  echo -n "oracle,clear," >> $CSVFILE
  docker-compose exec oracle-12c sh -c 'echo "DELETE FROM ontime;" | sqlplus -s system/oracle' 2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function oracle_stop() {
  echo -n "Stoping docker..." >> $LOGFILE
  docker-compose down 2>&1 > /dev/null
  sleep 10
  cd ..
  echo "OK" >> $LOGFILE
}

# Redis functions
function redis_start() {
  echo -n "Starting Redis docker" >> $LOGFILE
  cd $REDISPATH
  docker-compose up -d 2>&1 > /dev/null

  while ! docker-compose logs | grep -q "Ready to accept connections"
  do
    sleep 1
    echo -n "." >> $LOGFILE
  done
  
  echo " OK" >> $LOGFILE
}

function redis_insert_script_generation(){
  echo -n "Generating insert script... " >> $LOGFILE
  tail --lines=+$RANDOMLINE $SOURCEFILE | head -n $DATASIZE | awk -F',' '{ print "HSET \x27" $1$2$3$4$5 "\x27 Year \x27" $1 "\x27 Month \x27" $2 "\x27 DayofMonth \x27" $3 "\x27 DayofWeek \x27" $4 "\x27 DepTime \x27" $5 "\x27 CRSDepTime \x27" $6 "\x27 ArrTime \x27" $7 "\x27 CRSArrTime \x27" $8 "\x27 UniqueCarrier \x27" $9 "\x27 FlightNum \x27" $10 "\x27 TailNum \x27" $11 "\x27 ActualElapsedTime \x27" $12 "\x27 CRSElapsedTime \x27" $13 "\x27 AirTime \x27" $14 "\x27 ArrDelay \x27" $15 "\x27 DepDelay \x27" $16 "\x27 Origin \x27" $17 "\x27 Dest \x27" $18 "\x27 Distance \x27" $19 "\x27 TaxiIn \x27" $20 "\x27 TaxiOut \x27" $21 "\x27 Cancelled \x27" $22 "\x27 \\n \nLPUSH ontime \x27" $1$2$3$4$5 "\x27 \\n"}' > $REDISPATH/redis-data/testscript.txt
  echo "OK" >> $LOGFILE
}

function redis_insert() {
  echo -n "Inserting records... " >> $LOGFILE
  echo -n "redis,insert," >> $CSVFILE
  docker-compose exec redis sh -c 'echo $(cat testscript.txt) | redis-cli -c' 2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function redis_insert_validate() {
  echo -n "Inserted $(docker-compose exec redis redis-cli DBSIZE | tr -dc '[:digit:]') records" >> $LOGFILE
  if [ $(docker-compose exec redis redis-cli DBSIZE | tr -dc '[:digit:]') -lt $(( $DATASIZE/100*85 )) ]
  then
    echo " ERROR!" >> $LOGFILE
    echo "" >> $LOGFILE
    echo "Error inserting records" >> $ERRLOGFILE
    exit 1
  fi
  
  echo " ACCEPTED" >> $LOGFILE
}

function redis_sort() {
  echo -n "Sorting records... " >> $LOGFILE
  echo -n "redis,sort," >> $CSVFILE
  docker-compose exec redis redis-cli SORT ontime 2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function redis_clear(){
  echo -n "Cleaning docker... " >> $LOGFILE
  echo -n "redis,clear," >> $CSVFILE
  docker-compose exec redis redis-cli FLUSHDB  2>&1 > /dev/null
  echo "OK" >> $LOGFILE
}

function redis_stop() {
  echo -n "Stoping docker... " >> $LOGFILE
  docker-compose down 2>&1 > /dev/null
  sleep 10
  cd ..
  echo "OK" >> $LOGFILE
}

## TEST ##
echo "Logging file: $LOGFILE"
echo "Engine,Action,Data size,Time (ns)" > $CSVFILE
echo "Results: $CSVFILE"

for DATASIZE in ${DATASIZELIST[@]}
do
  for (( TESTITERACTION=1; TESTITERACTION<=$TESTREPETITIONS; TESTITERACTION++ ))
  do
    echo "Starting test $TESTITERACTION of $TESTREPETITIONS with $DATASIZE records." >> $LOGFILE
    # Random number from 1 to (Source file number of lines - Test data size + 1)
    RANDOMLINE=$( shuf -n1 -i1-$(( $(wc -l < $SOURCEFILE) - $DATASIZE + 1 )) )

    # Oracle test
    oracle_start
    oracle_insert_script_generation
    
    take_start_time
      oracle_insert
    take_end_time
    
    oracle_insert_validate
    
    take_start_time
      oracle_sort
    take_end_time
    
    take_start_time
    oracle_clear
    take_end_time
    
    oracle_stop

    # Redis test
    redis_start
    redis_insert_script_generation
    
    take_start_time
      redis_insert
    take_end_time
    
    redis_insert_validate

    take_start_time
      redis_sort
    take_end_time

    take_start_time
      redis_clear
    take_end_time

    redis_stop
    
    echo "Finished test $TESTITERACTION of $TESTREPETITIONS for $DATASIZE records." >> $LOGFILE
    echo "" >> $LOGFILE
  done #test repetitions
done #data size list

echo "Finished all tests." >> $LOGFILE
echo "" >> $LOGFILE
exit 0

