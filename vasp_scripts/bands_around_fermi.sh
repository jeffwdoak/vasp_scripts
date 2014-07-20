#!/bin/bash

# bands_around_fermi.sh v1.1 10-10-2013 Jeff Doak jeff.w.doak@gmail.com
# script to grab valence and conduction band values from OUTCAR and
# plot them as a function of the k-point magnitude. Also grabs the
# vb and cb values at the L and Sigma points in the rocksalt structure
# (lots of assumptions made here about the calculation that was performed!).
efermi=`head -6 < DOSCAR | tail -1 | awk '{print $4}'`
awk ' \
BEGIN{ \
  i = 0; \
  kpt0 = 0.0; \
  kptold = 0.0; \
  vb1max = -100; \
  vb2max = -100; \
  cb1min = 100; \
  cb2min = 100; \
  print "kpt_#","d_|kpt|","vb1_(eV)","vb2_(eV)","cb1_(eV)","cb2_(eV)"; \
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
  vbm1 = $2; \
  vbm2 = $2; \
  cbm1 = $2; \
  cbm2 = $2; \
  vbn1 = $1; \
  vbn2 = $1; \
  cbn1 = $1; \
  cbn2 = $1; \
  while (cbm1 <= efermi){ \
    getline; \
    oldline = newline; \
    newline = $0; \
    vbm1 = vbm2; \
    vbm2 = cbm1; \
    cbm1 = cbm2; \
    cbm2 = $2; \
    vbn1 = vbn2; \
    vbn2 = cbn1; \
    cbn1 = cbn2; \
    cbn2 = $1; \
  } \
  if (i == 1){ \
    vb1L = vbm1; \
    vb2L = vbm2; \
    cb1L = cbm1; \
    cb2L = cbm2; \
  } \
  if (i > 20 && vbm1 >= vb1max){ \
    vb1max = vbm1; \
  } \
  if (i > 20 && vbm2 >= vb2max){ \
    vb2max = vbm2; \
  } \
  if (i >= 20 && cbm1 <= cb1min){ \
    cb1min = cbm1; \
  } \
  if (i >= 20 && cbm2 <= cb2min){ \
    cb2min = cbm2; \
  } \
  print i,kptnew,vbm1,vbm2,cbm1,cbm2; \
} \
END{ \
  print ""; \
  print "Fermi Energy"; \
  print efermi; \
  print "Band #s"; \
  print vbn1,vbn2,cbn1,cbn2; \
  print "VB1_L","VB1_Sigma","VB2_L","VB2_Sigma","CB1_L","CB1_Sigma","CB2_L","CB2_Sigma"; \
  print vb1L,vb1max,vb2L,vb2max,cb1L,cb1min,cb2L,cb2min; \
  print "D_VB1_L-Sig","D_VB2_L-Sig","D_CB1_L-Sig","D_CB2_L-Sig"; \
  print vb1L-vb1max,vb2L-vb2max,cb1L-cb1min,cb2L-cb2min; \
} \
' efermi=$efermi < OUTCAR
