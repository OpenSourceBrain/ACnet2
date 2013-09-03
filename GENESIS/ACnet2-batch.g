//genesis

/**********************************************************************
** This simulation script and the files included in this package
** are Copyright (C) 2013 by David Beeman (dbeeman@colorado.edu)
** and are made available under the terms of the
** GNU Lesser General Public License version 2.1
** See the file copying.txt for the full notice.
*********************************************************************/

/*======================================================================

  Version 2.5 of a 'simple yet realistic' model of primary auditory layer
  4, described in:

  Beeman D (2013) A modeling study of cortical waves in primary auditory
  cortex. BMC Neuroscience, 14(Suppl 1):P23 doi:10.1186/1471-2202-14-S1-P23
  (http://www.biomedcentral.com/1471-2202/14/S1/P23)

  This model is based on the earlier simple cortical model
  dualexpVA-HHnet.g:

  The GENESIS implementation of the dual exponential conductance version of
  the Vogels-Abbott (J. Neurosci. 25: 10786--10795 (2005)) network model
  with Hodgkin-Huxley neurons.  Details are given in Brett et al. (2007)
  Simulation of networks of spiking neurons: A review of tools and
  strategies.  J. Comput. Neurosci. 23: 349-398.
  http://senselab.med.yale.edu/SenseLab/ModelDB/ShowModel.asp?model=83319

  A network of simplified Regular Spiking neocortical neurons providing
  excitatory connections and Fast Spiking interneurons providing inhibitory
  connections.  Further description is given with the RSnet.g example from
  the GENESIS Neural Modeling Tutorials
  (http://genesis-sim.org/GENESIS/UGTD/Tutorials/)

  ======================================================================*/

str script_name = "ACnet2-batch"
str RUNID = "B0003"        // default ID string for output file names

float tmax = 1.0      	  // max simulation run time (sec)
float dt = 20e-6	  // simulation time step
float out_dt = 0.0001     // output every 0.1 msec
float netview_dt = 0.0002 // slowest clock for netview display

// Booleans indicating the type of calculations or output
int debug = 3        // display additional information during setup
int batch = 1        // if (batch) run the default simulation without graphics
int graphics = 0     // display control panel, graphs, optionally net view
int netview = 0      // show network activity view (slow, but pretty)
int netview_output = 1	// Record network output (soma Vm) to a file
int binary_file = 0	// if 0, use asc_file to produce ascii output
			// else use disk_out to produce binary FMT1 file
int write_asc_header = 1 // write header information to ascii file
int EPSC_output = 1  // output Ex_ex EPS currents to file
int calc_EPSCsum = 1 // calculate summed excitatory post-synaptic currents

int use_weight_decay = 0 // Use exponential decay of weights with distance
int use_prob_decay = 1 // Use connection probablility exp(-r*r/(sigma*sigma))
int connect_network = 1  // Set to 0 for testing with unconnected cells
int hflag = 1    // use hsolve if hflag = 1
int hsolve_chanmode = 4  // chanmode to use if hflag != 0
int use_sprng = 1 // Use SPRNG random number generator, rather than default RNG


/* Specification of stimulation input patterns (distribution of inputs)
   and type of input (e. g. a steady spike train gated with a pulsegen
*/

str input_type = "pulsed_spiketrain"  // pulsed spike train input

str input_pattern = "row"     // input goes to an entire row of cells
// str input_pattern = "line" // input goes to a line of cells
// str input_pattern = "box"   // use a square block of cells

// Set random number seed. If seed is 0, set randseed from clock,
// else from given seed
int seed = 0  // Simulation will give different random numbers each time

/****** the seed is set here to reproduce the results in Beeman (2013) *****/
int seed = 1369497795

if (use_sprng)
    setrand -sprng
end

if (seed)
    randseed {seed}
else
    seed = {randseed}
end

/* Customize these strings and parameters to modify this simulation for
   other excitatory or inhibitory cells.
*/

str Ex_cellfile = "pyr_4_asym.p"  // name of the excitatory cell parameter file
str Inh_cellfile = "bask.p"  // name of the inhibitory cell parameter file
str protodefs_file = "protodefs.g" // file that creates prototypes in /library

str Ex_cell_name = "pyr_4"   // name of the excitatory cell
str Inh_cell_name = "bask_4" // name of the inhibitory cell

// Paths to synapses on cells: cell_synapse = compartment-name/synchan-name
// e.g. Ex_inh_synpath is path to inhibitory synapse on excitatory cell
str Ex_ex_synpath = "apical3/AMPA_pyr" // pyr middle apical dendrite AMPA
str Ex_inh_synpath = "basal0/GABA_pyr" // pyr prox basal GABA
str Inh_ex_synpath = "dend/AMPA_bask"  // bask dend AMPA
str Inh_inh_synpath = "soma/GABA_bask" // bask soma GABA
str Ex_bg_synpath = "basal1/AMPA_pyr"  // synchan for background input

// Excitatory drive inputs - path to synapse on Ex and Inh cells to apply drive
str Ex_drive_synpath = "apical1/AMPA_pyr" // drive -> pyr prox oblique apical
str Inh_drive_synpath = "dend/AMPA_bask_drive"  // drive -> bask dendrite

// Label to appear on the graph
str graphlabel = "Vm of row center cell"
str net_efile = "Ex_netview"  // filename prefix for Ex_netview data
str net_ifile = "Inh_netview" // filename prefix for Inh_netview data
str net_EPSC_file = "EPSC_netview" // filename prefix for Ex_ex_synpath Ik (EPSCs)
str EPSC_sum_file = "EPSC_sum" // filename prefix for summed Ex_ex_synpath Ik
str sum_file = "run_summary"    // text file prefix for summary of run params

/* Size of the excitatory and inhibitory networks. The default size is
   a square patch of cortex with 48 x 48 excitatory cells and 24 x 24
   inhibitory, spanning two octaves.  For a longer piece, spanning six
   octaves (about 1.92 x 5.76 mm), use Ex_NY = 144 and Inh_NY = 72.
*/

int Ex_NX = 48; int Ex_NY = 48
int Inh_NX = 24; int Inh_NY = 24

