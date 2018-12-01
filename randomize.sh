#!/bin/bash

# Descarga todos los archivos
  # Descomprime
  # Filtra solo lineas que inician con numero
  # Sustituye basura por ceros
  # Ordena aleatoriamente
  # Escribe el archivo para pruebas
wget http://stat-computing.org/dataexpo/2009/{1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008}.csv.bz2 -O - \
  | bzip2 -dc \
  | grep -e ^[0-9].* \
  | sed 's/NA/0/g' | sed 's/,,/,0,/g' \
  | sort --random-sort > testrecords.csv
