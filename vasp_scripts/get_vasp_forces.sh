#!/bin/bash

#number of lines to get forces for, i.e. number of atoms in calc.
n=54
#print the lines containing forces:
lines=`awk '{i=0}/TOTAL-FORCE/{getline; while(i<n) {getline; print $4,$5,$6; i++} i=0}' n=$n < OUTCAR`
echo $lines

#output='results'
#echo "encut kppra force_x force_y force_z" > $output
#for dir in *
#do
#  if [ -d $dir ]
#  then
#    encut=`sed -n "s/^ *ENCUT *= *\([0-9][0-9]*\).*/\1/p" < $dir/vasp.in`
#    kppra=`sed -n "s/^ *KPPRA *= *\([0-9][0-9]*\).*/\1/p" < $dir/vasp.in`
#    forces=`awk '{i=0}/TOTAL-FORCE/{getline; while(i<n) {getline; print $4,$5,$6; i++} i=0}' n=$n < $dir/OUTCAR`
#    echo "$encut $kppra $forces" >> $output
#  fi
#done