/* In this extension of the RSnet tutorial script, there will be a layer of
   excitatory cells on a grid, and another layer of inhibitory cells,
   with twice the grid spacing, in order to have a 4:1 ratio of
   excitatory to inhibitory cells.
*/

/* Neurons will be placed on a two dimensional NX by NY grid, with points
   SEP_X and SEP_Y apart in the x and y directions.

   Cortical networks typically have pyramidal cell separations on the order
   of 10 micrometers, and can have local pyramidal cell axonal projections
   of up to a millimeter or more.  For small network models, one sometimes
   uses a larger separation, so that the model represents a larger cortical
   area.  In this case, the neurons in the model are a sparse sample of the
   those in the actual network, and each one of them represents many in the
   biological network.  To compensate for this, the conductance of each
   synapse may be scaled by a synaptic weight factor, to represent the
   increased number of neurons that would be providing input in the actual
   network.  Here, we use a separation of 40 um that is larger than the
   spacing between cells in A1. With no axonal delays, actual spacing is
   irrelevant.
*/

// 40 micrometer spacing between cells
float Ex_SEP_X = 40e-6
float Ex_SEP_Y = 40e-6 
float Inh_SEP_X = 2*Ex_SEP_X  // There are 1/4 as many inihibitory neurons
float Inh_SEP_Y = 2*Ex_SEP_Y

/* "SEP_Z" should be set to the actual layer thickness, in order to allow
   possible random displacements of cells from the 2-D lattice.  Here, it
   needs to be large enough that any connections to distal dendrites will
   be within the range -SEP_Z to SEP_Z.
*/

float Ex_SEP_Z = 1.0
float Inh_SEP_Z = Ex_SEP_Z

// These definitions depend on MGBv_input.g or simple_inputs.g
// int Ninputs = Ex_NY - 16 // Number of auditory input channels from the thalamus (MGB)
int Ninputs = 2 // In this case, there will be two inputs MGBv[1] and MGBv[2]

float drive_weight = 1.0 // Default weight of all input drive connections
float octave_distance = 0.96e-3 // approx 1 mm/octave - integer rows/octave = 24
// octave_distance = Ex_SEP_Y // just one row

int rows_per_octave = {round {octave_distance/Ex_SEP_Y}}

// number of rows below and above "target row" getting input

// int input_spread = {round {rows_per_octave/6.0}} // 1/6 octave
int input_spread = 0 // no spread of thalamic connections to other rows

float input_delay, input_jitter // used in simple-inputs.g or MGBv_input.g
float input_delay = 0.0
float input_jitter = 0.0

// float spike_jitter = 0.0005 // 0.5 msec jitter in thalamic inputs
float spike_jitter = 0.0  //default is no jitter in arrival time

/* parameters for synaptic connections */

float syn_weight = 1.0 // synaptic weight, effectively multiplies gmax

/* 
   prop_delay is the delay per meter, or 1/cond_vel.  The value often used
   corresponds to Shlosberg et al. 2008 rat somatosenory cortex axonal cond
   velocities of RS and Martinotti cell axons ranging from 0.2 to 0.3
   m/sec.  With a value of 0.25 m/sec, cells 1 mm apart have a 4 msec
   conduction delay

   However this value is for longer distance interlaminar axons between
   layer 5 and layer 1 in rat somatosensory cortex.  Estimates for shorter
   distance (< a few mm) intralaminar unmeyelinated axons are in the range
   of 60-90 mm/s. (Salin and Price, 1996).

   The slower velocity of 0.08 m/sec can have a signigicant effect in the
   delay of the onset of inhibition, as connected cells 400 um apart can
   have a delay of 5 msec.

*/
float prop_delay = 12.5 //  delay per meter, or 1/cond_vel

float Ex_ex_gmax = 30e-9   // Ex_cell ex synapse
float Ex_inh_gmax = 0.6e-9  // Ex_cell inh synapse
float Inh_ex_gmax = 0.15e-9  // Inh_cell ex synapse
float Inh_inh_gmax = 0.0e-9 // Inh_cell inh synapse 
float Ex_bg_gmax = 80e-9  // Ex_cell background excitation

// Initially use same values as network synapses
float Ex_drive_gmax = 50e-9 // Ex_cell thalamic input
float Inh_drive_gmax = 1.5e-9 // Inh_cell thalamic input

// Poisson distributed random excitation frequency of Ex_cells
// NOTE: For use with hsolve, the synchan frequency must be set to a non-zero
// value before the solver setup.  Then it may be set to any value, including zero.

float frequency = 8.0

// time constants for dual exponential synaptic conductance

float tau1_ex = 0.001     // rise time for excitatory synapses
float tau2_ex =  0.003    // decay time for excitatory synapses
float Inh_tau1_ex = 0.003 // make a special case for Inh cell excitatory channels
float Inh_tau2_ex = 0.003
float tau1_inh = 0.005    // rise time for inhibitory synapses
float tau2_inh =  0.012   // decay time for inhibitory synapses
// float tau2_inh =  0.025   // decay time for "schizophrenic" case

/* Give a range of tau2_inh from tau2_inh*(1-tau2_inh_spreadfactor)
   to tau2_inh*(1+tau2_inh_spreadfactor) - set to zero for a single value
   Set to 0.6 for a range of 8 +/- 4.8 msec, or 25 +/- 15 msec
*/

float tau2_inh_spreadfactor = 0.0

/* for debugging and exploring - see comments in file for details
   Usage:   synapse_info path_to_synchan
   Example: synapse_info /Ex_layer/Ex_cell[5]/dend/Ex_channel
*/
if (debug)
    include synapseinfo.g
end

// =============================
//   Function definitions
// =============================

/**** set synchan parameters ****/

function set_Ex_ex_gmax(value)  // excitatory synchan gmax in Ex_cell
   float value                  // value in nA
   Ex_ex_gmax = {value}*1e-9	// use this for driver input also
   setfield /Ex_layer/{Ex_cell_name}[]/{Ex_ex_synpath} gmax {Ex_ex_gmax}
end

