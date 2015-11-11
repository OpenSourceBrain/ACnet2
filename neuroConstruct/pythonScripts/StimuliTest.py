import neuroml
import neuroml.writers as writers


from pyneuroml.lems import generate_lems_file_for_neuroml


ref = "StimuliTest"
nml_doc = neuroml.NeuroMLDocument(id=ref)


# Define synapses

syn0 = neuroml.ExpTwoSynapse(id="syn0", gbase="1nS",
                             erev="0mV",
                             tau_rise="0.5ms",
                             tau_decay="10ms")
nml_doc.exp_two_synapses.append(syn0)

syn1 = neuroml.ExpTwoSynapse(id="syn1", gbase="6nS",
                             erev="0mV",
                             tau_rise="2ms",
                             tau_decay="10ms")
nml_doc.exp_two_synapses.append(syn1)

# Define Poisson spiking input

pfs = neuroml.PoissonFiringSynapse(id="poissonFiringSyn",
                                   average_rate="50 Hz",
                                   synapse=syn0.id, 
                                   spike_target="./%s"%syn0.id)
nml_doc.poisson_firing_synapses.append(pfs)


# Define Spike array

sa = neuroml.SpikeArray(id="spikeArray")
sa.spikes.append(neuroml.Spike(id="0", time="100ms"))
sa.spikes.append(neuroml.Spike(id="1", time="500ms"))
sa.spikes.append(neuroml.Spike(id="2", time="700ms"))
sa.spikes.append(neuroml.Spike(id="3", time="705ms"))
nml_doc.spike_arrays.append(sa)


# Include cell

cell_id = 'pyr_4_sym'

nml_doc.includes.append(neuroml.IncludeType('%s.cell.nml'%cell_id))

# Create network
net = neuroml.Network(id=ref+"_network")
nml_doc.networks.append(net)


# Create populations
size0 = 3
pop0 = neuroml.Population(id="PoissonFiringSynCells", size = size0,
                          component=cell_id)
net.populations.append(pop0)

size1 = 3
pop1 = neuroml.Population(id="SpikeArrayCells", size = size1,
                          component=cell_id)
net.populations.append(pop1)

size2 = 1
pop2 = neuroml.Population(id="SpikeArrays", size = size2,
                          component=sa.id)
net.populations.append(pop2)


# Add inputs

pfs_input_list = neuroml.InputList(id="pfsInput", component=pfs.id, populations=pop0.id)
net.input_lists.append(pfs_input_list)


pfs_input_list.input.append(neuroml.Input(id=0, 
                                          target='../%s/0/%s'%(pop0.id, cell_id),
                                          destination="synapses"))
pfs_input_list.input.append(neuroml.Input(id=1, 
                                          target='../%s/1/%s'%(pop0.id, cell_id),
                                          segment_id = "2",
                                          destination="synapses"))
pfs_input_list.input.append(neuroml.Input(id=2, 
                                          target='../%s/2/%s'%(pop0.id, cell_id),
                                          segment_id = "4",
                                          destination="synapses"))
                 
                 
# Create a projection

proj0 = neuroml.Projection(id="Proj0", synapse=syn1.id,
                        presynaptic_population=pop2.id, 
                        postsynaptic_population=pop1.id)
net.projections.append(proj0)


proj0.connections.append(neuroml.Connection(id=0, \
               pre_cell_id="../%s[0]"%(pop2.id),
               post_cell_id="../%s/%i/%s"%(pop1.id,0,cell_id)))
               
proj0.connections.append(neuroml.Connection(id=1, \
               pre_cell_id="../%s[0]"%(pop2.id),
               post_cell_id="../%s/%i/%s"%(pop1.id,1,cell_id),
               post_segment_id = "2",))
               
proj0.connections.append(neuroml.Connection(id=2, \
               pre_cell_id="../%s[0]"%(pop2.id),
               post_cell_id="../%s/%i/%s"%(pop1.id,2,cell_id),
               post_segment_id = "4",))


# Write NML2 file

nml_file = '../generatedNeuroML2/%s.nml'%ref
writers.NeuroMLWriter.write(nml_doc, nml_file)


print("Written network file to: "+nml_file)

# Validate the NeuroML 

from neuroml.utils import validate_neuroml2

validate_neuroml2(nml_file)


# Generate the LEMS file to simulate network (NEURON only...)

generate_lems_file_for_neuroml('sim_%s'%ref, 
                                nml_file, 
                                net.id, 
                                1000, 
                                0.01, 
                                'LEMS_%s.xml'%ref,
                                '../generatedNeuroML2',
                                gen_plots_for_all_v = False,
                                gen_plots_for_only = [pop0.id, pop1.id],
                                gen_saves_for_all_v = False,
                                gen_saves_for_only = [pop0.id, pop1.id],
                                copy_neuroml = False,
                                seed=1234)