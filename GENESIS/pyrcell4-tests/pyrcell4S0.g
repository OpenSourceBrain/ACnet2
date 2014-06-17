//genesis  -  pyr4cell - derived from simplecell2.g
/*======================================================================
  A sample script to create a neuron from a specified cell parameter file,
  with channels taken from the prototypes created by the file protodefs.g
  When used with the GUI functions defined in graphics.g, it allows a
  variety of pulsed current injection and synaptic inputs to be applied.
  ======================================================================*/

/* Customize these strings and parameters to modify this simulation for
   another cell.
*/

str cellfile = "pyr_4_sym.p"
str cellpath = "/cell"
// Define the places for current injection and synaptic input
str injectpath = {cellpath} @ "/soma"  // Use '@' to concatenate strings
// For no synaptic input, set
// str synpath = ""
str synpath = {cellpath} @ "/apical1/AMPA_pyr"
str bg_synpath = {cellpath} @ "/basal1/AMPA_pyr"

/* Some Booleans indicating the type of calculations or output */
int batch = 0        // if (batch) then run a default simulation
int graphics = 1     // display control panel, graphs
int file_out = 1     // write output to a file
int hflag = 1    // use hsolve if hflag = 1
int chanmode = 0 // hsolve mode for GENESIS 2

int symcomps = 1  // If zero assume asymmetric compartments

str outfile = "pyrcell4S0_Vm.txt"

float tmax = 1.0		// simulation time in sec
float dt = 0.00001		// simulation time step in sec
float out_dt = 0.0001		// output step = 0.1 msec
float injdelay = 0.1

injdelay = injdelay - dt

// for constant injection, use injwidth = tmax, injdelay = 0
float injwidth = 0.5 // 10 msec
float injinterval = 1
float injcurrent = 0.6e-9

// If there is synaptic input, define gmax for the target synchan
float gmax  // value will be obtained from cell created by readcell
float bg_gmax = 25e-9 // for background synaptic input
float bg_freq = 0.1
float spikeinterval = 0.01 // Default interval in applied spike train

// Label for the graph
str graphlabel = "layer 4 pyramidal cell: " @ {cellfile}

// Create a library of prototype elements to be used by the cell reader
include protodefs0.g

//===============================
//      Function Definitions
//===============================

function step_tmax
    // Add any other commands here that you want to execute for each run
    echo "START: "{getdate}
    step {tmax} -time
    echo "END: "{getdate}
end

function do_quit
    // Add any other commands here that you want to execute before quitting
    quit
end

function set_inj_timing(delay, width, interval)
    float delay, width, interval
    setfield /injectpulse level1 1 width1 {width} delay1 {delay}  \
        baselevel 0.0 trig_mode 0 delay2 {interval - delay} width2 0
    // free run mode with no second level2 pulse
end

function set_frequency(frequency) // Frequency of random background activation
    float frequency
    setfield {bg_synpath} frequency {frequency}
end


//===============================
//    Main simulation section
//===============================

setclock  0  {dt}		// set the simulation clock

// Use readcell read a cell parameter file and create a cell in "cellpath"
readcell {cellfile} {cellpath}

/* Create the output element */
if (file_out)
    create asc_file /output/plot_out
    setclock 1 {out_dt}
    useclock /output/plot_out 1
    addmsg {cellpath}/soma /output/plot_out SAVE Vm
    setfield /output/plot_out filename {outfile}
end

// Set up the circuitry to provide injection pulses to the cell

function make_inject_pulse
    create pulsegen /injectpulse // Make a periodic injection current step
    set_inj_timing {injdelay} {injwidth} {injinterval}
    // set the amplitude (current) with the gain of a differential amplifier
    create diffamp /injectpulse/injcurr
    setfield /injectpulse/injcurr saturation 10000 gain {injcurrent}
    addmsg /injectpulse /injectpulse/injcurr PLUS output
    addmsg /injectpulse/injcurr {injectpath} INJECT output
end


/* Uncomment the function call below to use a pulsegen instead of a constant
   current source.  
*/

make_inject_pulse

// use this instead for a constant injection
// setfield {injectpath} inject {injcurrent}

// Set up circuitry for synaptic input if synapse exists
if({synpath} != "")
    gmax = {getfield {synpath} gmax}
    create neutral /spikes_on
    setfield /spikes_on x 0  // x field used as a toggle for spiketrain
    create spikegen /spiketrain
    setfield /spiketrain thresh 0.5 abs_refract {spikeinterval}
    addmsg /spikes_on /spiketrain INPUT x
    addmsg /spiketrain {synpath} SPIKE
end

// Include the functions used to build the GUI
if (graphics)
    include graphics4.g
    // make the control panel
    make_control
    // make the graph to display soma Vm and pass messages to the graph
    make_Vmgraph
    addmsg {cellpath}/soma /data/voltage PLOT Vm *volts *red

    make_concengraph
    addmsg {cellpath}/soma/Ca_conc /concengraphs/Ca_concen PLOT Ca *Ca *blue

    /* uncomment the two lines below to create a cell display (slower)  */
//    make_xcell // create and display the xcell
//    xcolorscale hot
    colorize    // function defined in graphics.g
end

set_frequency {bg_freq}
if (hflag)
    create hsolve /cell/solve
    if (symcomps == 0)
        setfield /cell/solve path "/cell/##[][TYPE=compartment]"
    else
        setfield /cell/solve path "/cell/##[][TYPE=symcompartment]"
    end
    setmethod 11
    setfield /cell/solve chanmode {chanmode}
    call /cell/solve SETUP
    reset
    echo "Using hsolve"
end
bg_freq = 0.0
set_frequency {bg_freq}

// check
reset

if (batch)
    // step 3000
    step_tmax
end