function set_Ex_drive_gmax(value)  // thalamic drive synchan gmax in Ex_cell
   float value                  // value in nA
   Ex_drive_gmax = {value}*1e-9
   setfield /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} gmax {Ex_drive_gmax}
end

function set_Ex_bg_gmax(value)  // background ex  synchan gmax in Ex_cell
   float value                  // value in nA
   Ex_bg_gmax = {value}*1e-9
   setfield /Ex_layer/{Ex_cell_name}[]/{Ex_bg_synpath} gmax {Ex_bg_gmax}
end

function set_Inh_ex_gmax(value)   // excitatory synchan gmax in Inh_cell
   float value			  // value in nA
   Inh_ex_gmax = {value}*1e-9	  // use this for driver input also
   setfield /Inh_layer/{Inh_cell_name}[]/{Inh_ex_synpath} gmax {Inh_ex_gmax}
end

function set_Inh_drive_gmax(value) // thalamic drive synchan gmax in Inh_cell
   float value			  // value in nA
   Inh_drive_gmax = {value}*1e-9
   setfield /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} gmax {Inh_drive_gmax}
end

function set_Ex_inh_gmax(value)  // inhibitory synchan gmax in Ex_cell
   float value			  // value in nA
   Ex_inh_gmax = {value}*1e-9
   setfield /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} gmax {Ex_inh_gmax}
end

function set_Inh_inh_gmax(value)  // inhibitory synchan gmax in Inh_cell
   float value			  // value in nA
   Inh_inh_gmax = {value}*1e-9
   setfield /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} gmax {Inh_inh_gmax}
end

function set_all_gmax // set all gmax to Ex_ex_gmax, ..., Ex_bg_gmax
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_ex_synpath} gmax \
        {Ex_ex_gmax}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} gmax \
        {Ex_inh_gmax}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_ex_synpath} gmax \
        {Inh_ex_gmax}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath}  gmax \
        {Inh_inh_gmax}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} gmax \
        {Ex_drive_gmax}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_bg_synpath} gmax \
        {Ex_bg_gmax}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath}  gmax \
        {Inh_drive_gmax}
end

/* NOTE: Functions to set synchan tau1 and tau2 values should be called
   only prior to hsolve SETUP.  Unlike the case with gmax, which may be
   changed if followed by a reset, changing the taus of hsolved synchans
   causes erroneous results.
*/
function set_all_taus  // assume all synchans of one type have same taus
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_ex_synpath} tau1 {tau1_ex} \
        tau2 {tau2_ex}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} tau1 {tau1_ex} \
        tau2 {tau2_ex}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} tau1 {tau1_inh} \
        tau2 {tau2_inh}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_ex_synpath} tau1 {Inh_tau1_ex} \
        tau2 {Inh_tau2_ex}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} tau1 {tau1_ex}\
        tau2 {tau2_ex}
    setfield /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} tau1 {tau1_inh} \
        tau2 {tau2_inh}
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_bg_synpath} tau1 {tau1_ex} \
        tau2 {tau2_ex}
end

function set_inh_tau2(tau2)
    float tau2, tau2_min, tau2_max
    tau2_inh = tau2
    if (tau2_inh_spreadfactor != 0.0)
        tau2_min = tau2*(1-tau2_inh_spreadfactor)
        tau2_max = tau2*(1+tau2_inh_spreadfactor)
        setrandfield /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} \
            tau2 -uniform {tau2_min} {tau2_max}
        setrandfield /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} \
            tau2 -uniform {tau2_min} {tau2_max}
    else
        setfield /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} tau2 {tau2}
        setfield /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} tau2 {tau2}
    end 
end

/***** functions to connect network *****/ 

/* This is a specialized version of planarconnect where the connection
   probability is weighted with a probability prob0*exp(-r*r/(sigma*sigma))
   where r is the radial distance between source and destination
   in the x-y plane.

   Unlike the more general version, it is assumed that all cells in the
   source network are used as sources.  The destination region is defined
   as a ring between a radius rmin and rmax in the destination network.
   The sources are all assumed to be spikegen objects, and the destinations
   to be synchans, or variants such as facsynchans.
   
   An example of the ith cell in the source network would be:

   {src_cell_path}[{i}]{src_spikepath}

   with

   src_cell_path = /Ex_layer/{Ex_cell_name}
   src_spikepath = "soma/spike"

   An example destination would use:

   dst_cell_path = /Inh_layer/{Inh_cell_name}
   dst_synpath = {Inh_ex_synpath}

   For example:

   planarconnect_probdecay /Ex_layer/{Ex_cell_name} "soma/spike" {Ex_NX*Ex_NY} \
      /Inh_layer/{Inh_cell_name} {Inh_ex_synpath} {Inh_NX*Inh_NY} \
      0.0 {pyr_range} {Ex2Inh_prob} {Ex_sigma}

*/

function planarconnect_probdecay(src_cell_path, src_spikepath, n_src, \
    dst_cell_path, dst_synpath, n_dst, \
    rmin, rmax, prob0, sigma)

    str src, src_cell_path, src_spikepath, dst, dst_cell_path, dst_synpath

    int n_src, n_dst, i, j
    float rmin, rmax, prob0, sigma, x, y, dst_x, dst_y, prob, rsqr

    float decay = 1.0/(sigma*sigma)
    float rminsqr = rmin*rmin
    float rmaxsqr = rmax*rmax

    /* loop over all source cells - this will be all cells in layer */
    for (i = 0 ; i < {n_src} ; i = i + 1)

       src = {src_cell_path} @ "[" @ {i} @ "]/" @ {src_spikepath}
       x = {getfield {src} x}
       y = {getfield {src} y}

        /* loop over all possible destination cells - all in dest layer */
        for (j = 0 ; j < {n_dst} ; j = j + 1)
            dst = {dst_cell_path} @ "[" @ {j} @ "]/" @ {dst_synpath}
            dst_x = {getfield {dst} x}
            dst_y = {getfield {dst} y}

            rsqr = (dst_x - x)*(dst_x - x) + (dst_y - y)*(dst_y - y)
            if( ({rsqr} >= {rminsqr}) && ({rsqr} <= {rmaxsqr}) )
                prob = {prob0}*{exp {-1.0*{rsqr*decay}}}
                if ({rand 0 1} <= prob)
                  addmsg {src} {dst} SPIKE
                end
            end
        end // dst loop
    end // src loop
