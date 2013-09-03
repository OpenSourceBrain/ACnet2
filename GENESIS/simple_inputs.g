// simple_inputs.g - used by ACnet2-default.g and variants

str input_source = "/MGBv" // Name of the array of input elements
echo " input_source = "{input_source}

/* The following global variables are defined in the ACnet network script:

   int Ninputs // number of auditory inputs
   // approx 1 mm/octave - gives integer rows/octave
   float octave_distance = 0.96e-3
   float Ex_SEP_Y // separation between rows of Ex cells
   int input_spread // input to row_num +/- input_spread

   float spike_jitter = 0.0005 // 0.5 msec jitter in thalamic inputs
       or spike_jitter = 0.0

   float input_delay = 0.0	 // seconds
   float input_jitter = 0.0

   str input_type // "pulsed_spiketrain", "pulsed_randomspike", "MGBv"
   str input_pattern  // == "row", "line", "box"

   This version also needs Ex_SEP_X, Inh_SEP_X, Inh_SEP_Y
*/

int rows_per_octave = {round {octave_distance/Ex_SEP_Y}}

/* Input target rows are numbered 1 through Ninputs, and cell rows are
   numbered 0 through Ex_NY - 1.  The first and last one-third octave
   of the cell rows do not receive MGBv input, so the cell row number
   is offset from the input row by input_offset.
*/
int input_offset = {round {rows_per_octave/3.0}} - 1

// Pulsed spike generator -- for constant input, use pulsewidth >= tmax
float pulse_width =  0.05    // width of pulse
float pulse_delay = 0.05        // delay before start of pulse
float pulse_interval = 0.15 // time from start of pulse to next (period)
float spikefreq = 110          // just to initialize the dialog

/* Default input conduction delay and jitter - the many targets of a single
   MGBv cell will receive a spike with delay ranging from
   input_delay*(1 - input_jitter) to input_delay*(1 + input_jitter)

   This may be used to reduce the correlation between the inputs to the
   target rows.
   
*/

// These are set in the main script
// float input_delay = 0.0  // seconds
// float input_jitter = 0.0
// float spike_jitter = 0.0005 // 0.5 msec jitter in thalamic inputs

//===============================
//      Function Definitions
//===============================


/* Functions to create the MGBv cells that will provide the inputs 
   In this case the "cells" are spikegens controlled by pulsegens
*/

function make_MGBvcell(path)
    str path
    // The full MGBvcell model would have  MGBvcell parameters here
    // Pulsed spike generator -- for constant input, use pulsewidth >= tmax
    // these will get changed
    float pulse_width = {tmax}     // width of pulse
    float pulse_delay = 0          // delay before start of pulse
    float pulse_interval = {tmax}  // interval before next pulse
    float spikefreq = 110 // Hz.   // initial value of frequency

    // This parameter is used for the full MGBvcell model
    // float spike_weight = 8
    /* Create the basic cell as a container for the pulsegen and spikegen */
    create neutral {path}

    // add fields to keep the target row, frequency and weight
    addfield {path} input_row
    setfield {path} input_row 0 // just to initialize it
    addfield {path} dest_row
    setfield {path} dest_row 0 // just to initialize it
    addfield {path} input_freq
    setfield {path} input_freq {spikefreq}
    addfield {path} output_weight
    setfield {path} output_weight 1.0

    create pulsegen {path}/spikepulse // Make a periodic pulse to control spikes
    // make a spikegen to deliver the spikes
    create spikegen {path}/spikepulse/spike
    setfield {path}/spikepulse/spike thresh 0.5
    setfield {path}/spikepulse width1 {pulse_width} delay1 {pulse_delay}  \
          baselevel 0.0 trig_mode 0 delay2 {pulse_interval - pulse_delay} width2 0

    if (input_type == "pulsed_spiketrain")
        if (debug >= 1)
            echo "Using simple pulsed spiketrain input"
        end  
        // set the spikegen refractory period = 1/freq
        setfield {path}/spikepulse/spike abs_refract {1.0/spikefreq}
        addmsg {path}/spikepulse {path}/spikepulse/spike INPUT output
    elif (input_type == "pulsed_randomspike")
        if (debug >= 1)
            echo "Using pulsed random (Poisson) spike input"
        end  
        create randomspike {path}/randspike
        setfield {path}/spikepulse/spike abs_refract 0.0009 // 1100 Hz max
        // Intialize randomspike amplitude to zero
	setfield {path}/randspike min_amp 0.0 max_amp 0.0 \
            reset 1 reset_value 0  rate {spikefreq}
        // gate the randomspike by setting min and max to pulsegen output
        addmsg {path}/spikepulse {path}/randspike MINMAX output output
        // This will gate the state of the randomspike, but not prevent it
        // from registering events. The state should be sent to the spikegen
        addmsg {path}/randspike {path}/spikepulse/spike INPUT state
   else
      echo "No input_type was specified!"
      quit
    end
