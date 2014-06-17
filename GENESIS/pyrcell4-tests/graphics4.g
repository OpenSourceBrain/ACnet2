/*======================================================================
    A GENESIS GUI for cell models with a  control panel for
    providing inputs, and  a graph with axis scaling
  ======================================================================*/

//===============================
//      Function Definitions
//===============================

function overlaytoggle(widget)
    str widget
    setfield /##[TYPE=xgraph] overlay {getfield {widget} state}
end

/*  Use these versions with a pulsegen */

function inj_toggle // toggles current injection ON/OFF
    if ({getfield /control/injtoggle state} == 1)
        setfield /injectpulse level1 1.0        // ON
    else
        setfield /injectpulse level1 0.0        // OFF
    end
end

function set_injection
   str dialog = "/control"
   float inj_nA =  {getfield {dialog}/inject value}  // in nA
   set_inj_timing {getfield {dialog}/injectdelay value}  \
       {getfield {dialog}/width value} {getfield {dialog}/interval value}
   // inject is in nA
   injcurrent = inj_nA*1e-9  // set the global injection current variable
   setfield /injectpulse/injcurr gain {injcurrent}
   echo "Injection current = "{getfield {dialog}/inject value} "nA"
   echo "Injection pulse delay = "{getfield {dialog}/injectdelay value}
   echo "Injection pulse width = "{getfield {dialog}/width value}
   echo "Injection pulse interval = "{getfield {dialog}/interval value}
end

/* Alternate versions of these functions without pulsegen


function inj_toggle // toggles current injection ON/OFF
    if ({getfield /control/injtoggle state} == 1)
        setfield {injectpath} inject {injcurrent} // ON
    else
        setfield {injectpath} inject 0.0          // OFF
    end
end

function set_injection
    str dialog = "/control"
    float inj_nA =  {getfield {dialog}/inject value}  // in nA
    // inject is in nA
    injcurrent = inj_nA*1e-9  // set the global injection current variable
    setfield {injectpath} inject {injcurrent}
end

*/

function change_stepsize(dialog)
   str dialog
   dt =  {getfield {dialog} value}
   setclock 0 {dt}
   echo "Changing step size to "{dt}
end

function change_runtime(dialog)
   str dialog
   tmax =  {getfield {dialog} value}
   // set xmax for any graphs
   setfield /data/voltage xmax {tmax}
end

function set_gmax(value)
   float value
   gmax = {value}*1e-9
   setfield {synpath} gmax {gmax}
end

function set_bg_gmax(value)
   float value
   bg_gmax = {value}*1e-9
   setfield {bg_synpath} gmax {bg_gmax}
end

/*  A subset of the functions defined in genesis/startup/xtools.g
    These are used to provide a "scale" button to graphs.
    "makegraphscale path_to_graph" creates the button and the popup
     menu to change the graph scale.
*/

function setgraphscale(graph)
    str graph
    str form = graph @ "_scaleform"
    str xmin = {getfield {form}/xmin value}
    str xmax = {getfield {form}/xmax value}
    str ymin = {getfield {form}/ymin value}
    str ymax = {getfield {form}/ymax value}
    setfield {graph} xmin {xmin} xmax {xmax} ymin {ymin} ymax {ymax}
    xhide {form}
end

function showgraphscale(form)
    str form
    str x, y
    // find the parent form
    str parent = {el {form}/..}
    while (!{isa xform {parent}})
        parent = {el {parent}/..}
    end
    x = {getfield {parent} xgeom}
    y = {getfield {parent} ygeom}
    setfield {form} xgeom {x} ygeom {y}
    xshow {form}
end

function makegraphscale(graph)
    if ({argc} < 1)
        echo usage: makegraphscale graph
        return
    end
    str graph
    str graphName = {getpath {graph} -tail}
    float x, y
    str form = graph @ "_scaleform"
    str parent = {el {graph}/..}
    while (!{isa xform {parent}})
        parent = {el {parent}/..}
    end

    x = {getfield {graph} x}
    y = {getfield {graph} y}

    create xbutton {graph}_scalebutton  \
        [{getfield {graph} xgeom},{getfield {graph} ygeom},50,25] \
           -title scale -script "showgraphscale "{form}
    create xform {form} [{x},{y},180,170] -nolabel

    disable {form}
    pushe {form}
    create xbutton DONE [10,5,55,25] -script "setgraphscale "{graph}
    create xbutton CANCEL [70,5,55,25] -script "xhide "{form}
    create xdialog xmin [10,35,160,25] -value {getfield {graph} xmin}
    create xdialog xmax [10,65,160,25] -value {getfield {graph} xmax}
    create xdialog ymin [10,95,160,25] -value {getfield {graph} ymin}
    create xdialog ymax [10,125,160,25] -value {getfield {graph} ymax}
    pope
end

/* Add some interesting colors to any widgets that have been created */
function colorize
    setfield /##[ISA=xlabel] fg white bg blue3
    setfield /##[ISA=xbutton] offbg rosybrown1 onbg rosybrown1
    setfield /##[ISA=xtoggle] onfg red offbg cadetblue1 onbg cadetblue1
    setfield /##[ISA=xdialog] bg palegoldenrod
    setfield /##[ISA=xgraph] bg ivory
end

//==========================================================
//    Functions to create the Graphical User Interface
//==========================================================