end

/***** functions to set weights and delays *****/

function set_weights(weight)
    float weight
    syn_weight = weight  // set the global variable to the new weight
    // use fixed weights  // The defualt
    volumeweight /Ex_layer/{Ex_cell_name}[]/soma/spike \
                /Ex_layer/{Ex_cell_name}[]/{Ex_ex_synpath} \
                -fixed {syn_weight}
    volumeweight /Ex_layer/{Ex_cell_name}[]/soma/spike \
                /Inh_layer/{Inh_cell_name}[]/{Inh_ex_synpath} \
                -fixed {syn_weight}
    volumeweight /Inh_layer/{Inh_cell_name}[]/soma/spike  \
            /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} \
                -fixed {syn_weight}
    volumeweight /Inh_layer/{Inh_cell_name}[]/soma/spike  \
                /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} \
                -fixed {syn_weight}
    echo "All maxium synaptic weights set to "{weight}
end


/* If the delay is zero, set it as the fixed delay, else use the conduction
   velocity to calculate delays based on radial distance to the target.
   For a fixed delay, either planardelay or volumedelay can be used.
   As axonal conduction velocities are the same in both the vertical
   direction, and in the horizontal plane, volumedelay should be
   used to account for the vertical distance traveled to the dendrites.
*/

function set_delays(delay)
    float delay
    prop_delay = delay
    if (delay == 0.0)
        planardelay /Ex_layer/{Ex_cell_name}[]/soma/spike -fixed {delay}
        planardelay /Inh_layer/{Inh_cell_name}[]/soma/spike -fixed {delay}
    else
        volumedelay /Ex_layer/{Ex_cell_name}[]/soma/spike -radial {1/delay}
        volumedelay /Inh_layer/{Inh_cell_name}[]/soma/spike -radial {1/delay}
    end
    echo "All propagation delays set to "{delay}" sec/m"
end

function set_frequency(value) // set Ex_ex average random firing freq
    float value
    frequency = value
    setfield /Ex_layer/{Ex_cell_name}[]/{Ex_bg_synpath} frequency {frequency}
end

/**** functions to output results ****/

function make_output(rootname) // asc_file to {rootname}_{RUNID}.txt
    str rootname, filename
    if ({exists {rootname}})
        call {rootname} RESET // this closes and reopens the file
        delete {rootname}
    end
    filename = {rootname} @ "_" @ {RUNID} @ ".txt"
    create asc_file {rootname}
    setfield ^    flush 1    leave_open 1 filename {filename}
    setclock 1 {out_dt}
    useclock {rootname} 1
end

/* This function returns a string to be used for a one-line header at the
   beginning of an ascii file that contains values of Vm or Ik for each
   cell in the network, at time steps netview_dt. When binary file output
   is used with the disk_out object, the file contains information on the
   network dimensions that are needed for the xview object display.  When
   asc_file is used to generate the network data, this information is
   provided in a header of the form:

   #optional_RUNID_string Ntimes start_time dt NX NY SEP_X SEP_Y x0 y0 z0

   This header may be read by a data analysis script, such as netview.py.

   The line must start with "#" and can optionally be followed immediately
   by any string.  Typically this is some identification string generated
   by the simulation run.  The following parameters, separated by blanks or
   any whitespace, are:

   * Ntimes - the number of lines in the file, exclusive of the header

   * start_time - the simulation time for the first data line (default 0)

   * dt - the time step used for output (netview_dt)

   * NX, NY - the integer dimensions of the network

   *  SEP_X, SEP_Y - the x,y distances between cells (optional)

   * x0, y0, z0 - the location of the compartment (data source) relative to
     the cell origin (often ignored)

   A typical header generated by this simulation is:

   #B0003	5000 0.0 0.0002	 48 48 4e-05  4e-05 0.0	 0.0	0.0
*/

function make_header(diskpath)
    str diskpath
    int Ntimes = {round {tmax/netview_dt}} // outputs t = 0 thru tmax - netview_dt
    str header_str = "#" @ {RUNID} @ "  " @ {Ntimes} @ " 0.0 " @ {netview_dt} @ "  "
    if(diskpath == {net_efile})
        header_str = {header_str} @ {Ex_NX} @ " " @ {Ex_NY} @ " " @ {Ex_SEP_X} @ \
        "  " @ {Ex_SEP_Y} @ " 0.0  0.0  0.0"
    elif(diskpath == {net_ifile})
        header_str = {header_str} @ {Inh_NX} @ " " @ {Inh_NY} @ " " @ {Inh_SEP_X} @ \
        "  " @ {Inh_SEP_Y} @ " 0.0  0.0  0.0"
    elif(diskpath == {net_EPSC_file})
	header_str = {header_str} @ {Ex_NX} @ " " @ {Ex_NY} @ " " @ {Ex_SEP_X} @ \
	"  " @ {Ex_SEP_Y} @ " 0.0  0.0	0.0"
    else
        echo "Wrong file name root!"
        header_str = ""
    end    
    return {header_str}
end

/* Create disk_out element to write netview data to a binary or ascii  file */
function do_disk_out(diskpath,srcpath, srcelement, field)
    str name, diskpath, srcpath, srcelement, field, filename
    if ({exists /output/{diskpath}})
            delete /output/{diskpath}
    end
    if(binary_file==0) // use asc_file
	filename = {diskpath}  @ "_" @ {RUNID} @ ".txt"
        create asc_file /output/{diskpath}
        setfield /output/{diskpath} leave_open 1 flush 0 filename {filename}
        setfield /output/{diskpath} float_format %.3g notime 1
        if(write_asc_header==1)
            setfield /output/{diskpath} append 1
            call /output/{diskpath} OUT_OPEN
            call /output/{diskpath} OUT_WRITE {make_header {diskpath}}
            reset
        end
    else  // use disk_out to make FMT1 binary file
        filename = {diskpath}  @ "_" @ {RUNID} @ ".dat"
        create disk_out /output/{diskpath}
	setfield /output/{diskpath} leave_open 1 flush 0 filename {filename}
    end //if(binary_file==0)
    if({hflag} && {hsolve_chanmode > 1})
	foreach name ({getelementlist {srcpath}})
            addmsg {name}/solver /output/{diskpath} SAVE \
		{findsolvefield {name}/solver {name}/{srcelement} {field}}
	end
    else
        foreach name ({getelementlist {srcpath}})
            addmsg {name}/{srcelement} /output/{diskpath} SAVE {field}
        end
    end