end // function make_MGBvcell

function set_input_freq(cell, input_freq)
    str cell; float freq, input_freq
    setfield {cell} input_freq {input_freq}
    freq = input_freq
    if ({input_freq} > 1000)
        freq = 1000
    end
    float abs_refract = 1e6 // A very low frequency
    if ({freq} > 1.0e-6)
       abs_refract = 1.0/freq
    end
    if (input_type == "pulsed_spiketrain")
        setfield {cell}/spikepulse/spike abs_refract {abs_refract}
    elif (input_type == "pulsed_randomspike")
        setfield {cell}/randspike rate {freq}
    else
      echo "No input_type was specified!"
      return
    end
end // set_input_freq(cell, freq)

// Set parameters for spike train pulses
function set_pulse_params(input_num, frequency, delay, width, interval)
    int input_num
    float frequency, delay, width, interval, abs_refract
    setfield {input_source}[{input_num}]/spikepulse width1 {width} delay1 \
        {delay} baselevel 0.0 trig_mode 0 delay2 {interval - delay} width2 0
    // free run mode with very long delay for 2nd pulse (non-repetitive)
    // level1 is set by GUI spiketoggle function, or by a batch mode command
    // set the abs_refract of the spikegen to spike every 1/frequency
    set_input_freq {input_source}[{input_num}] {frequency}
end

function set_spiketrain_weight(input_num, weight)
    int input_num
    float weight
    setfield {input_source}[{input_num}] output_weight {weight}
    // Now set the weights of all network cell targets (not Inh feedback)
    // The optional 2nd arg for target is useful here
    planarweight {input_source}[{input_num}]/spikepulse/spike  \
        /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} -fixed {weight}
    planarweight {input_source}[{input_num}]/spikepulse/spike  \
        /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} -fixed {weight}
end

function setall_driveweights(weight)
    int i
    float weight
    for (i=1; i <= {Ninputs}; i=i+1)
        set_spiketrain_weight {i} {weight}
    end
end

/* Set up the circuitry to provide spike trains to the network */
function make_input_source(input_num)
    int input_num
    float x0, y0, z0, y
    x0 = 0; y0 = input_offset*Ex_SEP_Y; z0 =0;
    make_MGBvcell {input_source}[{input_num}]
    // Set the separations of the vertical array of inputs to that of network
    y = y0 + input_num*Ex_SEP_Y
    setfield {input_source}[{input_num}] x {x0} y {y} z {z0}
    setfield {input_source}[{input_num}] dest_row {input_num + input_offset}
end // function make_input_source

/* make_inputs and connect_inputs are the two functions called by ACnet2
   to set up the inputs to the network
*/

// Make array of pulsed inputs ({input_source}[{input_num}]) and initialize
function make_inputs(f0)
    int i
    float f0, freq
    f0 = 110
    if ({argc} == 1)
        f0 = {argv 1}
    end
    for (i=1; i <= {Ninputs}; i=i+1)
        make_input_source {i}
        // This assignment can be changed as needed
        freq = f0*{pow 2.0 {1.0*(i-1)/rows_per_octave}}
        set_pulse_params {i} {freq} {pulse_delay} {pulse_width} {pulse_interval}
        if (debug > 1)
            echo "source "{i}"  freq = "{freq}
        end
    end
end // function make_inputs

function set_input_delays(delay, jitter_factor)
    // give a random delay unfiformly distributed between
    // delay*(1 - jitter_factor) and delay*(1 + jitter_factor)
    float delay, jitter_factor
    // be careful to do it for just the network targets  
    planardelay /MGBv[]/spikepulse/spike  \
        /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} \
        -fixed {delay} -uniform {jitter_factor}
    planardelay /MGBv[]/spikepulse/spike  \
        /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} \
        -fixed {delay} -uniform {jitter_factor}
end

// Asume that spike_jitter < 1.0/input_freq (e.g. 2 kHz for 0.5 msec jitter)
function add_spike_jitter
    int i
    float st
    for (i=1; i <= {Ninputs}; i=i+1)
	st = 1.0/{getfield {input_source}[{i}] input_freq}
	setrandfield  {input_source}[{i}]/spikepulse/spike abs_refract \
            -gaussian {st} {spike_jitter}
    end
end

function make_jitter_adder
    create script_out /jitter_adder
    enable /jitter_adder
    useclock /jitter_adder 2 // same as netview_dt
    setfield /jitter_adder command "add_spike_jitter"
