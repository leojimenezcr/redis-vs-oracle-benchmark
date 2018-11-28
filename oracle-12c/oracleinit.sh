#!/bin/bash

docker-compose up -d
sleep 10

docker-compose exec oracle-12c sh -c 'echo "DROP TABLE ontime;" | sqlplus -s system/oracle'

docker-compose exec oracle-12c sh -c 'echo "CREATE TABLE ontime(id NUMBER, Year  INTEGER, Month  INTEGER, DayofMonth  INTEGER, DayofWeek  INTEGER, DepTime  INTEGER, CRSDepTime  INTEGER, ArrTime  INTEGER, CRSArrTime  INTEGER, UniqueCarrier  VARCHAR(5), FlightNum  INTEGER, TailNum  VARCHAR(8), ActualElapsedTime  INTEGER, CRSElapsedTime INTEGER, AirTime  INTEGER, ArrDelay  INTEGER, DepDelay  INTEGER, Origin  VARCHAR(3), Dest  VARCHAR(3), Distance  INTEGER, TaxiIn  INTEGER, TaxiOut  INTEGER, Cancelled  INTEGER);" | sqlplus -s system/oracle'

docker-compose down
