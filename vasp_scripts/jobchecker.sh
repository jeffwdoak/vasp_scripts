#!/bin/bash
about(){
cat << EOF
jobchecker.sh  Jeff Doak   8/03/2012  v1.4   jeff.w.doak@gmail.com

This script searches through every subdirectory of the current working
directory and each subdir within those, looking for OUTCAR files. In
each dir that contains an OUTCAR file, the script checks to see if a
Vasp job failed. The criteria for failure used by the script are listed
below. If the job failed, the directory and reason for failure will be printed
to stdout. A list of all failed jobs is also created in an errorfile. The
default error file is $errorfile.
Command Line Arguments:
-h | --help   : Display this help document.
-q | --quiet  : Do not output to stdout jobs that failed. The final results
                  will still be output, and error file will still be created.
-e <filename> : Use the specified file as the errorfile instead of the default.
			Criteria for Vasp Job Failure:
	-Last line of OUTCAR file does not contain the word Voluntary
	-Number of electronic iterations ever reach max number allowed
		in INCAR file (or default of 60 if unspecified)
	-Number of ionic iterations ever reach max number allowed in
		INCAR file (or default of 40 if unspecifed) if job is an
		energy relaxation, or if the number of ionic iterations
		isn't reached if the job is an MD simulation
	-Highest energy electronic band is occupied. A calculation should 
		have some number of unoccupied bands to ensure good electronic
		structure convergence (and good forces and energies).
		If this error is encountered, NBANDS should be increased
		by 1.5 and the calculation rerun.
	-If there is an error file (*.q.e*), and it contains something
		unexpected (i.e. not an error for trying to copy a dir)
		Note: To add exceptions to this list, add a regex that
		matches only the excepted lines and another nested if
		clause to the function, errorfile.
Note: If there are other failure criteria you would like to see
implemented in this script, please let me know and I will add them.
If you want to add more criteria yourself however, you can create a new
function that checks for the desired condition, and add the function name
to the list, \"list\". Any function created should return 1 if the job
finished incorrectly, and 0 otherwise.
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
      -q|--quiet)
        quiet=1
        ;;
      -e)
        errorfile="$2"
        shift
        ;;
    esac
    shift
  done
}

outcar (){
  #Function to check OUTCAR file for correctly finished job.
  if ! tail -1 OUTCAR | grep -q Voluntary
  then
    #exit with incorrect status
    if [ $quiet -eq 0 ]
    then echo "${now#$here/} : OUTCAR file ends unexpectedly."
    fi
    echo "${now#$here/} : OUTCAR file ends unexpectedly." >> $here/$errorfile
    return 1
  fi
}

electronic (){
  #Function to check OSZICAR file for electronic convergence.
  local default_nelm=60
  eval local nelm=`sed -n "s/^NELM *= *\([0-9][0-9]*\)/\1/p" INCAR`
  if [ -z $nelm ]
  then
    nelm=$default_nelm
  fi
  if grep -q "[A-Z][A-Z]*: *$nelm" OSZICAR
  then
    #hit max num electronic steps
    if [ $quiet -eq 0 ]
    then 
      echo "${now#$here/} : Maximum number of electronic steps reached"
      echo "  in one or more ionic step(s)."
    fi
    echo "${now#$here/} : Maximum number of electronic steps reached in one or more ionic step(s)." >> $here/$errorfile
    return 1
  fi
}

