vasp_scripts
============

Bash and Python scripts to perform simple post-processing and analyses on VASP calculation outputs.

Files:

- band_shift.sh - script to peform post-processing on bandstructure 
    calculations of rocksalt supercells. Many assumptions are made in this script. 

- bandgap.py - Calculates the band gap of a calculation using the DOSCAR file.

- bands_around_fermi.sh - Second script to perform post-processing on 
    bandstructure calculations of rocksalt supercells. Many assumptions are made in this script.

- bands_around_fermi2.sh - Slightly different version of the above script.

- bondlengths.py - This program calculates the bond lengths between all the 
    atoms in a unit cell, read from a POSCAR or CONTCAR like file. Bond 
    lengths are calculated between an atom in the unit cell and all other atoms 
    in the same unit cell, and those in the 26 surrounding unit cells, to get 
    all possible nearest neighbor bond lengths.

    The bond length calculator can output results in several ways. A large table 
    containing all bond lengths (27 per pair of atoms) is written to a file 
    'bigbond.out'. In addition, bond length calculator can search for a given 
    number of closest bonds between one type of atom and atoms of other, 
    given types. Average bond lengths and standard deviations are output for 
    this calculation.

- break_sym_vasp.py - Script to move atoms and unitcell vectors by small, 
    random amounts, in order to break any symmetry in the cell and allow for 
    off-lattice relaxation. Script has some POSCAR/CONTCAR details hardcoded, 
    which will need to be changed.

- cleanvasp.sh  - Script to perform various tasks to clean-up VASP calculation 
    outputs. Main uses of cleanvasp.sh include:
  - cleanvasp.sh -r : removes all VASP calculation outputs allowing for a 
      re-run of the calculation. CHGCAR and/or WAVECAR files will be kept if
      ICHARG and/or ISTART are set to 1.
  - cleanvasp.sh -z : Gzips large VASP output files. Files that will be zipped
      include: CHGCAR, WAVECAR, CHG, DOSCAR, LOCPOT, PROCAR, ELFCAR, and 
      vasprun.xml
  - cleanvasp.sh -s : Searches all subdirectories of the current directory for 
      VASP calculations, and runs cleanvasp.sh -z in those directories.

- gen_gulp_input.sh - Extract relaxed unitcell parameters and atomic positions 
    from a GULP output file and write them to a VASP or GULP input-formatted file.

- get_vasp_forces.sh - Prints out the lines contained in an OUTCAR file that 
    contain the forces on atoms.

- jobchecker.sh - Script to check VASP calculation outputs looking for various 
    errors. The script will look in the current directory and all subdirectories 
    for OUTCAR files, and in each directory with an OUTCAR file, the OUTCAR, 
    standard output, standard error, INCAR and OSZICAR files will be checked to 
    see if any errors have occured. Possible errors include:
  - VASP not completing the calculation (the word Voluntary not appearing on the 
      last line of the OUTCAR file).
  - The max number of electronic steps (NELM in INCAR) occuring during any 
      ionic step.
  - The max number of ionic steps (NSW in INCAR) occuring in a relaxation 
      calculation (IBRION != 0)
  - The set number of ionic steps (NSW in INCAR) not occuring in an MD 
      simulation (IBRION = 0)
  - The highest energy band is occupied at some point during the calculation.
  - The standard error file contains anything.

- kpoints_awk.sh - Script to look at the electron eigenvalues at eack k-point, 
    and find the highest-energy occupied band, and the lowest energy unoccupied 
    (occupation < 0.5) band. The energy and occupation of these bands will be 
    printed at every k-point. After searching all k-points, the highest energy 
    occupied and lowest energy unoccupied bands from all the k-points in the 
    calculation will be returned, along with the indices of the k-points from 
    which they came, as well as the corresponding band-gap.

- procar_awk.sh - Script to search the PROCAR file for information related to 
    the projection of bands onto the orbitals of a specific ion in the 
    calculation. Script takes as input 
    1. the PROCAR file to use, 
    2. the # of the ion to look for projection onto, 
    3. the lower bound for projection fraction, and 
    4. the upper bound for projection fraction.
  
  Script will return the bands which have projection fractions onto the ion in 
  question that fall within the bounds given.
                
