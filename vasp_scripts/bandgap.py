#!/usr/bin/env python
#bandgap.py v1.0 2-24-2012 Jeff Doak jeff.w.doak@gmail.com
import sys

def get_bandgap(location,tol):
    doscar = open(location)
    for i in range(6):
        l=doscar.readline()
    efermi = float(l.split()[3])
    step1 = doscar.readline().split()[0]
    step2 = doscar.readline().split()[0]
    step_size = float(step2)-float(step1)
    not_found = True
    while not_found:
        l = doscar.readline().split()
        e = float(l.pop(0))
        dens = 0
        for i in range(len(l)/2):
            dens += float(l[i])
        if e < efermi and dens > tol:
            bot = e
        elif e > efermi and dens > tol:
            top = e
            not_found = False
    if top - bot < step_size*2:
        return 0,0,0
    else:
        #return top - bot,bot-efermi,top-efermi
        return top - bot,bot,top

if __name__ == "__main__":
    if len(sys.argv) < 2:
        tol = 1e-3
        name = "DOSCAR"
    elif len(sys.argv) < 3:
        tol = float(sys.argv[1])
        name = "DOSCAR"
    else:
        tol = float(sys.argv[1])
        name = sys.argv[2]
    gap,vbm,cbm = get_bandgap(name,tol)
    print "Gap, VBM, CBm"
    print gap,vbm,cbm
