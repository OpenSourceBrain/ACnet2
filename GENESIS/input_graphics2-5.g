/*======================================================================
    A GENESIS GUI for providing inputs to an auditory cortex model
  ======================================================================*/

//===============================
//      Function Definitions
//===============================

// Display the parameters for the specified input
function show_params(input_num)
    str control_form = "/input_control"
    int input_num, row_num
    setfield {control_form}/input_num value {input_num}
    float frequency, delay, width, interval
    str pulse_src = {input_source} @ "[" @ {input_num} @ "]" @ "/spikepulse"
    str spike_out = {input_source} @ "[" @ {input_num} @ "]" @ "/soma/spike"
     // this assumes set_pulse_params has been called so that abs_refract != 0
    row_num = {getfield {{input_source} @ "[" @ {input_num} @ "]"} input_row}
    setfield {control_form}/targ_row value {row_num}
    frequency = {getfield {{input_source} @ "[" @ {input_num} @ "]"} input_freq}
    setfield {control_form}/spikefreq value {frequency}
    delay = {getfield {pulse_src} delay1 }
    float width = {getfield {pulse_src} width1}
    interval = {getfield {pulse_src} delay1} \
        + {getfield {pulse_src} delay2}
    setfield {control_form}/pulse_delay value {delay}
    setfield {control_form}/pulse_width value {width}
    setfield {control_form}/interval value {interval}

    // Set the spiketoggle state
    int toggle_state = 0
    if ({getfield {pulse_src} level1} > 0.5)
        toggle_state = 1
    end
    setfield {control_form}/spiketoggle state {toggle_state}

    // set the Spike train weight dialog from the output_weight field
    setfield {control_form}/st_weight value \ 
       {getfield {{input_source} @ "[" @ {input_num} @ "]"} output_weight }
    //  This is an ugly hack to make sure that the main form gets input_num
    //  It assumes that there is an xdialog control/show_params 
    setfield /control/show_params value {input_num}
    xshow {control_form}
end

function decr_input_num
    str form = "/input_control"
    int input_num
    input_num = {getfield {form}/input_num value}
    if ({input_num} > 1)
        input_num = input_num - 1
    end
    show_params {input_num}
end

function incr_input_num
    str form = "/input_control"
    int input_num
    input_num = {getfield {form}/input_num value}
    if ({input_num} < {Ninputs})
        input_num = input_num + 1
    end
    show_params {input_num}
end


function set_spike_pulse
   str form = "/input_control"
   int input_num
   input_num = {getfield {form}/input_num value}
   float frequency, delay, width, interval
   frequency = {getfield {form}/spikefreq value}
   delay = {getfield {form}/pulse_delay value}
   width = {getfield {form}/pulse_width value}
   interval = {getfield {form}/interval value}
   set_pulse_params {input_num} {frequency} {delay} {width} {interval}
   echo "Spike frequency = "{frequency}
   echo "Pulse delay = "{getfield {form}/pulse_delay value}" sec"
   echo "Pulse width = "{getfield {form}/pulse_width value}" sec"
   echo "Pulse interval = "{getfield {form}/interval value}" sec"
end

function spike_toggle // toggles spike train ON/OFF for given input
    str form = "/input_control"
    int input_num
    input_num = {getfield {form}/input_num value}
    if ({getfield {form}/spiketoggle state} == 1)
        setfield {input_source}[{input_num}]/spikepulse level1 1.0  // ON
    else
        setfield {input_source}[{input_num}]/spikepulse level1 0.0  // OFF
    end
end

function set_input_weight
   str form = "/input_control"
   int input_num
   input_num = {getfield {form}/input_num value}
   float weight
   weight = {getfield {form}/st_weight value}
   set_spiketrain_weight {input_num} {weight}
end

function set_input_delays_from_GUI
    str form = "/input_control"
    // Set the global values from the values in the form
    input_delay = {getfield {form}/input_delay value}
    input_jitter = {getfield {form}/input_jitter value}
    // check range of jitter value
    if ((input_jitter < 0.0) || (input_jitter > 1.0))
        echo "jitter must be >= 0, and <= 1.0"
        input_jitter = 0.0
        setfield {form}/input_jitter value {input_jitter}
    end
    set_input_delays {input_delay} {input_jitter}
end
     
//==========================================================
//    Functions to create the Graphical User Interface
//==========================================================

function make_input_control
    int control_height = 520
    create xform /input_control [0,{35 + control_height},270,345]
    pushe /input_control
    create xlabel spikeparms -label "Parameters for inputs 1 - "{Ninputs}

    create xbutton less -label " < " -wgeom 20%  -script decr_input_num
    create xdialog input_num -xgeom 0:less -ygeom 0:spikeparms -wgeom 60% \
        -label "Input:" -value 1 -script "show_params <v>"
    create xbutton more -label " > " -wgeom 20% -xgeom 0:input_num \
        -ygeom 0:spikeparms -script incr_input_num
    create xtoggle spiketoggle -label "" -script spike_toggle
    setfield spiketoggle offlabel "Spike Train OFF"  state 0
    setfield spiketoggle onlabel "Spike Train ON"
    spike_toggle     // initialize
    create xdialog targ_row -label "Target Row" -value 0
    create xdialog st_weight -label "Spike train weight" \
        -value 1.0  -script "set_input_weight"
    create xdialog spikefreq -label "Input freq" -value {spikefreq} \
        -script "set_spike_pulse"
    create xdialog pulse_delay -label "Delay (sec)" \
         -value {pulse_delay}   -script "set_spike_pulse"
    create xdialog pulse_width -label "Width (sec)" \
        -value {pulse_width}  -script "set_spike_pulse"
    create xdialog interval -label "Interval (sec)" -value {pulse_interval} \
        -script "set_spike_pulse"
    // The delay and jitter are set globally for all MGBv connections
    create xdialog input_delay -label "Input delay" -value {input_delay} \
        -script "set_input_delays_from_GUI"
    create xdialog input_jitter -label "Input jitter" -value {input_jitter} \
        -script "set_input_delays_from_GUI"

    create xbutton DISMISS -script "xhide /input_control"
    pope
    // Initialize values for input 1
    show_params 1
    xshow /input_control
end

function make_MGBv_Vmgraph
    str form = "/MGBv_Vm"
    float vmin = -0.075
    float vmax = 0.125
    create xform {form} [1048,0,400,250]
    create xgraph {form}/voltage -hgeom 100% \
        -title "MGBv_cell Membrane Potential" -bg white 
    setfield ^ XUnits sec YUnits V
    setfield ^ xmax {tmax} ymin {vmin} ymax {vmax}
    makegraphscale {form}/voltage
    xshow {form}
end
