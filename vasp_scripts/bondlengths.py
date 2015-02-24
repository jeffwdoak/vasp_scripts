#!/usr/bin/python

#########################################################################
# Bond Length Calculator                        						#
# Jeff Doak								                                #
# v 1.2 11/29/2011							                            #
#									                                    #
#This program calculates the bond lengths between all the atoms in a 	#
#unit cell, read from a POSCAR or CONTCAR like file. Bond lengths are 	#
#calculated between an atom in the unit cell and all other atoms in the #
#same unit cell, and those in the 26 surrounding unit cells, to get all	#
#possible nearest neighbor bond lengths.				                #
#									                                    #
#The Bond Length Calculator can output results in several ways. A large #
#table containing all bond lengths (27 per pair of atoms) is written to	# 
#a file 'bigbond.out'. In addition, Bond Length Calculator can search	#
#for a given number of closest bonds between one type of atom and atoms	#
#of other, given types. Average bond lengths and standard deviations are#
#output for this calculation.						                    #
#########################################################################

import sys
import numpy as np
from scipy.stats import gaussian_kde
from scipy.stats import histogram

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
    """
    Reads in POSCAR/CONTCAR like file line by line.
    """
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
    lat = np.zeros((3,3))
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
    positions = np.zeros((num_atoms,3))
    for i in range(num_atoms):
        line = f.readline().split()
        for j in range(3):
            positions[i,j] = float(line[j])
    #convert atomic positions to cart coords in not already in them
    cees = ['c','C']
    if not cees.count(convention[0]):
        for i in range(num_atoms):
            positions[i] = np.dot(lat.transpose(),positions[i])
    #scale atomic positions and lattice vectors by scale factor
    lat = lat*scale
    positions = positions*scale
    f.close()

def write_table_to_file(table,name,file_name = "bigbond.out"):
    """Writes any table to a text file. The table is preceeded by the name of
    the structure, as listed in the input file."""
    file_ = open(file_name,'w')
    file_.write(name+"\n")
    for i in range(len(table)):
        for j in range(len(table[i])):
            file_.write(str(table[i,j])+' ')
        file_.write("\n")
    file_.close()

def bond_vector_table(positions):
    """Creates a table with bond vectors between each pair of atoms in the
    unit cell. The table should be antisymmetric, i.e. the bond vector between 
    atoms i and j is negative 1 times the bond vector between atoms j and i."""
    vector_table = np.zeros((len(positions),len(positions),3))
    for i in range(len(positions)):
        for j in range(len(positions)):
            vector_table[i,j] = positions[i]-positions[j]
    return vector_table

def all_neighbor_distances(lat,vector_table,cell_rad = 1):
    """
    Creates an n x n*(1+2*cell_rad)**3 table of bond lengths between all n 
    atoms in the unit cell and every atom in the same unit cell and the 
    (1+2*cell_rad)**3 -1 surrounding cells (the cell_rad number of layers of
    cells surrounding the central one).
    """
    all_neighbor_table = np.zeros((len(vector_table),len(vector_table)*(1+2*cell_rad)**3))
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
                        all_neighbor_table[i,j*(1+2*cell_rad)**3+n] = np.linalg.norm(temp)
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
    bond_table = np.zeros((len(a_atom_list),num_nn))
    for i in range(len(a_atom_list)):
        for j in range(len(full_b_list)):
            #Ignore same atom distances (i.e. a length of 0)
            if big_table[a_atom_list[i],full_b_list[j]] != 0.0:
                if j < num_nn:
                    bond_table[i,j] = big_table[a_atom_list[i],full_b_list[j]]
                elif big_table[a_atom_list[i],full_b_list[j]] < bond_table[i].max():
                    bond_table[i,bond_table[i].argmax()] = big_table[a_atom_list[i],full_b_list[j]]
    bond_stats = [bond_table.mean(),bond_table.std()]
    return bond_table,bond_stats
    #return bond_stats

def NN_config(big_table,a_list,b_list,num_nn):
    """
    Sorts the table of all bond lenghts to find the num_nn closest bond lengths.
    """
    atom_types = [ i for i in range(len(atom_type_list)) for j in range(atom_type_list[i]) ]
    a_atom_list = list_atoms_of_type(a_list,num_atom_types,atom_type_list)
    bond_table = []
    config_table = []
    for i in a_atom_list:
        pos = np.sort(big_table[i])[1:num_nn+1]
        atoms = np.argsort(big_table[i])[1:num_nn+1]
        atoms = [ orig_atom(j,big_table) for j in atoms ]
        types = [ atom_types[k]-1 for k in atoms ]
        num_b = types.count(b_list[-1])
        bond_table.append(pos)
        config_table.append(types)
        print i,pos,atoms,types,types.count(1)
    print bond_table,config_table
    return np.array(bond_table),np.array(config_table)