end

function do_network_out
   if(netview_output)
      setclock 2 {netview_dt}
      do_disk_out {net_efile} /Ex_layer/{Ex_cell_name}[] soma Vm
      useclock /output/{net_efile} 2
      do_disk_out {net_ifile} /Inh_layer/{Inh_cell_name}[] soma Vm
      useclock /output/{net_ifile} 2
   end
   if (EPSC_output)
      do_disk_out {net_EPSC_file} /Ex_layer/{Ex_cell_name}[] {Ex_ex_synpath} Ik
      setclock 2 {netview_dt}
      useclock /output/{net_EPSC_file} 2
   end
end

/* ------------------------------------------------------------------
 Create a calculator object to hold summed Ex_ex currents, and then
 send all Ex_ex synaptic currents to it for summation

  NOTE:  Previous versions of make_EPSCsummer also summed the excitatory
  currents from the thalamic input drive. Here, the effect of any input
  drive would be indirect through propagation of its effect from cell to
  cell via synaptic connections.
------------------------------------------------------------------- */

str data_source = "/EPSCsummer" // data_source sums Ex_cell ex currents

function make_EPSCsummer // data_source sums Ex_cell ex currents
    int i
    create calculator {data_source}
    useclock {data_source} 1 // the clock for out_dt
    for (i=0; i < Ex_NX*Ex_NY; i = i + 1)
        if({hflag} && {hsolve_chanmode > 1})
            addmsg /Ex_layer/{Ex_cell_name}[{i}]/solver {data_source} SUM \
              {findsolvefield /Ex_layer/{Ex_cell_name}[{i}]/solver \
              {Ex_ex_synpath} Ik}
        else
            addmsg /Ex_layer/{Ex_cell_name}[{i}]/{Ex_ex_synpath} \
                {data_source} SUM Ik
//            addmsg /Ex_layer/{Ex_cell_name}[{i}]/{Ex_drive_synpath} \
//                {data_source} SUM Ik
        end
    end
end

function do_EPSCsum_out
    if (calc_EPSCsum)
        if (! {exists {data_source}})
            make_EPSCsummer
        end
        make_output {EPSC_sum_file}
        addmsg {data_source} {EPSC_sum_file} SAVE output
    end
end

function do_run_summary
    str filename = {sum_file} @ "_" @ {RUNID} @ ".txt"
    openfile {filename} w
    writefile {filename} "Script:" {script_name} "  RUNID:" {RUNID} "  seed:" {seed} \
        "  date:" {getdate}
    writefile {filename} "tmax:" {tmax} " dt:" {dt} " out_dt:" {out_dt} \
        " netview_dt:" {netview_dt} 
    writefile {filename} "EPSC_output:" {EPSC_output} "  netview_output:" {netview_output}
    writefile {filename} "Ex_NX:" {Ex_NX} " Ex_NY:" {Ex_NY} " Inh_NX:" \
        {Inh_NX} "  Inh_NY:" {Inh_NY}
    writefile {filename} "Ex_SEP_X:" {Ex_SEP_X} " Ex_SEP_Y:" {Ex_SEP_Y} \
        "  Inh_SEP_X:" {Inh_SEP_X}  "  Inh_SEP_Y:" {Inh_SEP_Y}
    writefile {filename} "Ninputs:" {Ninputs} " bg Ex freq:" {frequency} \
        " bg Ex gmax:" {Ex_bg_gmax}
    writefile {filename} "================== Network parameters ================="
    writefile {filename} "Ex_ex_gmax:" {Ex_ex_gmax} " Ex_inh_gmax:" {Ex_inh_gmax} \
        "  Inh_ex_gmax:" {Inh_ex_gmax} "  Inh_inh_gmax:" {Inh_inh_gmax}
    writefile {filename} "tau1_ex:" {tau1_ex} "  tau2_ex:" {tau2_ex}  \
        "  tau1_inh:" {tau1_inh} "  tau2_inh:" {tau2_inh}
    writefile {filename} "syn_weight: " {syn_weight} \
        " prop_delay:" {prop_delay} " default drive weight:" {drive_weight}
    writefile {filename} "Ex_drive_gmax: " {Ex_drive_gmax} \
        "  Inh_drive_gmax: " {Inh_drive_gmax}
    /* The code below is specific to the input model -- see MGBv_input.g */
    writefile {filename} "MGBv input delay: " {input_delay} \
	"  MGBv input jitter :" {input_jitter}
    writefile {filename} "input_spread : " {input_spread} \
        "  connect_network :" {connect_network} "use_weight_decay: " \
        {use_weight_decay}
    writefile {filename} "================== Thalamic inputs ================="
    writefile {filename} "Input" " Row " "Frequency" "    State" "   Weight" \
        "    Delay" "    Width" " Period"
    int input_num, input_row
    str  input_source = "/MGBv" // Name of the array of input elements
    float input_freq, delay, width, interval, drive_weight
    str pulse_src, spike_out
    str toggle_state
    floatformat %10.3f
    for (input_num = 1; input_num <= {Ninputs}; input_num= input_num +1)
        pulse_src = {input_source} @ "[" @ {input_num} @ "]" @ "/spikepulse"
        spike_out = {input_source} @ "[" @ {input_num} @ "]" @ "/soma/spike"
        input_row  = \
          {getfield {{input_source} @ "[" @ {input_num} @ "]"} input_row}
        input_freq  = \
          {getfield {{input_source} @ "[" @ {input_num} @ "]"} input_freq}
        drive_weight = \
          {getfield {{input_source} @ "[" @ {input_num} @ "]"} output_weight}
        delay = {getfield {pulse_src} delay1 }
        width = {getfield {pulse_src} width1}
        interval = {getfield {pulse_src} delay1} + {getfield {pulse_src} delay2}
        // get the spiketoggle state
        toggle_state = "OFF"
        if ({getfield {pulse_src} level1} > 0.5)
            toggle_state = "ON"
        end
        writefile {filename} {input_num} {input_row} -n -format "%5s"
        writefile {filename} {input_freq} {toggle_state} {drive_weight} \
            {delay} {width} {interval}  -format %10s
    end
    writefile {filename} "----------------------------------------------------------"
    writefile {filename} "Notes:"
    closefile {filename}
    floatformat %0.10g