ionic (){
  #Function to check OSZICAR file for ionic convergence.
  local default_nsw=40
  eval local nsw=`sed -n "s/^ *NSW *= *\([0-9][0-9]*\)/\1/p" INCAR`
  eval local ibrion=`sed -n "s/^ *IBRION *= *\(-*[0-9]\)/\1/p" INCAR`
  #Set nsw to default if it doesn't appear in INCAR file
  if [ -z $nsw ]
  then
    nsw=$default_nsw
  fi
  #Set ibrion to default if it doesn't appear in INCAR file
  if [ -z $ibrion ]
  then
    if [ $nsw -eq 0 ] || [ $nsw -eq 1 ]
    then
      ibrion=-1
    else
      ibrion=0
    fi
  fi
  #Check for error conditions based on IBRION tag
  if [ $ibrion -eq 0 ]
  then
    #Ionic error conditions for MD simulation
    local newsw=$nsw+1
    if ! grep -q "^ *$nsw[^F]*F=" OSZICAR
    then
      if [ $quiet -eq 0 ]
      then echo "${now#$here/} : Total number of ionic steps not reached for MD simulation."
      fi
      echo "${now#$here/} : Total number of ionic steps not reached for MD simulation." >> $here/$errorfile
      return 1
    elif grep -q "^ *$newsw[^F]*F=" OSZICAR
    then
      if [ $quiet -eq 0 ]
      then echo "${now#$here/} : MD simulation went over set number of ionic steps."
      fi
      echo "${now#$here/} : MD simulation went over set number of ionic steps." >> $here/$errorfile
      return 1
    fi
  else
    #Ionic error conditions for energy relaxation
    if grep -q "^ *$nsw F=" OSZICAR
    then
      #hit max num ionic steps
      if [ $quiet -eq 0 ]
      then echo "${now#$here/} : Maximum number of ionic steps reached."
      fi
      echo "${now#$here/} : Maximum number of ionic steps reached." >> $here/$errorfile
      return 1
    fi
  fi
}

toofewbands(){
  # This function checks an OUTCAR file to see the highest band is occupied or
  # not. Returns an error if there are too few bands (highest band occupied).
  local toofew="highest band is occupied"
  if grep -q "$toofew" OUTCAR
  then
    if [ $quiet -eq 0 ]
    then
      echo "${now#$here/} : Highest band is occupied! Increase NBANDS by 1.5 and rerun!"
    fi
    echo "${now#$here/} : Highest band is occupied! Increase NBANDS by 1.5 and rerun!" >> $here/$errorfile
    return 1
  fi
}

hitastar(){
  #This function removes all instances of the "hit a member ... in another star"
  #vasp error from the .q.e* error file, if it exists.
  local star="hit a member that was already found in another star"
  for file in *.q.e*
  do
    if [ -s $file ]
    then
      if grep -q "$star" $file
      then
        sed -i "/$star/d" $file
        echo "$star" >> $file
      fi
    fi
  done
}

errorfile (){
  #Function to check error file for problems.
  local copy=^[^c] #regex for cp from stderr
  for file in *.q.e*
  do
    if [ -s $file ]
    then
      if grep -q $copy $file
      then
        #There is something unexpected in error file.
        if [ $quiet -eq 0 ]
        then echo "${now#$here/} : Error file contains one or more unexcepted lines."
        fi
        echo "${now#$here/} : Error file contains one or more unexcepted lines." >> $here/$errorfile
        return 1
      fi
    fi
  done
}

search (){
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
  now=$PWD
  flag2=0
  if [ -f OUTCAR ]
  then
    for subroutine in $list
    do
      eval `echo $subroutine`
      if [ ! $? -eq 0 ]
      then
        #Problems with file associated with $subroutine.
        flag2=1
      fi
    done
  fi
  if [ $flag2 -eq 1 ]
  then 
    if [ $quiet -eq 0 ]
    then echo "${now#$here/} : calculation did not finish correctly!"
    fi
    #echo "${now#$here/}" >> $here/$errorfile
    flag1=1
  fi
}

#Run main body of code.
list="outcar electronic ionic errorfile toofewbands hitastar" #Add names of new functions here
here=$PWD
flag1=0 #flag1 goes to 1 if ANY of the calculations don't finish correctly.
quiet=0
errorfile=bad_jobs
arguments $@ #Parse any command-line arguments
echo "Failed Vasp jobs are in the following directories:" > $errorfile
search #Call the function that searches for vasp jobs.

#Deal with the results of the function search.
if [ $flag1 -eq 0 ]
then
  echo "All calculations finished correctly."
  rm $errorfile
  exit 0
else
  if [ ! $quiet -eq 0 ]
  then
    echo "One or more jobs failed. Check the file $errorfile for a list of those jobs."
  fi
  exit 1
fi

