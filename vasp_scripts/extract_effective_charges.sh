#!/bin/bash

natoms=`head -7 CONTCAR  | tail -1 | awk '{for (i=1; i<=NF; i++) j+=$i; print j;}'`

awk ' \
/BORN EFFECTIVE CHARGES/{ \
  getline; \
  i=1; \
  while (i<=natoms){ \
    getline; \
    for (j=1; j<=3; j++){ \
      getline; \
      print $2,$3,$4; \
    } \
    i++; \
  } \
} \
' natoms=$natoms < OUTCAR


