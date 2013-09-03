/*======================================================================
  A GENESIS GUI for network models, with a  control panel, a graph with
  axis scaling, and a network view to visualize Vm in each cell
  ======================================================================*/

//=========================================
//      Function definitions used by GUI
//=========================================

function overlaytoggle(widget)
    str widget
    setfield /##[TYPE=xgraph] overlay {getfield {widget} state}
end

function change_stepsize(dialog)
   str dialog
   dt =  {getfield {dialog} value}
   setclock 0 {dt}
   echo "Changing step size to "{dt}
end


function change_runtime(dialog)
   str dialog
   tmax =  {getfield {dialog} value}
   setfield /data/voltage xmax {tmax}
   setfield /data/Inh_voltage xmax {tmax}
   setfield /MGBv_Vm/voltage xmax {tmax}    // from input_graphics.g
   setfield /EPSCform/EPSC_sum xmax {tmax}  // from ACnet2-3.g
end

function set_drive_weights(dialog)
   str dialog
   drive_weight = {getfield {dialog} value}
   setall_driveweights {drive_weight}
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

// function to return a color name from an index into the colorlist
// Usage example: str color = {colors 3}
function colors(col_num)
    int col_num
    str colorlist = "black blue cyan green magenta red orange"
    str color
    // convert col_num to range 1 though 7
    col_num = col_num - {trunc {col_num/7.0}}*7 + 1
    color = {getarg {arglist {colorlist}} -arg {col_num}}
    return {color}
end

/* Functions to drop and add plots of Vm for middle cell of input target row */

function add_Vmplot(row_num)
    int row_num, cell_num, dup_num, n, count
    str label, msglabel
    float offset
    float delta_y = 0.02 // vertical displacement of subsequent plots
    int first_row = 8 // the first row to be plotted has no vertical offset
    cell_num = row_num*Ex_NX  + {round {(Ex_NX -1)/2.0}}
    // generate PLOTSCALE options  {value} *{label} *{color} scale offset
    label = "row_" @ {row_num}
    offset = (row_num - first_row)*delta_y
    count = {getmsg /data/voltage -in -count}
    dup_num = -1  // default is that the message doesn't already exist
    for (n = 0; n < count; n = n +1)
        msglabel = {getmsg /data/voltage -in -slot {n} 1 }
        if ({msglabel} == {label})
            dup_num = n
            echo "Plot " {n} "  " {msglabel} " already exists"
        end
    end
    if (dup_num < 0)
      if({hflag} && {hsolve_chanmode > 1})
        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
          /data/voltage PLOTSCALE \
          {findsolvefield /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
          soma Vm}  *{label} *{colors {row_num}} 1 {offset}
      else
        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/soma /data/voltage \
          PLOTSCALE  Vm  *{label} *{colors {row_num}} 1 {offset}
      end
    end
    // MGBv inputs target y-coord range, not a row, and Inh cells have
    // twice the spacing of Ex cell.  Thus the row numbers of Inh inputs
    // increase at half the rate.
    cell_num =  {round {row_num*Inh_NX/2.0}}  + {round {(Inh_NX -1)/2.0}}
    // redo this for /data/Inh_voltage without assuming it has same messages
    count = {getmsg /data/Inh_voltage -in -count}
    dup_num = -1  // default is that the message doesn't already exist
    for (n = 0; n < count; n = n +1)
        msglabel = {getmsg /data/Inh_voltage -in -slot {n} 1 }
        if ({msglabel} == {label})
            dup_num = n
            echo "Plot " {n} "  " {msglabel} " already exists"
        end
    end
    if (dup_num < 0)
      if({hflag} && {hsolve_chanmode > 1})
        addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/solver \
          /data/Inh_voltage PLOTSCALE \
          {findsolvefield /Inh_layer/{Inh_cell_name}[{cell_num}]/solver \
          soma Vm}  *{label} *{colors {row_num}} 1 {offset}
      else
         addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/soma /data/Inh_voltage \
            PLOTSCALE  Vm *{label} *{colors {row_num}} 1 {offset}
      end
    end
end


/* This is a much simplified version of add_Vmplot, to add plots
   of synaptic currents.  It does no checking for existing plots.
*/