end

function change_RUNID(value)
    str value
    RUNID =  value
    // Set up new file names for output
    do_network_out
    do_EPSCsum_out
end

function step_tmax
    echo "dt = "{getclock 0}"   tmax = "{tmax}
    echo "RUNID: " {RUNID}
    echo "START: " {getdate}
    step {tmax} -time
    echo "END  : " {getdate}
    do_run_summary
end

//=============================================================
//    Functions to set up the network
//=============================================================

function make_prototypes
  /* Step 1: Assemble the components to build the prototype cell under the
     neutral element /library.  This is done by including "prododefs.g"
     before using the function make_prototypes.
  */
  
  /* Step 2: Create the prototype cell specified in 'cellfile', using readcell.
     This should set up the apropriate synchans in specified compartments,
     with a spikegen element "spike" attached to the soma.  This will be
     done in /library, where it will be available to be copied into a network

     In this case there are two types of cells "Ex_cell" and "Inh_cell".
  */

  readcell {Ex_cellfile} /library/{Ex_cell_name}
  readcell {Inh_cellfile} /library/{Inh_cell_name}

  // In this case, use different values from the defaults in 'cellfile'
  setfield /library/{Ex_cell_name}/{Ex_ex_synpath} gmax {Ex_ex_gmax}
  setfield /library/{Ex_cell_name}/{Ex_inh_synpath} gmax {Ex_inh_gmax}
  setfield /library/{Ex_cell_name}/{Ex_drive_synpath} gmax {Ex_ex_gmax}
  setfield /library/{Ex_cell_name}/soma/spike thresh 0 abs_refract 0.002 \
	output_amp 1
  // Note: the Ex-cell has wider and slower spikes, so use larger abs_refract

  setfield /library/{Inh_cell_name}/{Inh_ex_synpath} gmax {Inh_ex_gmax}
  setfield /library/{Inh_cell_name}/{Inh_inh_synpath} gmax {Inh_inh_gmax}
  setfield /library/{Inh_cell_name}/{Inh_drive_synpath} gmax {Inh_ex_gmax}
  setfield /library/{Inh_cell_name}/soma/spike thresh 0  abs_refract 0.001 \
	 output_amp 1
end

/***** functions to set up the network *****/

function make_network
  /* Step 3 - make a 2D array of cells with copies of /library/cell */
  // usage: createmap source dest Nx Ny -delta dx dy [-origin x y]

  /* There will be NX cells along the x-direction, separated by SEP_X,
     and  NY cells along the y-direction, separated by SEP_Y.
     The default origin is (0, 0).  This will be the coordinates of cell[0].
     The last cell, cell[{NX*NY-1}], will be at (NX*SEP_X -1, NY*SEP_Y-1).
  */
  createmap /library/{Ex_cell_name} /Ex_layer {Ex_NX} {Ex_NY} \
      -delta {Ex_SEP_X} {Ex_SEP_Y}

  // Displace the /Inh_layer origin to be in between Ex_cells
  createmap /library/{Inh_cell_name} /Inh_layer {Inh_NX} {Inh_NY} \
      -delta {Inh_SEP_X} {Inh_SEP_Y} -origin {Ex_SEP_X/2}  {Ex_SEP_Y/2}
end // function make_network

