#!/bin/bash

## Requeriments
# Ready to use dockers
# Prerandomized data file

## SETUP ##
SOURCEFILE=testrecords.csv
DATASIZELIST=(10)
#DATASIZE=(1000 10000 100000 1000000)
LOGFILE=$(pwd)/benchmark.log

ORACLEHOST=""
ORACLEHOSTPORT=1521
ORACLEDB=""
ORACLEUSER=system
ORACLEPASS=oracle
ORACLEPATH=oracle-12c

REDISPATH=redis


## FUNCTIONS ##
function randomize() {
  echo "randomize" >> $LOGFILE
  
  # ignore header
  #  randomize
  #  write first N lines
#  tail -n +2 $SOURCEFILE | \
#    sort --random-sort | \
#    head -n $DATASIZE > "${SOURCEFILE%.*}-$DATASIZE-records.csv"
}

function take_start_time() {
  echo "take_start_time" >> $LOGFILE
}

function take_end_time() {
  echo "take_end_time" >> $LOGFILE
}

# Oracle functions
function oracle_start() {
  echo "Starting Oracle docker" >> $LOGFILE
  cd $ORACLEPATH
  docker-compose up -d
  sleep 10
}

function oracle_stop() {
  echo "Stoping Oracle docker" >> $LOGFILE
  docker-compose down
  sleep 10
  cd ..
}

function oracle_insert(){
  echo "oracle_insert" >> $LOGFILE
}

# Redis functions
function redis_start() {
  echo "Starting Redis docker" >> $LOGFILE
  cd $REDISPATH
  docker-compose up -d
  sleep 10
}

function redis_stop() {
  echo "Stoping Redis docker" >> $LOGFILE
  docker-compose down
  sleep 10
  cd ..
}

function redis_insert() {
  echo "redis_insert" >> $LOGFILE
}


## TEST ##
for DATASIZE in ${DATASIZELIST[@]}
do  
  echo "Starting test with $DATASIZE records" >> $LOGFILE
  #randomize
  


  # Oracle test
  oracle_start
  
  take_start_time
  oracle_insert
  take_end_time
  
  oracle_stop

  # Redis test
  redis_start
  
  take_start_time
  redis_insert
  take_end_time
  
  redis_stop
  
  echo "Ending test for $DATASIZE records" >> $LOGFILE
  echo "" >> $LOGFILE
done

echo "Ending all tests" >> $LOGFILE
exit 0

