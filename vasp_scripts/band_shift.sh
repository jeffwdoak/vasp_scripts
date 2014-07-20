#!/bin/bash

# band_shift.sh v1.1 8-14-2013 Jeff Doak jeff.w.doak@gmail.com
# script to grab valence and conduction band values from OUTCAR and
# plot them as a function of the k-point magnitude. Also grabs the
# vb and cb values at the L and Sigma points in the rocksalt structure
# (lots of assumptions made here about the calculation that was performed!).

awk ' \
BEGIN{ \
  i = 0; \
  vbmmax = -100; \
  cbmmin = 100; \
  kpt0 = 0.0; \
  kptold = 0.0; \
  print "kpt_#","d_|kpt|","vb_(eV)","cb_(eV)"; \
} \
/ *k-point *[0-9]* \: *[0-9][.][0-9]* +[0-9][.][0-9]* +[0-9][.][0-9]*$/{ \
  i += 1; \
  kpt1 = sqrt($4^2+$5^2+$6^2); \
  dkpt = ( kpt1-kpt0 >=0 ? kpt1-kpt0 : kpt0-kpt1 ); \
  kptnew = ( i == 1 ? kptold : kptold + dkpt ); \
  kpt0 = kpt1; \
  kptold = kptnew; \
  getline; \
  getline; \
  oldline = $0; \
  newline = $0; \
  vbm = $2; \
  cbm = $2; \
  while ($3 >= 1.0){ \
    getline; \
    oldline = newline; \
    newline = $0; \
    vbm = cbm; \
    cbm = $2; \
  } \
  if (i == 1){ \
    cb2L = cbm; \
    while (cb2L == cbm){ \
      getline; \
      cb2L = $2; \
    } \
  } \
  if (i == 1){ \
    vbL = vbm; \
    cbL = cbm; \
  } \
  if (i > 20 && vbm >= vbmmax){ \
    vbmmax = vbm; \
  } \
  if(i > 20 && cbm <= cbmmin){  \
    cbmmin = cbm; \
  } \
  print i,kptnew,vbm,cbm; \
} \
END{ \
  print ""; \
  print "VB_L","VB_Sigma","CB_L","CB_Sigma","CB_2L"; \
  print vbL,vbmmax,cbL,cbmmin,cb2L; \
  print "D_VB_L-Sig","D_CB_Sig-L","D_CB_2L-L","E_G"; \
  print vbL-vbmmax,cbmmin-cbL,cb2L-cbL,cbL-vbL; \
} \
' < OUTCAR