function connect_cells
  /* Step 4: Now connect them up with planarconnect.  Usage:
   * planarconnect source-path destination-path
   *               [-relative]
   *               [-sourcemask {box,ellipse} xmin ymin xmax ymax]
   *               [-sourcehole {box,ellipse} xmin ymin xmax ymax]
   *               [-destmask   {box,ellipse} xmin ymin xmax ymax]
   *               [-desthole   {box,ellipse} xmin ymin xmax ymax]
   *               [-probability p]
   */

  /* Connect each source spike generator to target synchans within the
     specified range.  Set the ellipse axes or box size just higher than the
     cell spacing, to be sure cells are included.  To connect to nearest
     neighbors and the 4 diagonal neighbors, use a box:
       -destmask box {-SEP_X*1.01} {-SEP_Y*1.01} {SEP_X*1.01} {SEP_Y*1.01}
     For all-to-all connections with a 10% probability, set both the sourcemask
     and the destmask to have a range much greater than NX*SEP_X using options
       -destmask box -1 -1  1  1 \
       -probability 0.1
     Set desthole to exclude the source cell, to prevent self-connections.

     In an earlier version, the destination was divided into three rings, with
     decreasing connection probabilities.  The same function is used
     for both Ex_cells and Inh_cells.

     In this version, with the flag 'use_prob_decay = 1', the  connection
     probability is weighted with a probability exp(-d*d/(sigma*sigma))
     where r is the radial distance between source and destination
     in the x-y plane.
  */

  /*
  Typical values from experiment are:

  float Ex2Ex_prob = 0.1
  float Ex2Inh_prob = 0.3
  float Inh2Ex_prob = 0.4
  float Inh2Inh_prob = 0.4  // (a guess, data not available)
  */

  /* Default values used in this simulation */
  float Ex2Ex_prob = 0.15
  float Ex2Inh_prob = 0.45
  float Inh2Ex_prob = 0.6
  float Inh2Inh_prob = 0.6  // (a guess, data not available)

  // distance at which number of targets cells becomes very small
  float pyr_range = 25*Ex_SEP_X 
  float bask_range = 25*Ex_SEP_X

  // Ex_layer cells connect to excitatory synchans

  if (use_prob_decay)
    float Ex_sigma = 10.0*Ex_SEP_X // values from K Yaun SfN 2008 poster fit
    float Inh_sigma = 10.0*Ex_SEP_X

    planarconnect_probdecay /Ex_layer/{Ex_cell_name} "soma/spike" {Ex_NX*Ex_NY} \
      /Ex_layer/{Ex_cell_name} {Ex_ex_synpath} {Ex_NX*Ex_NY} \
      {0.5*Ex_SEP_X} {pyr_range} {Ex2Ex_prob} {Ex_sigma}

    // Inh_ex connections don't need an intial desthole, so rmin = 0.0
    planarconnect_probdecay /Ex_layer/{Ex_cell_name} "soma/spike" {Ex_NX*Ex_NY} \
      /Inh_layer/{Inh_cell_name} {Inh_ex_synpath} {Inh_NX*Inh_NY} \
      0.0 {pyr_range} {Ex2Inh_prob} {Ex_sigma}

    planarconnect_probdecay /Inh_layer/{Inh_cell_name} "soma/spike" \
      {Inh_NX*Inh_NY} /Ex_layer/{Ex_cell_name} {Ex_inh_synpath} {Ex_NX*Ex_NY} \
      0.0 {bask_range} {Inh2Ex_prob} {Inh_sigma}

    planarconnect_probdecay /Inh_layer/{Inh_cell_name} "soma/spike" {Inh_NX*Inh_NY} \
      /Inh_layer/{Inh_cell_name} {Inh_inh_synpath} {Inh_NX*Inh_NY} \
      {Inh_SEP_X*0.5} {bask_range} {Inh2Inh_prob} {Inh_sigma}

  else // use a fixed range and probablity of connections

    volumeconnect /Ex_layer/{Ex_cell_name}[]/soma/spike \
    /Ex_layer/{Ex_cell_name}[]/{Ex_ex_synpath} \
    -relative \ // Destination coordinates are measured relative to source
    -sourcemask box -1 -1 -1 1 1 1 \ // Larger than source area ==> all cells
    -desthole box {-Ex_SEP_X*0.5} {-Ex_SEP_Y*0.5} {-Ex_SEP_Z*0.5} \
       {Ex_SEP_X*0.5} {Ex_SEP_Y*0.5} {Ex_SEP_Z*0.5} \
    -destmask ellipsoid 0 0 0 {pyr_range} {pyr_range} {Ex_SEP_Z*0.5}  \
    -probability {Ex2Ex_prob}

    // Inh_ex connections don't need an intial desthole
    volumeconnect /Ex_layer/{Ex_cell_name}[]/soma/spike \
    /Inh_layer/{Inh_cell_name}[]/{Inh_ex_synpath} \
    -relative \	    // Destination coordinates are measured relative to source
    -sourcemask box -1 -1 -1  1 1  1 \   // Larger than source area ==> all cells
    -destmask ellipsoid 0 0 0 {pyr_range} {pyr_range}  {Ex_SEP_Z*0.5} \
    -probability {Ex2Inh_prob}

    // Inh_layer cells connect to inhibitory synchans
    volumeconnect /Inh_layer/{Inh_cell_name}[]/soma/spike \
    /Inh_layer/{Inh_cell_name}[]/{Inh_inh_synpath} \
    -relative \	    // Destination coordinates are measured relative to source
    -sourcemask box -1 -1 -1  1 1  1 \   // Larger than source area ==> all cells
    -destmask ellipsoid 0 0 0 {bask_range} {bask_range}  {Inh_SEP_Z*0.5}  \
    -desthole box {-Inh_SEP_X*0.5} {-Inh_SEP_Y*0.5} {-Inh_SEP_Z*0.5} \
       {Inh_SEP_X*0.5} {Inh_SEP_Y*0.5} {Inh_SEP_Z*0.5} \
    -probability {Inh2Inh_prob}

    // Inh_layer cells connect to excitatory synchans
    // Ex_inh connections don't need an intial desthole
    volumeconnect /Inh_layer/{Inh_cell_name}[]/soma/spike \
    /Ex_layer/{Ex_cell_name}[]/{Ex_inh_synpath} \ {Inh_SEP_Z*0.5}
    -relative \	    // Destination coordinates are measured relative to source
    -sourcemask box -1 -1 -1  1 1  1 \   // Larger than source area ==> all cells
    -destmask ellipsoid 0 0 0  {bask_range} {bask_range}  {Inh_SEP_Z*0.5} \
    -probability {InheEx_prob}
  end // if-else

  /* Step 5: Set the axonal propagation delay and weight fields of the target
     synchan synapses for all spikegens.  To scale the delays according to
     distance instead of using a fixed delay, use
       planardelay /network/cell[]/soma/spike -radial {cond_vel}
     and change dialogs in graphics.g to set cond_vel.  This would be
     appropriate when connections are made to more distant cells.  Other
     options of planardelay and planarweight allow some randomized variations
     in the delay and weight.

     This is now done in the main simulation section, following connect_cells.
  */
end // function connect_cells

// Utility functions to calculate statistics
function print_avg_syn_number
    int n
    int num_Ex_ex = 0
    int num_Ex_inh = 0
    for (n=0; n < Ex_NX*Ex_NY; n=n+1)
        num_Ex_ex = num_Ex_ex + {getsyncount \
            /Ex_layer/{Ex_cell_name}[{n}]/{Ex_ex_synpath}}
        num_Ex_inh = num_Ex_inh + {getsyncount \
            /Ex_layer/{Ex_cell_name}[{n}]/{Ex_inh_synpath}}
    end
    num_Ex_ex = num_Ex_ex/(Ex_NX*Ex_NY)
    num_Ex_inh = num_Ex_inh/(Ex_NX*Ex_NY)
    int num_Inh_ex = 0
    int num_Inh_inh = 0
    for (n=0; n < Inh_NX*Inh_NY; n=n+1)
        num_Inh_ex = num_Inh_ex + {getsyncount \
            /Inh_layer/{Inh_cell_name}[{n}]/{Inh_ex_synpath}}
        num_Inh_inh = num_Inh_inh + {getsyncount \
            /Inh_layer/{Inh_cell_name}[{n}]/{Inh_inh_synpath}}
    end
    num_Inh_ex = num_Inh_ex/(Inh_NX*Inh_NY)
    num_Inh_inh = num_Inh_inh/(Inh_NX*Inh_NY)
    echo "Average number of Ex_ex synapses per cell: " {num_Ex_ex}
    echo "Average number of Ex_inh synapses per cell: " {num_Ex_inh}
    echo "Average number of Inh_ex synapses per cell: " {num_Inh_ex}
    echo "Average number of Inh_inh synapses per cell: " {num_Inh_inh}