def orig_atom(atom,big_table):
    """
    Returns the 0-indexed position of atom from the full list of atoms in the
    supercell mapped back into the original unit cell
    """
    n = 0
    bonds_per_pair = len(big_table[0])/len(big_table)
    while atom > bonds_per_pair:
        atom -= bonds_per_pair
        n += 1
    # n is the index of atom in the original atom list
    # atom is now the index of the unit cell the atom came from
    return n

def config_stats(bond_table,config_table,a_list,b_list,num_nn,elements):
    """
    Determine the configurations of b-type atoms around each a-type atom, and
    average the bond lengths for (i) each a-type atom and (ii) each a-type atom
    with the same NN-config.
    """
    a_atom_list = list_atoms_of_type(a_list,num_atom_types,atom_type_list)
    b_atom_list = list_atoms_of_type(b_list,num_atom_types,atom_type_list)
    n_b_types = len(b_list)
    config_list = [ [[],[]] for i in range(num_nn+1) ]
    for i in range(len(bond_table)):
        num_b = 0
        bond_a = []
        bond_b = []
        for j in range(num_nn):
            if config_table[i,j] == 1:
                num_b += 1
                bond_b.append(bond_table[i,j])
            else:
                bond_a.append(bond_table[i,j])
        avg_a = np.mean(bond_a)
        std_a = np.std(bond_a)
        avg_b = np.mean(bond_b)
        std_b = np.std(bond_b)
        print "A-atom",i,"# NN-B",num_b
        print bond_table[i],config_table[i]
        print "    avg b_A",avg_a,"Ang, std b_A",std_a,"Ang"
        print "    avg b_B",avg_b,"Ang, std b_B",std_b,"Ang"
        print
        config_list[num_b][0].append(bond_a)
        config_list[num_b][1].append(bond_b)

    numstr = ""
    astr = ""
    bstr = ""
    for i in range(len(config_list)):
        num_a = len(config_list[i][0])
        num_b = len(config_list[i][1])
        avg_a = np.mean(config_list[i][0])
        std_a = np.std(config_list[i][0])
        avg_b = np.mean(config_list[i][1])
        std_b = np.std(config_list[i][1])
        numstr += "& "+str(num_b)+" "
        astr += "& $%.3f \pm %.3f$ " % (avg_a,std_a)
        bstr += "& $%.3f \pm %.3f$ " % (avg_b,std_b)
        print "# X atoms with",i,"B NN atoms:",num_b
        #print "avg b_A",avg_a,"std b_A",std_a
        #print "avg b_B",avg_b,"std b_B",std_b
        print "$%.3f \pm %.3f$" % (avg_a,std_a)
        print "$%.3f \pm %.3f$" % (avg_b,std_b)
        print
    numstr += "\\\\"
    astr += "\\\\"
    bstr += "\\\\"
    print numstr
    print astr
    print bstr
    return config_list

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
    #for PbS-PbTe sqs half Pb-0 S-1 Te-2
#Edit these numbers!!!!!!!!!!
    a_list = [[0]]  
    b_list = [1,2]
    num_nn = [6]  # Number of nearest neighbors between atoms of type a and b
    bond_stats=[]
    bond_table = []
    for i in range(len(a_list)):
        table,stats = find_nearest_neighbors(all_neighbor_table,a_list[i],b_list,num_nn[i],num_atom_types,atom_type_list)
        bond_table.append(table)
        bond_stats.append(stats)
    bond_table = np.array(bond_table).flatten()
    print "Table of bond lengths"
    print np.sort(bond_table)
    print "Avg. bond length (Ang), Std. Dev. (Ang)"
    print bond_stats
    print 
    gauss = gaussian_kde(bond_table)
    #xdata = np.linspace(2.4,4.0,100)
    xdata = np.linspace(min(bond_table)-3.*bond_stats[0][1],max(bond_table)+3.*bond_stats[0][1],100)
    ydata = gauss(xdata)
    print "Gaussian distribution fit"
    for i in range(len(xdata)):
        print xdata[i],ydata[i]
    print
    nbins = 10
    hist,lowest,binsize,extra = histogram(bond_table,numbins=nbins)
    n = lowest
    print "histogram data"
    print n,"0.0"
    for i in range(len(hist)):
        print n,hist[i]
        n += binsize
        print n,hist[i]
    print n,"0.0"
    print 

#Runs the main method if Bond Length Calculator is called from the command line.
if __name__=="__main__":
    if len(sys.argv[1:]) <= 1:
        main(sys.argv[1:])
    else:
        name = str(sys.argv[1])
        elements = [ str(i) for i in sys.argv[2:] ]
        input_vasp_file(name)
        vector_table = bond_vector_table(positions)
        all_neighbor_table = all_neighbor_distances(lat,vector_table)
        a_list = [0]
        b_list = [1,2]
        num_nn = 6
        bond_table,config_table = NN_config(all_neighbor_table,a_list,b_list,num_nn)
        config_list = config_stats(bond_table,config_table,a_list,b_list,num_nn,elements)
