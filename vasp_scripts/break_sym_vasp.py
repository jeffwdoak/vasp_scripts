#!/usr/bin/env python
from numpy import *
import sys,os,math,random

#cell_vec = 0.05/2.0
#cell_ang = 0.25/2.0
atom_pos = 0.01/2.0

iFile  = sys.stdin
#iFile  = "ideal.in"
#try: iFile = open(iFile, 'r')
#except: print "Problem opening ",iFile; sys.exit(1)

random.seed()

for i in range(7):
	line = iFile.readline()
	if not line: break
	print line,
#line = iFile.readline()
#if not line: print "No cell info!"; sys.exit(1)
#pair = line.split()
#print random.uniform( float(pair[0])-cell_vec,float(pair[0])+cell_vec ), \
#      random.uniform( float(pair[1])-cell_vec,float(pair[1])+cell_vec ), \
#      random.uniform( float(pair[2])-cell_vec,float(pair[2])+cell_vec ), \
#      random.uniform( float(pair[3])-cell_ang,float(pair[3])+cell_ang ), \
#      random.uniform( float(pair[4])-cell_ang,float(pair[4])+cell_ang ), \
#      random.uniform( float(pair[5])-cell_ang,float(pair[5])+cell_ang )

atomList = ["Pb","S","Te"]
while 1:
    line = iFile.readline()
    if not line: break
    pair = line.split()
    for i in range(3):
        pair[i] = random.uniform(float(pair[i])-atom_pos,float(pair[i])+atom_pos)
    line = ""
    for i in range(len(pair)):
        line = line+str(pair[i])+" "
    print line
iFile.close()