end // print_avg_syn_number

//===============================
//    Main simulation section
//===============================

setclock  0  {dt}		// set the simulation clock

/* Including the protodefs file creates prototypes of the channels,
   and other cellular components under the neutral element '/library'.
   Calling the function 'make_prototypes', defined earlier in this
   script, uses these and the cell reader to add the cells.
*/
include protodefs.g
// Now /library contains prototype channels, compartments, spikegen

make_prototypes // This adds the prototype cells to /library

make_network // Copy cells into network layers

// make_network should do some of this, but set all synchan gmax values
set_all_gmax

/* synchan tau values should not be changed after hsolve SETUP */
// Change the synchan tau1 and tau2 from the values used in protodefs
set_all_taus
// Give a range of the inhibitory tau2 if tau2_inh_spreadfactor != 0.0
set_inh_tau2 {tau2_inh}

// set the random background excitation frequency
set_frequency {frequency}


/* Setting up hsolve for a network requires setting up a solver for
   one cell of each type in the network and then duplicating the
   solvers.  The procedure is described in the advanced tutorial
   'Simulations with GENESIS using hsolve by Hugo Cornelis' from
   genesis-sim.org/GENESIS/UGTD/Tutorials/advanced-tutorials
*/
if(hflag)
    pushe /Ex_layer/pyr_4[0]
    create hsolve solver
    setmethod . 11 // Use Crank-Nicholson
    setfield solver chanmode {hsolve_chanmode} path "../[][TYPE=compartment]"
    call solver SETUP
    int i
    for (i = 1 ; i < {Ex_NX*Ex_NY} ; i = i + 1)
        call solver DUPLICATE \
            /Ex_layer/pyr_4[{i}]/solver  ../##[][TYPE=compartment]
        setfield /Ex_layer/pyr_4[{i}]/solver \
            x {getfield /Ex_layer/pyr_4[{i}]/soma x} \
            y {getfield /Ex_layer/pyr_4[{i}]/soma y} \
            z {getfield /Ex_layer/pyr_4[{i}]/soma z}
    end
    pope
    pushe /Inh_layer/bask_4[0]
    create hsolve solver
    setmethod . 11 // see if this works
    setfield solver chanmode  {hsolve_chanmode} path "../[][TYPE=compartment]"
    call solver SETUP
    int i
    for (i = 1 ; i < {Inh_NX*Inh_NY} ; i = i + 1)
  	call solver DUPLICATE \
            /Inh_layer/bask_4[{i}]/solver	 ../##[][TYPE=compartment]
    setfield /Inh_layer/bask_4[{i}]/solver \
        x {getfield /Inh_layer/bask_4[{i}]/soma x} \
        y {getfield /Inh_layer/bask_4[{i}]/soma y} \
        z {getfield /Inh_layer/bask_4[{i}]/soma z}
    end
    pope
end

// Now connect them
if (connect_network)
    if (debug)
        echo "Starting connection set up: " {getdate}
    end
    connect_cells // connect up the cells in the network layers
    if (debug)
        echo "Finished connection set up: " {getdate}
    end
end

// set weights and delays
set_weights {syn_weight}

/* If the delay is zero, set it as the fixed delay, else use the conduction
  velocity and calculate delays based on radial distance to target
*/
if (prop_delay == 0.0)
    planardelay /Ex_layer/{Ex_cell_name}[]/soma/spike -fixed {prop_delay}
    planardelay /Inh_layer/{Inh_cell_name}[]/soma/spike -fixed {prop_delay}
else
    planardelay /Ex_layer/{Ex_cell_name}[]/soma/spike -radial {1/prop_delay}
    planardelay /Inh_layer/{Inh_cell_name}[]/soma/spike -radial {1/prop_delay}
end

/* Set up the inputs to the network.  Depending on
   the type of input to be used, include the appropriate
   file for defining the functions make_inputs and connect_inputs
*/
if (input_type == "pulsed_spiketrain")
    echo "Using simple pulsed spiketrain input"
    include basic_inputs.g
else
   echo "No input_type was specified!"
   quit
end

make_inputs 220.0 // Create array of network inputs starting at freq f0
connect_inputs // Connect the inputs to the network
setall_driveweights {drive_weight} // Initialize the weights of input drive

// Create disk_out elements /output/{net_efile}, {net_ifile}, {net_EPSC_file}
do_network_out
// if (calc_EPSCsum), set up the calculator, messages, and file for summed EPSCs
do_EPSCsum_out

// check
// reset

if (debug)
    echo "Network of "{Ex_NX}" by "{Ex_NY}" excitatory cells with separations" \
        {Ex_SEP_X}" by "{Ex_SEP_Y}
    echo "and "{Inh_NX}" by "{Inh_NY}" inhibitory cells with separations" \
         {Inh_SEP_X}" by "{Inh_SEP_Y}
    echo "Random number generator seed initialized to: " {seed}
    echo
    print_avg_syn_number
end

if(batch)
    // set up the inputs for the default simulation with two inputs:
    // Row 12 -  220Hz, Row 36 - 440 Hz
    set_frequency 0.0 // No background excitation
    setfield /MGBv[1]/spikepulse level1 1.0 
    setfield /MGBv[1]/spikepulse/spike abs_refract {1.0/220.0}
    setfield /MGBv[2]/spikepulse level1 1.0
    setfield /MGBv[2]/spikepulse/spike  abs_refract {1.0/440.0}
    reset
    reset
    step_tmax
end
