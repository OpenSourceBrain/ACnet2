#
#   A file which creates a cell array with both neuron types 
#   and the appropriate connections. The network statistics are saved in an external file.
#
#   Author: Christoph Metzner, Padraig Gleeson
#
#   This file builds on an example neuroConstruct script by Padraig Gleeson (Ex3_ManualCreate.py)
#


from neuroml import NeuroMLDocument
from neuroml import Network
from neuroml import Population
from neuroml import Location
from neuroml import Instance
from neuroml import Projection
from neuroml import Connection

import math
import random

import neuroml.writers as writers

network_id = "ACNet2_Full"

nml_doc = NeuroMLDocument(id=network_id)

net = Network(id=network_id)
nml_doc.networks.append(net)

# Get the names of the first Cell Group and Network Connection
exc_group = "pyramidals_48" #"pyramidals48x48"
inh_group = "baskets_12" #"baskets24x24"
exc_group_comp = "pyr_4_sym"
inh_group_comp = "basket"

net_conn_exc_exc = "SmallNet_pyr_pyr"
net_conn_exc_inh = "SmallNet_pyr_bask"
net_conn_inh_exc = "SmallNet_bask_pyr"
net_conn_inh_inh = "SmallNet_bask_bask"

exc_exc_syn = "AMPA_syn"
exc_exc_syn_seg_id = 3       # Middle apical dendrite
exc_inh_syn = "AMPA_syn_inh"
exc_inh_syn_seg_id = 1       # Dendrite
inh_exc_syn = "GABA_syn"
inh_exc_syn_seg_id = 6       # Basal dendrite
inh_inh_syn = "GABA_syn_inh"
inh_inh_syn_seg_id = 0       # Soma


# Excitatory Parameters
XSCALE_ex = 48
ZSCALE_ex = 48
xSpacing_ex = 40 # 10^-6m
zSpacing_ex = 40 # 10^-6m
 
# Inhibitory Parameters
XSCALE_inh = 24
ZSCALE_inh = 24
xSpacing_inh = 80 # 10^-6m
zSpacing_inh = 80 # 10^-6m


numCells_ex = XSCALE_ex * ZSCALE_ex
numCells_inh = XSCALE_inh * ZSCALE_inh

# Connection probabilities (initial value)
connection_probability_ex_ex =   0.15
connection_probability_ex_inh =  0.45
connection_probability_inh_ex =  0.6
connection_probability_inh_inh = 0.6


# Generate excitatory cells 

exc_pop = Population(id=exc_group, component=exc_group_comp, type="populationList", size=XSCALE_ex*ZSCALE_ex)
net.populations.append(exc_pop)

for i in range(0, XSCALE_ex) :
    for j in range(0, ZSCALE_ex):
        # create cells
        x = i*xSpacing_ex
        z = j*zSpacing_ex
        index = i*ZSCALE_ex + j 

        inst = Instance(id=index)
        exc_pop.instances.append(inst)

        inst.location = Location(x=x, y=0, z=z)
    

# Generate inhibitory cells

inh_pop = Population(id=inh_group, component=inh_group_comp, type="populationList", size=XSCALE_inh*ZSCALE_inh)
net.populations.append(inh_pop)

for i in range(0, XSCALE_inh) :
    for j in range(0, ZSCALE_inh):
        # create cells
        x = i*xSpacing_inh
        z = j*zSpacing_inh
        index = i*ZSCALE_inh + j 

        inst = Instance(id=index)
        inh_pop.instances.append(inst)

        inst.location = Location(x=x, y=0, z=z)



proj_exc_exc = Projection(id=net_conn_exc_exc, presynaptic_population=exc_group, postsynaptic_population=exc_group, synapse=exc_exc_syn)
net.projections.append(proj_exc_exc)
proj_exc_inh = Projection(id=net_conn_exc_inh, presynaptic_population=exc_group, postsynaptic_population=inh_group, synapse=exc_inh_syn)
net.projections.append(proj_exc_inh)
proj_inh_exc = Projection(id=net_conn_inh_exc, presynaptic_population=inh_group, postsynaptic_population=exc_group, synapse=inh_exc_syn)
net.projections.append(proj_inh_exc)
proj_inh_inh = Projection(id=net_conn_inh_inh, presynaptic_population=inh_group, postsynaptic_population=inh_group, synapse=inh_inh_syn)
net.projections.append(proj_inh_inh)


# Generate exc -> *  connections

