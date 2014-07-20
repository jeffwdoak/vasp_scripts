awk ' \
BEGIN{ \
  i=0; \
  vbmmax=-1000; \
  cbmmin=1000; \
} \
/ *k-point *[0-9]* \: *[-]?[0-9][.][0-9]* +[-]?[0-9][.][0-9]* +[-]?[0-9][.][0-9]*$/{ \
  print; \
  i += 1; \
  getline; \
  getline; \
  oldline = $0; \
  newline = $0; \
  vbm = $2; cbm = $2; \
  while ($3 > 0.50000){ \
    getline; \
    oldline = newline; \
    newline = $0; \
    vbm = cbm; \
    cbm = $2; \
  } \
  if(vbm >= vbmmax){ \
    vbmmax = vbm; \
    kptVmax = i; \
    } \
  if(cbm <= cbmmin){ \
    cbmmin = cbm; \
    kptCmin = i; \
  } \
  print oldline; \
  print newline; \
  print ""; \
} \
END{ \
  print "Maximum VBM =",vbmmax,"Minimum CBM =",cbmmin,"Band Gap =",cbmmin-vbmmax; \
  print "k-point of VBM =",kptVmax,"k-point of CBM =",kptCmin; \
} \
' < OUTCAR

