#!/bin/bash

## SETUP ##
SOURCEFILE=testrecords.csv
DATASIZELIST=(10)
#DATASIZE=(1000 10000 100000 1000000)
LOGFILE=benckmark.log

ORACLEHOST=""
ORACLEHOSTPORT=1521
ORACLEDB=""
ORACLEUSER=system
ORACLEPASS=oracle


## FUNCTIONS ##
function randomize(){
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
function oracle_start(){
}

function oracle_insert(){
  echo "oracle_insert" >> $LOGFILE
}

# Redis functions
function redis_insert() {
  echo "redis_insert" >> $LOGFILE
}


## TEST ##
for DATASIZE in ${DATASIZELIST[@]}
do  
  echo "Starting test with $DATASIZE records" >> $LOGFILE
  randomize

  # Oracle test
  take_start_time
  oracle_insert
  take_end_time

  # Redis test
  take_start_time
  redis_insert
  take_end_time
  
  echo "Ending test for $DATASIZE records" >> $LOGFILE
  echo "" >> $LOGFILE
done

echo "Ending all tests" >> $LOGFILE
exit 0

