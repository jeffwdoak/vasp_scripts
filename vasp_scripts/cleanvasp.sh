#!/bin/bash
about(){
  cat <<-EOF
	cleanvasp.sh  Jeff Doak   12/20/11  v1.0   jeff.w.doak@gmail.com

	This script provides several clean-up utilities for VASP related calculations.

	Command-line arguments:
	-h, --help    Display this help text and exit.
	-r, --restart Remove all VASP and ATAT output files, returning the directory
	              to its pre-calculation state. Note: THIS WILL DELETE DATA! Use
	              with caution!
	-a, --atat    Remove all ATAT output files from directory.
	-p, --poscar  Clean up format of POSCAR and CONTCAR files using convasp.
	-z, --zip     Gzip large VASP output files (CHGCAR WAVECAR CHG LOCPOT PROCAR ELFCAR DOSCAR vasprun.xml)
	-s, --search  Searches the current directory and all subdirectories for all VASP calculations and runs
	              --zip in these directories.
EOF
}

arguments(){
  #Command-line argument parser
  while [ $# -gt 0 ]
  do
    case "$1" in
      -h|--help)
        about
        exit
        ;;
      -r|--restart)
        re_start
	exit
	;;
      -a|--atat)
        clean_atat
	;;
      -p|--poscar)
        clean_poscar
	;;
      -z|--zip)
        zip_files
	;;
      -s|--search)
        search
	;;
    esac
    shift
  done
}

relaxtar() {
  # Tar and zip up relaxation directories.
  #relaxdirs="zeroth_relax first_relax second_relax third_relax"
  mkdir relaxation
  #for i in $relaxdirs
  for i in *_relax
  do
    if [ -d $i ]
    then
      mv $i relaxation
    fi
  done
  tar -cvzf relaxation.tar.gz relaxation
  if [ $? ] && [ -s relaxation.tar.gz ]
  then
    rm -r relaxation
  fi
}

#save_files(){
#  # Remove all VASP related files, except for files to be saved. Files to save:
#  # POSCAR CONTCAR OUTCAR OSZICAR CHGCAR
#
#}

zip_files(){
  # Zip up large VASP output files.
  ziplist="CHGCAR WAVECAR CHG LOCPOT PROCAR ELFCAR DOSCAR vasprun.xml"
  for i in $ziplist
  do
    if [ -s $i ]
    then
      gzip $i
    else
      rm -f $i
    fi
  done
}

clean_poscar(){
  # Use convasp to clean up CONTCAR and POSCAR files.
  if [ -s POTCAR ]
  then
    names=`grep TITEL POTCAR | awk '{print $4}'`
  fi
  files="POSCAR CONTCAR"
  for i in $files
  do
    if [ -s $i ]
    then
      convasp -names $names < $i | convasp -direct | convasp -scale 1.0 > tempcar
      if [ $? -eq 0 ]
      then
	cp tempcar $i
      else
	echo "Error with convasp. No changes made to $i."
      fi
      rm -f tempcar
    fi
  done
}

re_start(){
  # Revert to pre-vasp input files.
  vasp_output="CHG CONTCAR DOSCAR EIGENVAL ELFCAR IBZKPT LOCPOT OSZICAR OUTCAR PCDAT PROCAR PROOUT XDATCAR vasprun.xml"
  atat_output="atomlabel.tmp dos.out energy force.out str_relax.out stress.out"
  queue_output="*.q.*"
  zipped_output="CHG.gz CHGCAR.gz OUTCAR.gz OSZICAR.gz WAVECAR.gz"  # Currently keeps these.
  for file in $vasp_output $atat_output $queue_output
  do
    rm -f $file
  done
  if ! grep -q "ICHARG *= *1" INCAR
  then
    rm -f CHGCAR
  fi
  if ! grep -q "IWAVE *= *1" INCAR
  then
    rm -f WAVECAR
  fi
}

clean_atat(){
  # Remove ATAT output files.
  atat_output="atomlabel.tmp dos.out energy force.out str_relax.out stress.out"
  for file in $atat_output
  do
    rm -f $file
  done
}

search(){
  #Function searches for subdirectories that contain OUTCAR files.
  for folder in *
  do
    if [ -d $folder ]
    then
      cd $folder
      search
      cd ..
    fi
  done
  #If there are no more subdirs in this dir, and it has an OUTCAR file,
  #check to see if a job has finished correctly.
  zip_files
  #now=$PWD
  #flag2=0
  #if [ -f OUTCAR ]
  #then
  #  for subroutine in $list
  #  do
  #    eval `echo $subroutine`
  #    if [ ! $? -eq 0 ]
  #    then
  #      #Problems with file associated with $subroutine.
  #      flag2=1
  #    fi
  #  done
  #fi
  #if [ $flag2 -eq 1 ]
  #then 
  #  if [ $quiet -eq 0 ]
  #  then echo "${now#$here/} : calculation did not finish correctly!"
  #  fi
  #  #echo "${now#$here/}" >> $here/$errorfile
  #  flag1=1
  #fi
}

# Run logic of code.
if [ $# -eq 0 ]
then
  about
  exit
fi
arguments $@ #Parse any command-line arguments
exit
