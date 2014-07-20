#!/usr/bin/python

#########################################################################
# Bond Length Calculator					                        	#
# Jeff Doak							                                	#
# v 1.1 10/18/2010						                            	#
#							                                    		#
#This program calculates the bond lengths between all the atoms in a 	#
#unit cell, read from a POSCAR or CONTCAR like file. Bond lengths are 	#
#calculated between an atom in the unit cell and all other atoms in the #
#same unit cell, and those in the 26 surrounding unit cells, to get all	#
#possible nearest neighbor bond lengths.			                	#
#								                                    	#
#The Bond Length Calculator can output results in several ways. A large #
#table containing all bond lengths (27 per pair of atoms) is written to	# 
#a file 'bigbond.out'. In addition, Bond Length Calculator can search	#
#for a given number of closest bonds between one type of atom and atoms	#
#of other, given types. Average bond lengths and standard deviations are#
#output for this calculation.				                     		#
#########################################################################

import sys,numpy

def usage():
    usage = """        --Bond Length Calculator--
Jeff Doak v1.1 10-18-2010 jeff.w.doak@gmail.com

    Bond Length Calculator can be used to find distances between atoms in a crystal
based on specific criteria.

    Currently, Bond Length Calculator can find nearest neighbor distances between
atoms of two sets of elements. The inputs to this program are the number of nearest
neighbors, and two lists of elements (by number according to the input file)."""
    print usage

#def get_arguments(argv):
    

def input_vasp_file(file = "POSCAR"):
    """Reads in POSCAR/CONTCAR like file line by line."""
    global name,lat,num_atom_types,atom_type_list,num_atoms,positions
    f = open(file,'r')
    #read in structure name
    line = f.readline().split()
    name = ''
    for i in range(len(line)):
        name = name + line[i] + ' '
    #read in scale factor
    scale = float(f.readline().split()[0])
    #read in unit cell lattice vectors
    lat = numpy.zeros((3,3))
    for i in range(3):
        line = f.readline().split()
        for j in range(3):
	    lat[i,j]=float(line[j])
    #read in number of atom types, number of atoms of each type,
    #and total number of atoms
    line = f.readline().split()
    num_atom_types = len(line)
    atom_type_list = []
    for i in range(len(line)):
        atom_type_list.append(int(line[i]))
    num_atoms = 0
    for i in range(num_atom_types):
        num_atoms += atom_type_list[i]
    #read in atom coordinate convention
    convention = f.readline().split()[0]
    #read in atomic positions
    positions = numpy.zeros((num_atoms,3))
    for i in range(num_atoms):
        line = f.readline().split()
	for j in range(3):
	    positions[i,j] = float(line[j])
    #convert atomic positions to cart coords in not already in them
    cees = ['c','C']
    if not cees.count(convention[0]):
        for i in range(num_atoms):
	    positions[i] = numpy.dot(lat.transpose(),positions[i])
    #scale atomic positions and lattice vectors by scale factor
    lat = lat*scale
    positions = positions*scale
    f.close()

def write_table_to_file(table,name,file_name = "bigbond.out"):
    """Writes any table to a text file. The table is preceeded by the name of
    the structure, as listed in the input file."""
    file = open(file_name,'w')
    file.write(name+"\n")
    for i in range(len(table)):
        for j in range(len(table[0])):
	    file.write(str(table[i,j])+' ')
	file.write("\n")
    file.close()

def bond_vector_table(positions):
    """Creates a table with bond vectors between each pair of atoms in the
    unit cell. The table should be antisymmetric, i.e. the bond vector between 
    atoms i and j is negative 1 times the bond vector between atoms j and i."""
    vector_table = numpy.zeros((len(positions),len(positions),3))
    for i in range(len(positions)):
        for j in range(len(positions)):
	    vector_table[i,j] = positions[i]-positions[j]
    return vector_table