function make_control
  int control_height = 310
  create xform /control [10,50,250,{control_height}]
  create xlabel /control/label -hgeom 25 -bg cyan -label "CONTROL PANEL"
  create xbutton /control/RESET -wgeom 33%       -script reset
  create xbutton /control/RUN  -xgeom 0:RESET -ygeom 0:label -wgeom 33% \
         -script step_tmax
  create xbutton /control/QUIT -xgeom 0:RUN -ygeom 0:label -wgeom 34% \
        -script do_quit

  create xdialog /control/stepsize -title "dt (sec)" -value {dt} \
                -script "change_stepsize <widget>"
  create xdialog /control/runtime -title "runtime (sec)" -value {tmax} \
		-script "change_runtime <widget>"
  create xtoggle /control/overlay   -script "overlaytoggle <widget>"
  setfield /control/overlay offlabel "Overlay OFF" onlabel "Overlay ON" state 0
  create xlabel /control/injlabel -label "Injection Parameters"
  create xtoggle /control/injtoggle -label "" -script inj_toggle
  setfield /control/injtoggle offlabel "Current Injection OFF"
  setfield /control/injtoggle onlabel "Current Injection ON" state 1
  inj_toggle     // initialize
  create xdialog /control/inject -label "Injection (nA)" \
    -value {injcurrent*1e9} -script "set_injection"
  create xdialog /control/injectdelay -label "Delay (sec)" \
         -value {injdelay}  -script "set_injection"
  create xdialog /control/width -label "Width (sec)" \
        -value {injwidth} -script "set_injection"
  create xdialog /control/interval -label "Interval (sec)" \
        -value {injinterval}  -script "set_injection"

  xshow /control

  // if synchanpath non-null
  if({synpath} != "")
    create xform /syninput [10,{75 + control_height},250,195]
    create xdialog /syninput/gmax -label "gmax (nS)" -value {gmax*1e9} \
        -script "set_gmax <v>"
    create xlabel /syninput/randact -label "Random background activation"
    create xdialog /syninput/randfreq -label "Frequency (Hz)" -value 0 \
        -script "set_frequency <v>"
    create xdialog /syninput/bg_gmax -label "bg gmax (nS)" -value {bg_gmax*1e9} \
        -script "set_bg_gmax <v>"
    create xtoggle /syninput/spiketrain_toggle \
	-script "setfield /spikes_on x <v>"
    setfield /syninput/spiketrain_toggle offlabel "Spike input OFF" \
        onlabel "Spike input ON" state 0
    create xdialog /syninput/spike_interval -label "Spike interval (sec)" \
        -value {spikeinterval} -script "setfield /spiketrain abs_refract <v>"
    xshow /syninput
  end
end

function make_Vmgraph
    float vmin = -0.100
    float vmax = 0.05
    create xform /data [265,50,700,350]
    create xlabel /data/label -hgeom 10% -label {graphlabel}
    create xgraph /data/voltage -hgeom 90% -title "Membrane Potential" -bg white
    setfield ^ XUnits sec YUnits Volts
    setfield ^ xmax {tmax} ymin {vmin} ymax {vmax}
    makegraphscale /data/voltage
    xshow /data
end

function make_concengraph
    create xform /concengraphs [265,430,700,350]
    pushe /concengraphs

    create xgraph Ca_concen -hgeom 100% -title "Ca concentration"
    setfield Ca_concen xmin 0 xmax {tmax} ymin 0 ymax 150
    setfield Ca_concen XUnits "sec" YUnits "Conc)"
    pope
    makegraphscale  /concengraphs/Ca_concen
    xshow /concengraphs
end

/* optional functions to create a cell display */
// Set the dimensions of the draw widget from the cell dimensions
function set_drawrange
    str i
    float x,y,z
    float xmin = -1e-6, xmax = 1e-6, ymin = -1e-6, ymax = 1e-6
    float zmin = -1e-6, zmax = 1e-6
    foreach i ( {el {cellpath}/#[]} )
        x = {getfield {i} x}; y = {getfield {i} y}; z =  {getfield {i} z}
        xmin = {min {xmin} {x}}; xmax = {max {xmax} {x}}
        // hack to give x and y the same range
        xmin = {min {xmin} {y}}; xmax = {max {xmax} {y}}
        zmin = {min {zmin} {z}}; zmax = {max {zmax} {z}}
    end
    ymin = xmin; ymax = xmax
    setfield /cellform/draw xmin {xmin*1.1} xmax {xmax*1.1} \
        ymin {ymin*1.1} ymax {ymax*1.1} zmin {zmin*1.1} zmax {zmax*1.1}
end

function make_xcell
    int xpos = 10; int ypos = 425
    create xform /cellform [{xpos},{ypos},475,400]

    create xlabel /cellform/label [0,0,100%,25] -bg green \
      -label "Use arrows to pan; < and > to zoom; x, y, z, o, p for transform"
    create xdraw /cellform/draw [0,25,100%,375] -bg white -transform o
    create xcell /cellform/draw/cell
    setfield /cellform/draw/cell colmin -0.1 colmax 0.1 diarange -30 \
        soma -2 field Vm  script "echo <w> <v>"
    // initial guess at cell dimensions to set the scale
    setfield /cellform/draw xmin -15e-4 xmax 15e-4 ymin -15e-4 ymax 15e-4 \
        zmin -25e-4 zmax 15e-4
    // set viewpoint for ortho projection
    setfield /cellform/draw vx 10 vy -15 vz 7
    if (symcomps == 0)
        setfield /cellform/draw/cell path {cellpath}/##[TYPE=compartment]
    else
        setfield /cellform/draw/cell path {cellpath}/##[TYPE=symcompartment]
    end
    set_drawrange
    xcolorscale hot
    xshow /cellform
end
