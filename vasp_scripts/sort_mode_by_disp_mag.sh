#!/bin/bash

# sort_mode_by_disp_mag.sh v1.0 12/14/2014 Jeff Doak jeff.w.doak@gmail.com 

# Awk script to sort the atomic displacements of a chosen mode by the magnitude
# of atomic displacments or polarization vector. Either disp.dat or phonons.out
# file formats can be used.

# The first command-line argument is the index of the mode to analyze.
# The second argument is the name of the file to sort



mode=$1
file=$2

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
        print j,disp,$1,$2,$3; \
      } \
      getline; \
      j++; \
    } \
    i++; \
  } \
  ' mode=$mode < $file | sort -n -r -k 2
elif [ $file == "phonons.out" ]
then
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
        print $1,disp,$2,$3,$4; \
      } \
      getline; \
    } \
    i++; \
  } \
  ' mode=$mode < $file | sort -n -r -k 2
fi