function add_Ikplot(row_num)
    int row_num, cell_num, dup_num, n, count
    str label, msglabel
    float offset
    float iscale = 100e-12 // 100 pA
    int first_row = 8 // the first row to be plotted has no vertical offset
    float delta_y = 2.0*iscale // vertical displacement of subsequent plots
    // target is middle cell in row targeted by row_num
    cell_num = row_num*Ex_NX + {round {(Ex_NX -1)/2.0}}

    // generate PLOTSCALE options  {value} *{label} *{color} scale offset
    label = "row_" @ {row_num}
    offset = (row_num - first_row)*delta_y  //

    if({hflag} && {hsolve_chanmode > 1})
        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
          /Isyndata/syncurrent PLOTSCALE \
          {findsolvefield /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
          {Ex_ex_synpath} Ik} *{label} *{colors {row_num}} 1 {offset}

        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
          /Isyndata/syncurrent PLOTSCALE  \
          {findsolvefield /Ex_layer/{Ex_cell_name}[{cell_num}]/solver \
            {Ex_inh_synpath}  Ik} *"Inh_"{label} *{colors {row_num}} 1 {offset}

        // MGBv inputs target y-coord range, not a row, and Inh cells have
        // twice the spacing of Ex cell.  Thus the row numbers of Inh inputs
        // increase at half the rate.
        cell_num = {round {row_num*Inh_NX/2.0}} + {round {(Inh_NX -1)/2.0}}

        addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/solver \
          /Isyndata/Inh_syncurrent PLOTSCALE  \
          {findsolvefield /Inh_layer/{Inh_cell_name}[{cell_num}]/solver \
            {Inh_ex_synpath} Ik} *{label} *{colors {row_num}} 1 {offset}
        addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/solver \
           /Isyndata/Inh_syncurrent PLOTSCALE  \
           {findsolvefield /Inh_layer/{Inh_cell_name}[{row_num}]/solver \
           {Inh_inh_synpath} Ik}  *"Inh_"{label} *{colors {row_num}} 1 {offset}
    else
        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/{Ex_ex_synpath} \
            /Isyndata/syncurrent \
            PLOTSCALE  Ik  *{label} *{colors {row_num}} 1 {offset}
        addmsg /Ex_layer/{Ex_cell_name}[{cell_num}]/{Ex_inh_synpath} \
            /Isyndata/syncurrent \
            PLOTSCALE  Ik  *"Inh_"{label} *{colors {row_num}} 1 {offset}

        // MGBv inputs target y-coord range, not a row, and Inh cells have
        // twice the spacing of Ex cell.  Thus the row numbers of Inh inputs
        // increase at half the rate.
        cell_num = {round {row_num*Inh_NX/2.0}} + {round {(Inh_NX -1)/2.0}}
        addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/{Inh_ex_synpath} \
          /Isyndata/Inh_syncurrent \
            PLOTSCALE  Ik  *{label} *{colors {row_num}} 1 {offset}
        addmsg /Inh_layer/{Inh_cell_name}[{cell_num}]/{Inh_inh_synpath} \
           /Isyndata/Inh_syncurrent \
            PLOTSCALE  Ik  *"Inh_"{label} *{colors {row_num}} 1 {offset}
    end
end // function add_Ikplot


//==================================
//    Functions to set up the GUI
//==================================

