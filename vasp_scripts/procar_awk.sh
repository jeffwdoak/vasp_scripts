#!/bin/bash
procar=$1
ion=$2
tol1=$3
tol2=$4

awk '\
  $1=="k-point"{ \
    print; \
    print "band energy occ. ion s py pz px dxy dyz dx2 dxz dx2 tot"; \
  }\
  $1=="ion"{ \
    print;
  }\
  $1=="band"{ \
    bandline=$0; \
    bandnum=$2; \
    bandeng=$5; \
    bandocc=$8; \
    getline; \
    getline; \
    while ($1!=ion){ \
      getline; \
    }\
    nonzero=0; \
    for(i=2; i<=NF; i++){ \
      if($i >= tol1 && $i <= tol2){ \
        nonzero=1 \
      }\
    }\
    if(nonzero!=0){ \
      $1=bandnum " " bandeng " " bandocc " " ion
      print;
    }\
  }\
' ion=$ion tol1=$tol1 tol2=$tol2 < $procar