end


/* --------------- Notes on function connect_inputs ------------------

  The default input_pattern = "row" makes connections to all cells on the
  specified row.  If input_spread > 0, connections with an exponentially
  decaying probablility will be made to adjacent rows +/- input_spread.

  The input pattern "box" is a specialized input that is applied to each
  cell in a box that is defined by the integer variables:

       int Ex_NX0_in   // lower left corner x index
       int Ex_NY0_in   // lower left corner y index
       int Ex_NXlen_in // width of the box
       int Ex_NYlen_in // height of the box

  and similar variables Inh_NX0_in, Inh_NY0_in, Inh_NXlen_in, Inh_NYlen_in
  for the network of inhibitory cells.  A "line" input is merely a box with
  a height (Ex_NYlen_in or Inh_NYlen_in) = 1.  It differs from a single row
  input because it excludes cells at the ends of the row.

*/

function connect_inputs
    /* For special cases "line" or "box", I want connections from the one
       input channel to go to all cells in a rectangular block defined by
       the values of Ex_NX0_in, Ex_NY0_in, etc. defined below.

       Note that the Inh cells are displaced from Ex by Ex_SEP_X/2,
       Ex_SEP_Y/2, with twice the spacing.

       The x coord of the Ex_cell apical1 compartment (Ex_drive_synpath)
       is displaced from the grid location by -125 um, as it is at the end
       of the oblique apical dendrite.  For the symmetric compartment version
       of the cell, it is at -75 um.

       For "row" input, all cells on the row will be targets, so
       apical1_x_offset is not needed.

       Also, note the that '-relative' option is not used here.

 */
    float apical1_x_offset = -125e-6
    float xmin, ymin, xmax, ymax

    if (input_pattern == "row")
      /* Use code from MGBv_input2-5.g to provide input_spread */
      int i, k
      float target_y, y, ymin, ymax, prob, max_prob
      // number of rows below and above "target row" of input spread
      int kspread = input_spread // defined in main ACnet script
      int kmax = kspread  // number of rows to go above target row
      int kmin = -1*kspread  // number of rows to go below target row
      /* Target rows are numbered 1 through Ninputs, and cell rows are
          numbered 0 through Ex_NY - 1.  The first and last one-third octave
          of the cell rows do not receive MGBv input, so the cell row number
          is offset from the input row by input_offset.

          In addition, the y coord of the Ex_cell apical1 compartment
	  (Ex_drive_synpath) is displaced from the grid location by 17 um
	  for the symmetric compartment version of the cell, but not for
	  the asymmetric.
      */
      float apical1_offset = 0.0
      max_prob = 1.1 // just to be sure that all target row cells get input
      
      // Below, the exponential decay of probability is set to give
      // prob(kmax) = exp(-2.0), to make it independent of Ex_SEP_Y
      float decay_rate
      if (kspread == 0)
          decay_rate = 1.0 // avoid a singularity if no spread
      else
        decay_rate = 2.0/kspread
      end
      for (i=1; i <= {Ninputs}; i=i+1) // loop over inputs
        target_y = {getfield {input_source}[{i}] dest_row} * Ex_SEP_Y
        if (debug > 2)
           echo "source "{i}"  target_y = "{target_y}
        end
        // Now set the input_row number for the source to target_y
        setfield {input_source}[{i}] input_row {i + input_offset}
        for (k = kmin; k <= kmax; k=k+1)  // loop over spread about target
          y = target_y + k*Ex_SEP_Y
          prob = max_prob*{exp {-1.0*decay_rate*{abs {k}}} }
          ymin = target_y + (k - 0.2)*Ex_SEP_Y
          ymax = target_y + (k + 0.2)*Ex_SEP_Y
          planarconnect {input_source}[{i}]/spikepulse/spike \
            /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} \
            -sourcemask box -1 -1 1 1 \
            -destmask box -1 {ymin + apical1_offset} 1 {ymax + apical1_offset} \
            -probability {prob}

          planarconnect {input_source}[{i}]/spikepulse/spike \
            /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} \
            -sourcemask box -1 -1 1 1 \ // be sure that I include the source
            -destmask box -1 {ymin + 0.5*Ex_SEP_Y} 1 {ymax + 0.5*Ex_SEP_Y} \
            -probability 0 // {0.65*prob}
        end // for k
      end // for i
    end

    if (input_pattern == "line" || input_pattern == "box")
      /* The more general version has a loop over inputs:
          for (i=1; i <= {Ninputs}; i=i+1)
         with an algorithm for determining input target row and another
         loop over the spread about the target:
            for (k = kmin; k <= kmax; k=k+1)
         Here there are just two specialized inputs that are applied to
         each cell within the two boxes that are defined below.
      */
      if (input_pattern == "box")
          // This version only has one input channel for all cells in the net
          Ninputs = 1
          int Ex_NX0_in = 4 // lower left corner x
          int Ex_NY0_in = 4 // lower left corner y
          int Ex_NXlen_in = 40 // width of the box
          int Ex_NYlen_in = 40 // height of the box

          int Inh_NX0_in = 2 // lower left corner x
          int Inh_NY0_in = 2 // lower left corner y
          int Inh_NXlen_in = 20 // width of the box
          int Inh_NYlen_in = 20 // height of the box
      elif (input_pattern == "line")
          int Ex_NX0_in = 4 // lower left corner
          int Ex_NY0_in = 18
          int Ex_NXlen_in = 40 // width of the box
          int Ex_NYlen_in = 1 // height of the box

          int Inh_NX0_in = 2 // lower left corner
          int Inh_NY0_in = 4
          int Inh_NXlen_in = 20 // width of the box
          int Inh_NYlen_in = 1 // height of the box
      end

      // Set the input_row number for the source
      setfield {input_source}[1] input_row {Ex_NY0_in}
      setfield {input_source}[1] dest_row {Ex_NY0_in}

      // give a +/- 0.1*Ex_SEP_Y range in y to deal with any roundoff
      xmin = Ex_SEP_X*Ex_NX0_in + apical1_x_offset
      xmax = Ex_SEP_X*(Ex_NX0_in +  Ex_NXlen_in) + apical1_x_offset
      ymin = Ex_SEP_Y*Ex_NY0_in - 0.1*Ex_SEP_Y
      ymax = Ex_SEP_Y*(Ex_NY0_in + Ex_NYlen_in -1) + 0.1*Ex_SEP_Y

      planarconnect {input_source}[1]/spikepulse/spike \
         /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} \
        -sourcemask box -1 -1 1 1 \
        -destmask box {xmin} {ymin} {xmax} {ymax} \
        -probability 1.0
      echo "MGBv[1] messages: " { getmsg MGBv[1]/spikepulse/spike -out -count}

        /* Uncomment to allow excitation of inhibitory cells also 

        xmin = Inh_SEP_X*Inh_NX0_in + 0.5*Ex_SEP_X
        ymin = Inh_SEP_Y*Inh_NY0_in + 0.5*Ex_SEP_Y - 0.1*Inh_SEP_Y
        xmax = Inh_SEP_X*(Inh_NX0_in + Inh_NXlen_in)+ 0.5*Ex_SEP_X
        ymax = Inh_SEP_Y*(Inh_NY0_in -1 + Inh_NYlen_in) + 0.5*Ex_SEP_Y + 0.1*Inh_SEP_Y

        planarconnect {input_source}[1]/spikepulse/spike \
          /Inh_layer/{Inh_cell_name}[]/{Inh_drive_synpath} \
          -sourcemask box -1 -1 1 1 \ // be sure that I include the source
          -destmask box {xmin} {ymin} {xmax} {ymax} \
          -probability 0.65
        */

      /* Now make a specific input pattern for the second input */
      if ((input_pattern == "line") && (Ninputs == 2))
          Ex_NX0_in = 4 // lower left corner
          Ex_NY0_in = 30
          ymin = Ex_SEP_Y*Ex_NY0_in - 0.1*Ex_SEP_Y
          ymax = Ex_SEP_Y*(Ex_NY0_in -1 + Ex_NYlen_in) + 0.1*Ex_SEP_Y

          // Set the input_row number for the source
          setfield {input_source}[2] input_row {Ex_NY0_in}
          setfield {input_source}[2] dest_row {Ex_NY0_in}
 
          planarconnect {input_source}[2]/spikepulse/spike \
           /Ex_layer/{Ex_cell_name}[]/{Ex_drive_synpath} \
           -sourcemask box -1 -1 1 1 \
           -destmask box {xmin} {ymin} {xmax} {ymax} \
           -probability 1.0
         echo "MGBv[2] messages: " { getmsg MGBv[2]/spikepulse/spike -out -count}
      /* put similar code for Inh here, if needed */
      end
    end // if (input_pattern == "line")

    // give a random delay unfiformly distributed between
    // delay*(1 - jitter_factor) and delay*(1 + jitter_factor)
    set_input_delays {input_delay} {input_jitter}

    if (({spike_jitter} > 0.0) && ({input_type} == "pulsed_spiketrain"))
        // Create a script_out to provide jitter in spike arrival time
        make_jitter_adder
    end

end // function connect_inputs