function make_control
    create xform /control [0,0,270,530]
    pushe /control
    create xlabel label -hgeom 25 -bg cyan -label "CONTROL PANEL"
    create xbutton RESET -wgeom 25%       -script reset
    create xbutton RUN  -xgeom 0:RESET -ygeom 0:label -wgeom 25% \
         -script step_tmax
    create xbutton STOP  -xgeom 0:RUN -ygeom 0:label -wgeom 25% \
         -script stop
    create xbutton QUIT -xgeom 0:STOP -ygeom 0:label -wgeom 25% -script quit
    create xdialog RUNID -title "RUNID string:" -value {RUNID} \
                -script "change_RUNID <value>"
    create xdialog stepsize -title "dt (sec)" -value {dt} \
                -script "change_stepsize <widget>"
    create xdialog runtime -title "runtime (sec)" -value {tmax} \
                -script "change_runtime <widget>"
    create xtoggle overlay   -script "overlaytoggle <widget>"
    setfield overlay offlabel "Overlay OFF" onlabel "Overlay ON" state 0
    create xlabel connlabel -label "Connection Parameters"
    create xdialog Ex_ex_gmax -label "Ex_cell ex gmax (nS)" \
         -value {Ex_ex_gmax*1e9} -script "set_Ex_ex_gmax  <v>"
    create xdialog Ex_inh_gmax -label "Ex_cell inh gmax (nS)" \
          -value {Ex_inh_gmax*1e9} -script "set_Ex_inh_gmax  <v>"
    create xdialog Inh_ex_gmax -label "Inh_cell ex gmax (nS)" \
          -value {Inh_ex_gmax*1e9} -script "set_Inh_ex_gmax  <v>"
    create xdialog Inh_inh_gmax -label "Inh_cell inh gmax (nS)" \
          -value {Inh_inh_gmax*1e9} -script "set_Inh_inh_gmax  <v>"
    create xdialog weight -label "Weight"  \
	-value {syn_weight} -script "set_weights <v>"
    create xdialog propdelay -label "Prop delay (sec/m)" \
	-value {prop_delay}  -script "set_delays <v>"
    create xlabel randact -label "Random background activation"
    create xdialog randfreq -wgeom 50% -label "Freq" -value {frequency} \
	-script "set_frequency <v>"
    create xdialog Ex_bg_gmax -wgeom 50% -ygeom 0:randact -xgeom 0:randfreq \
        -label "gmax (nS)" -value {Ex_bg_gmax*1e9} -script "set_Ex_bg_gmax  <v>"
    create xlabel drive_input -label "Thalamic Drive Input"
    create xdialog Ex_dr_gmax -wgeom 50% -label "Ex gmax (nS)" \
         -value {Ex_drive_gmax*1e9} -script "set_Ex_drive_gmax  <v>"
    create xdialog Inh_dr_gmax -wgeom 50% -xgeom 0:Ex_dr_gmax \
         -ygeom 0:drive_input -label "Inh gmax (nS)" \
         -value {Inh_drive_gmax*1e9} -script "set_Inh_drive_gmax  <v>"

    create xdialog drive_weights -label "Default drive weights" \
         -value {drive_weight} -script "set_drive_weights <widget>"
    create xdialog show_params -label "Show params for input:" \
        -value 1  -script "show_params <v>"
    pope
    xshow /control
end

function make_Vmgraph
    str graph_form = "/data"
    str graphlabel = "Vm of center input targets"
    float vmin = -0.07
    float vmax = 0.65
    create xform {graph_form} [275,0,400,800]
    pushe {graph_form}
    create xlabel label -label {graphlabel}
    create xgraph voltage -hgeom 60% -title "Ex_cell Membrane Potential" !
    setfield ^ XUnits sec YUnits V
    setfield ^ xmax {tmax} ymin {vmin} ymax {vmax}
    makegraphscale {graph_form}/voltage
    useclock voltage 2 // the clock used to write the netview file
    create xgraph Inh_voltage -hgeom 30% -ygeom 0:voltage \
        -title "Inh_cell Membrane Potential" -bg white
    setfield ^ XUnits sec YUnits V
    setfield ^ xmax {tmax} ymin {vmin} ymax {vmax}
    makegraphscale {graph_form}/Inh_voltage
    pope
    xshow {graph_form}
end

function make_Ikgraph
    str graph_form = "/Isyndata"
    str graphlabel = "Syn cuurents of center input targets"
    float iscale = 100e-12 // 100 pA
    float imin = -5*iscale
    float imax = 80*iscale
    int xpos = 684; int ypos = 0
    create xform {graph_form} [{xpos}, {ypos},400,800]
    pushe {graph_form}
    create xlabel label -label {graphlabel}
    create xgraph syncurrent -hgeom 64% -title "Ex_cell synaptic currents" !
    setfield ^ XUnits sec YUnits I
    setfield ^ xmax {tmax} ymin {imin} ymax {imax}
    makegraphscale {graph_form}/syncurrent
    useclock voltage 2 // the clock used to write the netview file
    create xgraph Inh_syncurrent -hgeom 30% -ygeom 0:syncurrent \
        -title "Inh_cell synaptic currents" -bg white
    setfield ^ XUnits sec YUnits I
    setfield ^ xmax {tmax} ymin {imin} ymax {imax}
    makegraphscale {graph_form}/Inh_syncurrent
    create xbutton DISMISS -ygeom 0:Inh_syncurrent -script "xhide "{graph_form}
    pope
    xshow {graph_form}
end


