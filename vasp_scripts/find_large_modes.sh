#!/bin/bash

# find_large_modes.sh v1.0 12/14/2014 Jeff Doak jeff.w.doak@gmail.com 

# Awk script to search a DMsymm- (GoBaby-) formatted disp.dat file to find 
# the atoms of a phonon mode which have large displacements for a polarization.

# The first command-line argument is the index of the mode to analyze.
# The second argument is the tolerance (in A) for deciding if an atom's motion
# is significant.



mode=$1
tol=$2
file=$3

if [ $file == "disp.dat" ]
then
  awk ' \
  BEGIN{ \
  i = 1; \
  } \
  NF != 0 { \
    j = 1; \
    while(NF > 0){ \
      if(i == mode){ \
        disp=sqrt($1^2+$2^2+$3^2); \
        if(disp > tol){ \
          print j,disp,$1,$2,$3; \
        } \
      } \
      getline; \
      j++; \
    } \
    i++; \
  } \
  ' mode=$mode tol=$tol < $file
#elif [ $file == "phonons.out" ]
#then
else
  awk ' \
  BEGIN{ \
    getline; \
    natoms = $1; \
    nkpts = $2; \
    getline; \
    j = 0; \
    while(j < 3*natoms){ \
      getline; \
      j += NF; \
    } \
    i = 1; \
  } \
  NF != 0 { \
    while(NF > 0){ \
      if(i == mode){ \
        disp=sqrt($2^2+$3^2+$4^2); \
        if(disp > tol){ \
          print $1,disp,$2,$3,$4; \
        } \
      } \
      getline; \
    } \
    i++; \
  } \
  ' mode=$mode tol=$tol < $file
fi

