#!/bin/bash

# procar_awk.sh Jeff Doak jeff.w.doak@gmail.com

# Awk script to extract the electron eigenvalues at each k-point of a VASP
# calculation which have a specific projection weight onto an atomic oribtal.

# The first commandline argument is the PROCAR file to analyze.
# The second argument is the number of the ion in the POSCAR to look for 
# projection onto.
# The third and fourth arguments are the lower and upper bounds on the
# projection weight, respectively.
#
# At each k-point, the bands which have a projection onto the atomic orbital of
# the ion $ion with weight in between the lower and upper bounds will be
# printed to standard out. This is useful for parsing the PROCAR file for bands
# which project onto, say, an impurity atom, without also getting numerical
# noise associated with the projection scheme.
#
# Example usage: procar_awk.sh PROCAR 1 0.01 0.3

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