function make_graph_messages
    /* Set up plotting messages, with offsets */

    add_Vmplot  8
    add_Vmplot  12
    add_Vmplot  18
    add_Vmplot  24
    add_Vmplot  30
    add_Vmplot  36

    add_Ikplot  18
    add_Ikplot  24
    add_Ikplot  30
    add_Ikplot  36

    str MGBv_graph = "/MGBv_Vm/voltage"
    if (input_type == "MGBv")
    // This needs to be generalized
        str src = "soma"
        addmsg /MGBv[1]/{src} {MGBv_graph} PLOTSCALE Vm *MGBv1_Vm *black 1 0
    elif (input_type == "pulsed_spiketrain" || input_type == "pulsed_randomspike")
        str src = "spikepulse/spike"
        setfield {MGBv_graph} ymin 0.0 ymax 6.0
        // should loop over Ninputs to see which are enabled with spiketoggle
        addmsg /MGBv[5]/{src} {MGBv_graph} PLOTSCALE state *MGBv5_Vm *black 1 0
        addmsg /MGBv[17]/{src} {MGBv_graph} PLOTSCALE state *MGBv17_Vm *blue 1 2
        addmsg /MGBv[29]/{src} {MGBv_graph} PLOTSCALE state *MGBv29_Vm *red 1 4
    end


end // function make_graph_messages

function make_netview  // sets up xview widget to display Vm of each cell
    // Adjust the aspect ratio for rectangular networks of width around 400
    // Make view for Ex_cell[]
    int npixels = 2*{round {180/Ex_NX}}
    int Ex_view_width = npixels*Ex_NX + 20
    int Ex_view_height = npixels*Ex_NY + 17
    if ({exists /Ex_netview})  // make a new one of the right size
        delete /Ex_netview
    end
    create xform /Ex_netview [680,0,{Ex_view_width}, {Ex_view_height}]
    create xdraw /Ex_netview/draw [0%,0%,100%, 100%]
    // Make the display region a little larger than the cell array
    setfield /Ex_netview/draw xmin {-Ex_SEP_X} xmax {Ex_NX*Ex_SEP_X} \
	ymin {-Ex_SEP_Y} ymax {Ex_NY*Ex_SEP_Y}
    create xview /Ex_netview/draw/view

    setfield /Ex_netview/draw/view value_min -0.08 value_max 0.03 \
        viewmode colorview sizescale {Ex_SEP_X}
/* GENESIS doesn't like the wildcard path "{Ex_cell_name}[]/solver"

    if({hflag} && {hsolve_chanmode > 1})
      setfield /Ex_netview/draw/view path /Ex_layer/{Ex_cell_name}[]/solver \
        field {findsolvefield /Ex_layer/{Ex_cell_name}[]/solver soma Vm}
    else
      setfield /Ex_netview/draw/view path /Ex_layer/{Ex_cell_name}[]/soma \
        field Vm
    end
*/
      setfield /Ex_netview/draw/view path /Ex_layer/{Ex_cell_name}[]/soma \
        field Vm

    xshow /Ex_netview
    int Inh_view_width = npixels*Inh_NX + 20
    int Inh_view_height = npixels*Inh_NY + 10
    if ({exists /Inh_netview})  // make a new one of the right size
        delete /Inh_netview
    end
    create xform /Inh_netview [680,{20 + Ex_view_height}, \
	{Inh_view_width + npixels}, {Inh_view_height}]
    create xdraw /Inh_netview/draw [0%,0%,100%, 100%]
    // Make the display region a little larger than the cell array
    setfield /Inh_netview/draw xmin {-Inh_SEP_X} xmax {Inh_NX*Inh_SEP_X} \
	ymin {-Inh_SEP_Y} ymax {Inh_NY*Inh_SEP_Y}

    create xview /Inh_netview/draw/view
    setfield /Inh_netview/draw/view value_min -0.08 value_max 0.03 \
        viewmode colorview sizescale {Inh_SEP_X}
/*
    if({hflag} && {hsolve_chanmode > 1})
      setfield /Inh_netview/draw/view path /Inh_layer/{Inh_cell_name}[]/solver \
        field {findsolvefield /Inh_layer/{Inh_cell_name}[]/solver soma Vm}
    else
      setfield /Inh_netview/draw/view path /Inh_layer/{Inh_cell_name}[]/soma \
        field Vm
    end
*/
      setfield /Inh_netview/draw/view path /Inh_layer/{Inh_cell_name}[]/soma \
        field Vm
    xshow /Inh_netview
end