def all_neighbor_distances(lat,vector_table,cell_rad = 1):
    """Creates an n x n*(1+2*cell_rad)**3 table of bond lengths between all n 
    atoms in the unit cell and every atom in the same unit cell and the 
    (1+2*cell_rad)**3 -1 surrounding cells (the cell_rad number of layers of
    cells surrounding the central one)."""
    all_neighbor_table = numpy.zeros((len(vector_table),len(vector_table)*(1+2*cell_rad)**3))
    for i in range(len(vector_table)):
        for j in range(len(vector_table)):
	    n = 0
	    #loop over all combinations of lattice vectors scaled by the list
	    #range(-cell_rad,cell_rad+1) (i.e. -1,0,1 for cell_rad=1).
	    #n indexes the current position in the list of lattice vector 
	    #permutations. The list proceeds by looping over l, then k, then h.
	    for h in range(-cell_rad,cell_rad+1):
	        for k in range(-cell_rad,cell_rad+1):
		    for l in range(-cell_rad,cell_rad+1):
		        temp = vector_table[i,j]+h*lat[0]+k*lat[1]+l*lat[2]
		        all_neighbor_table[i,j*(1+2*cell_rad)**3+n] = numpy.linalg.norm(temp)
			n += 1
    return all_neighbor_table

def list_atoms_of_type(subset,num_atom_types,atom_type_list):
    """Creates a list containing the numbers of all atoms of the atom
    types in the list subset."""
    atom_subset_list = []
    n = 0
    for i in range(num_atom_types):
        for j in range(atom_type_list[i]):
	    if subset.count(i):
	        atom_subset_list.append(n)
	    n += 1
    return atom_subset_list

def find_nearest_neighbors(big_table,a_type_list,b_type_list,num_nn,num_atom_types,atom_type_list):
    """Search through the table of all neighbor atom distances to find the
    num_nn nearest neighbors between atoms of types a_type and atoms of types
    b_type."""
    a_atom_list = list_atoms_of_type(a_type_list,num_atom_types,atom_type_list)
    b_atom_list = list_atoms_of_type(b_type_list,num_atom_types,atom_type_list)
    bonds_per_pair = len(big_table[0])/len(big_table)
    #Make list of all bonds containing atoms in b_atom_list
    full_b_list = []
    for i in b_atom_list:
        for j in range(bonds_per_pair):
	    full_b_list.append(i*bonds_per_pair+j)
    #For each atom in a_atom_list, find the num_nn shortest bonds to atoms
    #in b_atom_list (full_b_list)
    bond_table = numpy.zeros((len(a_atom_list),num_nn))
    for i in range(len(a_atom_list)):
        for j in range(len(full_b_list)):
	    #Ignore same atom distances (i.e. a length of 0)
	    if big_table[a_atom_list[i],full_b_list[j]] != 0.0:
	        if j < num_nn:
	            bond_table[i,j] = big_table[a_atom_list[i],full_b_list[j]]
	        elif big_table[a_atom_list[i],full_b_list[j]] < bond_table[i].max():
	            bond_table[i,bond_table[i].argmax()] = big_table[a_atom_list[i],full_b_list[j]]
    bond_stats = [bond_table.mean(),bond_table.std()]
    #return bond_table,bond_stats
    return bond_stats

def main(args):
    if args[0]:
        filename = args[0]
    else:
        filename = "CONTCAR"
    input_vasp_file(filename)
    vector_table = bond_vector_table(positions)
    all_neighbor_table = all_neighbor_distances(lat,vector_table)
    #write_table_to_file(all_neighbor_table,name)
    #for GePbTe sqs half, Ge-0,Pb-1,Te-2
    a_list = [[0]]
    b_list = [1]
    num_nn = [9]
    bond_stats=[]
    for i in range(len(a_list)):
        temp = find_nearest_neighbors(all_neighbor_table,a_list[i],b_list,num_nn[i],num_atom_types,atom_type_list)
        bond_stats.append(temp)
    print bond_stats


#Runs the main method if Bond Length Calculator is called from the command line.
if __name__=="__main__":
    main(sys.argv[1:])