exc_exc_conn_number =  [[0 for x in xrange(ZSCALE_ex)] for x in xrange(XSCALE_ex)]
exc_inh_conn_number =  [[0 for x in xrange(ZSCALE_ex)] for x in xrange(XSCALE_ex)]
count_exc_exc = 0
count_exc_inh = 0
count_inh_exc = 0
count_inh_inh = 0


def add_connection(projection, id, pre_pop, pre_component, pre_cell_id, pre_seg_id, post_pop, post_component, post_cell_id, post_seg_id):
    
    connection = Connection(id=id, \
                            pre_cell_id="../%s/%i/%s"%(pre_pop, pre_cell_id, pre_component), \
                            pre_segment_id=pre_seg_id, \
                            pre_fraction_along=0.5,
                            post_cell_id="../%s/%i/%s"%(post_pop, post_cell_id, post_component), \
                            post_segment_id=post_seg_id,
                            post_fraction_along=0.5)

    projection.connections.append(connection)

for i in range(0, XSCALE_ex) :
    for j in range(0, ZSCALE_ex) :
        x = i*xSpacing_ex
        y = j*zSpacing_ex
        index = i*ZSCALE_ex + j 
        print("Looking at connections for exc cell at (%i, %i)"%(i,j))
        
		# exc -> exc  connections
        conn_type = net_conn_exc_exc
        for k in range(0, XSCALE_ex) :
            for l in range(0, ZSCALE_ex) :

                # calculate distance from pre- to post-synaptic neuron
                xk = k*xSpacing_ex
                yk = l*zSpacing_ex
                distance = math.sqrt((x-xk)**2 + (y-yk)**2)
                connection_probability = connection_probability_ex_ex * math.exp(-(distance/(10.0*xSpacing_ex))**2)

                # create a random number between 0 and 1, if it is <= connection_probability
                # accept connection otherwise refuse
                a = random.random()
                if 0 < a <= connection_probability:
                    index2 = k*ZSCALE_ex + l 
                    count_exc_exc+=1

                    add_connection(proj_exc_exc, count_exc_exc, exc_group, exc_group_comp, index, 0, exc_group, exc_group_comp, index2, exc_exc_syn_seg_id)

                    exc_exc_conn_number[i][j] = exc_exc_conn_number[i][j] + 1
	    
        
        # exc -> inh  connections
        conn_type = net_conn_exc_inh
        for k in range(0, XSCALE_inh):
            for l in range(0, ZSCALE_inh):
			
                # calculate distance from pre- to post-synaptic neuron
                xk = k*xSpacing_inh
                yk = l*zSpacing_inh
                distance = math.sqrt((x-xk)**2 + (y-yk)**2)
                connection_probability = connection_probability_ex_inh * math.exp(-(distance/(10.0*xSpacing_ex))**2)

                # create a random number between 0 and 1, if it is <= connection_probability
                # accept connection otherwise refuse
                a = random.random()
                if 0 < a <= connection_probability:
                    index2 = k*ZSCALE_inh + l 
                    count_exc_inh+=1

                    add_connection(proj_exc_inh, count_exc_inh, exc_group, exc_group_comp, index, 0, inh_group, inh_group_comp, index2, exc_inh_syn_seg_id)

                    exc_inh_conn_number[i][j] = exc_inh_conn_number[i][j] + 1


inh_exc_conn_number =  [[0 for x in xrange(ZSCALE_inh)] for x in xrange(XSCALE_inh)]
inh_inh_conn_number =  [[0 for x in xrange(ZSCALE_inh)] for x in xrange(XSCALE_inh)]
   

for i in range(0, XSCALE_inh) :
    for j in range(0, ZSCALE_inh) :

        x = i*xSpacing_inh
        y = j*zSpacing_inh
        index = i*ZSCALE_inh + j 
        print("Looking at connections for inh cell at (%i, %i)"%(i,j))
        
        # inh -> exc  connections
        conn_type = net_conn_inh_exc
        for k in range(0, XSCALE_ex):
            for l in range(0, ZSCALE_ex):
			
                # calculate distance from pre- to post-synaptic neuron
                xk = k*xSpacing_ex
                yk = l*zSpacing_ex
                distance = math.sqrt((x-xk)**2 + (y-yk)**2)
                connection_probability = connection_probability_inh_ex * math.exp(-(distance/(10.0*xSpacing_ex))**2)

                # create a random number between 0 and 1, if it is <= connection_probability
                # accept connection otherwise refuse
                a = random.random()
                if 0 < a <= connection_probability:
                    index2 = k*ZSCALE_ex + l 
                    count_inh_exc+=1

                    add_connection(proj_inh_exc, count_inh_exc, inh_group, inh_group_comp, index, 0, exc_group, exc_group_comp, index2, inh_exc_syn_seg_id)

                    inh_exc_conn_number[i][j] = inh_exc_conn_number[i][j] + 1
        
        # inh -> inh  connections
        conn_type = net_conn_inh_inh
        for k in range(0, XSCALE_inh) :
            for l in range(0, ZSCALE_inh) :

                # calculate distance from pre- to post-synaptic neuron
                xk = k*xSpacing_inh
                yk = l*zSpacing_inh
                distance = math.sqrt((x-xk)**2 + (y-yk)**2)
                connection_probability = connection_probability_inh_inh * math.exp(-(distance/(10.0*xSpacing_ex))**2)

                # create a random number between 0 and 1, if it is <= connection_probability
                # accept connection otherwise refuse
                a = random.random()
                if 0 < a <= connection_probability:
                    index2 = k*ZSCALE_inh + l 
                    count_inh_inh+=1
                    
                    add_connection(proj_inh_inh, count_inh_inh, inh_group, inh_group_comp, index, 0, inh_group, inh_group_comp, index2, inh_inh_syn_seg_id)
                    
                    inh_inh_conn_number[i][j] = inh_inh_conn_number[i][j] + 1

