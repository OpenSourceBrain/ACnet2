import neuroml
import neuroml.writers as writers

from pyneuroml import pynml
from pyneuroml.lems import generate_lems_file_for_neuroml


ref = "StimuliTest"
nml_doc = neuroml.NeuroMLDocument(id=ref)


# Define synapse
syn0 = neuroml.ExpTwoSynapse(id="syn0", gbase="1nS",
                             erev="0mV",
                             tau_rise="0.5ms",
                             tau_decay="10ms")
nml_doc.exp_two_synapses.append(syn0)

#<poissonFiringSynapse id="poissonFiringSyn" averageRate="50 Hz" synapse="synInput" spikeTarget="./synInput"/>
pfs = neuroml.PoissonFiringSynapse(id="poissonFiringSyn",
                                   average_rate="150 Hz",
                                   synapse=syn0.id, 
                                   spike_target="./%s"%syn0.id)
nml_doc.poisson_firing_synapses.append(pfs)

cell_id = 'pyr_4_sym'

nml_doc.includes.append(neuroml.IncludeType('%s.cell.nml'%cell_id))

# Create network
net = neuroml.Network(id=ref+"_network")
nml_doc.networks.append(net)


# Create populations
size0 = 4
pop0 = neuroml.Population(id="Pop0", size = size0,
                          component=cell_id)
net.populations.append(pop0)
'''
        <inputList id="stimInput" component="pulseGen1" population="iafCells">
            <!--TODO: Fix! want to use target="0"  -->
            <input id="0" target="../iafCells/0/iaf" destination="synapses"/>
        </inputList>'''

pfs_input_list = neuroml.InputList(id="pfsInput", component=pfs.id, populations=pop0.id)
net.input_lists.append(pfs_input_list)


pfs_input_list.input.append(neuroml.Input(id="0", 
                                          target='../%s/0/%s'%(pop0.id, cell_id),
                                          destination="synapses"))
pfs_input_list.input.append(neuroml.Input(id="1", 
                                          target='../%s/1/%s'%(pop0.id, cell_id),
                                          segment_id = "2",
                                          destination="synapses"))
pfs_input_list.input.append(neuroml.Input(id="2", 
                                          target='../%s/2/%s'%(pop0.id, cell_id),
                                          segment_id = "4",
                                          destination="synapses"))
                               


nml_file = '../generatedNeuroML2/%s.nml'%ref
writers.NeuroMLWriter.write(nml_doc, nml_file)


print("Written network file to: "+nml_file)

# Validate the NeuroML 

from neuroml.utils import validate_neuroml2

validate_neuroml2(nml_file)


generate_lems_file_for_neuroml('sim_%s'%ref, 
                                nml_file, 
                                net.id, 
                                1000, 
                                0.01, 
                                'LEMS_%s.xml'%ref,
                                '../generatedNeuroML2',
                                gen_plots_for_all_v = True,
                                gen_saves_for_all_v = True,
                                copy_neuroml = False,
                                seed=1234)