print("Generated network with %i exc_exc, %i exc_inh, %i inh_exc, %i inh_inh connections"%(count_exc_exc, count_exc_inh, count_inh_exc, count_inh_inh))
# Calculate network statistics

# exc-exc
s1 = len(exc_exc_conn_number)
s2 = len(exc_exc_conn_number[0][:])
length = float(s1*s2)
mean_exc_exc = sum([sum(x) for x in exc_exc_conn_number])/length
std_exc_exc  = math.sqrt((sum([sum([(exc_exc_conn_number[b][a]-mean_exc_exc)**2 for a in xrange(ZSCALE_ex)]) for b in xrange(XSCALE_ex)]))/length) 
# this is a rather complicated way of calculating mean and standard deviation, however importing numpy failed (is that possible with neuroConstruct's
# jython interface?)
max_exc_exc  = max(max(exc_exc_conn_number))
min_exc_exc  = min(min(exc_exc_conn_number))

# exc-inh
mean_exc_inh = sum([sum(x) for x in exc_inh_conn_number])/length
std_exc_inh  = math.sqrt((sum([sum([(exc_inh_conn_number[b][a]-mean_exc_inh)**2 for a in xrange(ZSCALE_ex)]) for b in xrange(XSCALE_ex)]))/length) 
max_exc_inh  = max(max(exc_inh_conn_number))
min_exc_inh  = min(min(exc_inh_conn_number))


# inh-exc
s1 = len(inh_exc_conn_number)
s2 = len(inh_exc_conn_number[0][:])
length = float(s1*s2)
mean_inh_exc = sum([sum(x) for x in inh_exc_conn_number])/length
std_inh_exc  = math.sqrt((sum([sum([(inh_exc_conn_number[b][a]-mean_inh_exc)**2 for a in xrange(ZSCALE_inh)]) for b in xrange(XSCALE_inh)]))/length) 
max_inh_exc  = max(max(inh_exc_conn_number))
min_inh_exc  = min(min(inh_exc_conn_number))

# inh-inh
mean_inh_inh = sum([sum(x) for x in inh_inh_conn_number])/length
std_inh_inh  = math.sqrt((sum([sum([(inh_inh_conn_number[b][a]-mean_inh_inh)**2 for a in xrange(ZSCALE_inh)]) for b in xrange(XSCALE_inh)]))/length) 
max_inh_inh  = max(max(inh_inh_conn_number))
min_inh_inh  = min(min(inh_inh_conn_number))




print "-----------------------------------"
print "Information on network generated: "
print

print 'exc-exc:'
print mean_exc_exc
print std_exc_exc
print max_exc_exc 
print min_exc_exc

print 'exc-inh:'
print mean_exc_inh
print std_exc_inh
print max_exc_inh 
print min_exc_inh

print 'inh-exc:'
print mean_inh_exc
print std_inh_exc
print max_inh_exc 
print min_inh_exc

print 'inh-inh:'
print mean_inh_inh
print std_inh_inh
print max_inh_inh 
print min_inh_inh
#print myProject.generatedElecInputs.details()



#######   Write to file  ######    

print("Saving to file...")
nml_file = network_id+'.net.nml'
writers.NeuroMLWriter.write(nml_doc, nml_file)

print("Written network file to: "+nml_file)



###### Validate the NeuroML ######    
'''
from neuroml.utils import validate_neuroml2
validate_neuroml2(nml_file) 
print "-----------------------------------"
'''

print
quit()



                                     






