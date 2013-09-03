//genesis - analysis_funcs.g

/* Functions for network spike analysis

   This file is intended to be included by a file such as replay_netview.g
   for replaying and analyzing the result of simulations of two-dimensional
   rectangular grids of "Ex_cells" and "Inh_cells".  It assumes global
   definitions for these quantities:

      float tmax   // simulation time in sec
      int Ex_NX, Ex_NY //  dimensions of the grid of excitatory cells
      int Ninputs  // Number of input rows in the network

      float octave_distance = 0.96e-3 // approx 1 mm/octave
      // used to give integer rows/octave
      rows_per_octave = {round {octave_distance/Ex_SEP_Y}}

   and the existence of a disk_in element /Ex_diskin that uses clock 2.

      A typical usage is:

      include analysis_funcs.g
      make_freq_graph 1048 368
      make_freqmon
      // Set up /Ex_diskin messages to spikegens, and PLOT message to freq_graph
      make_freqmon_messages 0
*/

/* Other global variables defined in this script */

float freq_binwidth = 0.010  // default for "binwidth" used in spike freq calcs

function freq_overlaytoggle(widget)
    str widget
    setfield /freq_form/frequency overlay {getfield {widget} state}
    setfield /freq_form/inh_frequency overlay {getfield {widget} state}
end

function make_freq_graph(xpos, ypos)
    float xpos, ypos
    str form = "/freq_form"
    float binwidth = freq_binwidth
    int row_num = 0
    float xmin = 0; float xmax = 1.0;
    float ymin = 0; float ymax = 25;
    create xform {form} [{xpos},{ypos},400,380]
    pushe {form}
    create xgraph frequency -hgeom 45% -bg white \
        -title "Average Spike Frequency"
    setfield ^ xmin {xmin} xmax {xmax} ymin 0 ymax {ymax}
    create xgraph inh_frequency -hgeom 40% -bg white \
        -title "Average Interneuron Spike Frequency"
    setfield ^ xmin {xmin} xmax {xmax} ymin 0 ymax {40}
    create xdialog rownum -wgeom 50% -title "Row number" \
        -value {row_num} -script "change_rownum <v>"
    create xdialog binwidth -wgeom 50% -ygeom 0:inh_frequency -xgeom 0:rownum \
        -title "Bin width"  -value {binwidth}  \
        -script "change_binwidth <v>"
    create xtoggle overlay -wgeom 50%  -script "freq_overlaytoggle <widget>"
    setfield overlay offlabel "Overlay OFF" onlabel "Overlay ON" state 0
    create xbutton DISMISS -wgeom 50% -ygeom 0:rownum -xgeom 0:overlay \
        -script "xhide "{form}
    pope
    makegraphscale {form}/frequency
    makegraphscale {form}/inh_frequency
    useclock {form}/frequency 3 // This uses the binwidth to avoid ramping
    useclock {form}/inh_frequency 3 // This uses the binwidth to avoid ramping
    xshow {form}
end

function change_binwidth(binwidth)
    float binwidth // default "window" for the frequency monitor
    freq_binwidth = binwidth // set the global value also
    int Ncells
    setclock 3 {binwidth}
    Ncells = {getmsg /frequency_monitor[0]/spikesummer -in -count}
    float scale_factor = 1.0/(binwidth*Ncells)
    setfield /frequency_monitor[0]/spikerate  gain {scale_factor}
    Ncells = {getmsg /inh_frequency_monitor/spikesummer -in -count}
    float scale_factor = 1.0/(binwidth*Ncells)
    setfield /inh_frequency_monitor/spikerate  gain {scale_factor}
end

/* 
   Note that the GENESIS 2 freq_monitor object cannot be used when there
   are multiple spike sources.  Here, a frequency monitor is created with a
   calculator object to sum the states of a set of spikegens responding to
   the soma Vm of each cell in an input row.  Binning is done by setting
   clock 3 to the binwidth and using it for the calculator resetclock.  A
   frequency_monitor is created for each input row.
*/
function make_freqmon
  float binwidth = freq_binwidth  // default "window" for the frequency monitor
  int Ncells = Ex_NX*Ex_NY
  // for a single row of cells
  float scale_factor = 1.0/(binwidth*Ex_NX)
  int targ_row  // rows receiving thalamic input numbered 1 - Nrows
  int n
  // This creates an extra /frequency_monitor[0] for average over all rows
  for (n = 0; n <= Nrows; n = n + 1)
    str name = "/frequency_monitor[" @ {n} @ "]"
    if ({exists {name}})  // Delete any existing frequency monitor
          delete {name}
    end
    create neutral {name} // and make a new one
    pushe {name}
    create calculator spikesummer
    useclock spikesummer 2  // clock used by Ex_diskin and spikecatchers
    setclock 3 {binwidth}
    setfield spikesummer resetclock 3
    create diffamp spikerate
    setfield spikerate  saturation 10000 gain {scale_factor}
    addmsg spikesummer spikerate PLUS output
    pope
  end // for loop over targ_rows, plus one for all rows
  // Now fix the normalization for the average over all cells
  scale_factor = 1.0/(binwidth*Ncells)
  setfield /frequency_monitor[0]/spikerate gain {scale_factor}
end

function make_inh_freqmon
    str name = "/inh_frequency_monitor"
    float binwidth = freq_binwidth // default "window" for the frequency monitor
    int Ncells = Ex_NX*Ex_NY
    float scale_factor = 1.0/(binwidth*Ncells)
    if ({exists {name}})  // Delete any existing frequency monitor
          delete {name}
    end
    create neutral {name} // and make a new one
    pushe {name}
    create calculator spikesummer
    useclock spikesummer 2
    setclock 3 {binwidth}
    setfield spikesummer resetclock 3
    create diffamp spikerate
    setfield spikerate  saturation 10000 gain {scale_factor}
    addmsg spikesummer spikerate PLUS output
    pope
end

/*
These functions set up messages from groups of cells to appropriate spike
detectors, in order to calculate average spiking frequencies.

In these simulations, cells are grouped by horizontal rows in the network.
For the Ex_cells, the network rows are numbered from 0 through Ex_NY -1,
and the cells are numbered from 0 through Ex_NX*Ex_NY -1.

The rows for thalamic input (target rows) are numbered from 1 through
Ninputs, corresponding to Ninputs channels of input.  In the ACnet
simulations, this will be the thalamic output for a tone burst at
a particular frequency.  The target row is logarithmicaly mapped to
vertical distance along the vertical (y) axis to frequency, so that one
octave (a doubling of frequency) spans "octave_distance", and
rows_per_octave = octave_distance/Ex_SEP_Y.

In order to generalize this script to allow for only a single input, but
multiple rows to analyze, Nrows is typically used instead of Ninputs, where 

   row_offset = {round {rows_per_octave/3.0}} // To skip top and bottom rows
   Nrows = Ex_NY - 2*row_offset

The neighboring rows also receive a reduced amount of input from the
thalamic input channel.  For many of the ACnet simulations, these span a
vertical distance of 1/3 of an octave, or +/- rows_per_octave/3 rows.  The
first input row is rows_per_octave/3 rows above cell row 0.
*/

/* This function is specific to /frequency_monitor[0] and the spikerate plot */
function make_freqmon_messages(rownum)
    str name = "/frequency_monitor[0]"
    int rownum, n, offset, maxcell, cellnum
    if (rownum > Nrows)
        echo "Row number must be <= " {Nrows}
        return
    end

    if (rownum == 0)  // this means all rows that can receive input
          offset = ({round {rows_per_octave/3.0}})*Ex_NX
          maxcell = Ex_NX*Ex_NY - 1 - offset
    else              // else just the cells in an input target row
           offset = (rownum + {round {rows_per_octave/3.0}} - 1)*Ex_NX
           maxcell = Ex_NX - 1  // up to end of row
    end
    pushe {name}
    for (n = 0; n <= maxcell; n = n +1)
        create spikegen spikecatcher[{n}]
        useclock spikecatcher[{n}] 2
        setfield spikecatcher[{n}] thresh 0 abs_refract 0.001
        cellnum = n + offset
        addmsg /Ex_diskin  spikecatcher[{n}] INPUT val[0][{cellnum}]
        addmsg spikecatcher[{n}] spikesummer SUM state // state = 1 if spike
    end
    pope
    // Now set up the plot
    int overlay_no = {getfield /freq_form/frequency overlay_no}
    int col_num = overlay_no
    str colorlist = "black red blue cyan green magenta orange"
    str color
    // convert col_num to range 1 though 7
    col_num = col_num - {trunc {col_num/7.0}}*7 + 1
    color = {getarg {arglist {colorlist}} -arg {col_num}}
//    setfield /freq_form/frequency yoffset 10
    addmsg {name}/spikerate /freq_form/frequency PLOT output *frequency *{color}
end

/* Set up /frequency_monitor[1] through /frequency_monitor[Nrows] */   

function make_freq_file
    int n, targ_row, offset, cellnum
    str spike_freq_file = "spike_freq_" @ {RUNID} @ ".txt"
    if ({exists /spike_freq})
        call /spike_freq RESET // this closes and reopens the file
        delete /spike_freq
    end
    create asc_file /spike_freq
    setfield /spike_freq flush 0 leave_open 1 filename {spike_freq_file}
    setfield /spike_freq append 0 float_format %8.3f
    // calculate and write total number of lines and columns to a header

    // t = 0 through tmax - netview_dt, plus header
    int nlines = {round {tmax/freq_binwidth}} + 1
    int ncols = Nrows + 1 // extra column for time
    call /spike_freq OUT_OPEN
    call /spike_freq OUT_WRITE {nlines}  {ncols}
    setfield /spike_freq append 1
    useclock /spike_freq 3  // This is the binwidth

    for (targ_row = 1; targ_row <= Nrows; targ_row = targ_row + 1)
        str name = "/frequency_monitor[" @ {targ_row} @ "]"
        pushe {name}
        offset = (targ_row + {round {rows_per_octave/3.0}} - 1)*Ex_NX
        for (n = 0; n < Ex_NX; n = n +1)	// up to end of row
            create spikegen spikecatcher[{n}]
            useclock spikecatcher[{n}] 2
            setfield spikecatcher[{n}] thresh 0 abs_refract 0.001
            cellnum = n + offset
            addmsg /Ex_diskin  spikecatcher[{n}] INPUT val[0][{cellnum}]
            addmsg spikecatcher[{n}] spikesummer SUM state // 1 if spike
        end
        addmsg spikerate /spike_freq SAVE output
        pope
    end
end

function make_inh_freqmon_messages(rownum)
    str name = "/inh_frequency_monitor"
    int rownum, n, offset, cellnum, maxcell
    if (rownum > Nrows)
        echo "Row number must be <= " {Nrows}
        return
    end

    // MGBv inputs target y-coord range, not a row, and Inh cells have
    // twice the spacing of Ex cell.  Thus the row numbers of Inh inputs
    // increase at half the rate.

    if (rownum == 0)  // this means all rows that can receive input
	  offset = {round {({round {rows_per_octave/3.0}})*Inh_NX/2.0}}
          maxcell = Inh_NX*Inh_NY - 1 - offset
    else              // else just the cells in an input target row
        offset = \
          {round {(rownum -1 + {round {rows_per_octave/3.0}})*Inh_NX/2.0}}
        maxcell =  Inh_NX - 1
    end
    pushe {name}
    for (n = 0; n <= maxcell; n = n +1)
        create spikegen spikecatcher[{n}]
        useclock spikecatcher[{n}] 2
        setfield spikecatcher[{n}] thresh 0 abs_refract 0.001
        cellnum = n + offset
        addmsg /Inh_diskin  spikecatcher[{n}] INPUT val[0][{cellnum}]
        addmsg spikecatcher[{n}] spikesummer SUM state // state = 1 if spike
    end
    pope
    // Now set up the plot
    int overlay_no = {getfield /freq_form/inh_frequency overlay_no}
    int col_num = overlay_no
    str colorlist = "black red blue cyan green magenta orange"
    str color
    // convert col_num to range 1 though 7
    col_num = col_num - {trunc {col_num/7.0}}*7 + 1
    color = {getarg {arglist {colorlist}} -arg {col_num}}
//    setfield /freq_form/inh_frequency yoffset 10
    addmsg {name}/spikerate /freq_form/inh_frequency PLOT output *frequency *{color}
end

function change_rownum(rownum)
    int rownum
    make_freqmon
    make_freqmon_messages {rownum}
    make_inh_freqmon
    make_inh_freqmon_messages {rownum}
    change_binwidth {getclock 3}
end

/* Functions for making and plotting firing rate distribution histogram */

int hbins = 10000     // number of histogram bins
float hbinwidth = 0.1 // Hz

function make_rate_dist
    str name = "rate_dist"
    int n
    int Ncells = Ex_NX*Ex_NY
    if ({exists {name}})  // Delete any existing version
          delete {name}
    end
    create neutral {name} // and make a new one
    pushe {name}

    // make the table that will hold the binned count of number of cells
    // having that averge spiking rate
    create table count_table
    call count_table TABCREATE {hbins} 0 {hbins*hbinwidth} // xdivs xmin xmax

    // add the circuitry and messages from /Ex_diskin

    for (n = 0; n < Ncells; n = n +1)
        create spikegen spikecatcher[{n}]
        useclock spikecatcher[{n}] 2
        setfield spikecatcher[{n}] thresh 0 abs_refract 0.001
        addmsg /Ex_diskin  spikecatcher[{n}] INPUT val[0][{n}]

        create calculator spikecatcher[{n}]/spikecounter
        useclock spikecatcher[{n}]/spikecounter 2
        // For some reason I wanted to reset after a period longer than tmax
        // setclock 4 {tmax}
        setclock 4 1000
        setfield spikecatcher[{n}]/spikecounter resetclock 4
        addmsg spikecatcher[{n}] spikecatcher[{n}]/spikecounter \
            SUM state // state = 1 if spike
    end
    pope

end


//==========================================================
//    Functions to calculate spike times for raster plots
//==========================================================

function make_spike_data_tables(Nplots, tmax, tablename)
    float tmax
    int Nplots
    int Npoints = {round {tmax/0.001}}  // estimate max number of APs
    int i
    int xdivs = Npoints
    float xmin = 0; float xmax = {tmax} // this is arbitrary
    for (i = 0; i < {Nplots}; i = i + 1)
        if ({exists {tablename}[{i}]})
            // Get rid of any existing one with old xdivs
  	    delete {tablename}[{i}]
        end
        create table {tablename}[{i}]
        call {tablename}[{i}] TABCREATE {xdivs} {xmin} {xmax}
        setfield {tablename}[{i}] step_mode 4 stepsize 0.0
    end
//    useclock {tablename}  1
end

function make_spike_time_file(Nplots,filename, tablename)
    str filename, tablename
    int i,j, ntimes, Nplots
    float spike_time
    openfile {filename} w
    for (i = 0; i < {Nplots}; i = i + 1)
        ntimes = {getfield {tablename}[{i}] output}
            for (j=0; j < {ntimes}; j = j + 1)
                spike_time = {getfield {tablename}[{i}] table->table[{j}]}
                // write it to the file
                writefile {filename} {spike_time} " " -n
            end
        writefile {filename}  // put a final newline
    end // i = 0; i < {Nplots}
    closefile {filename} 
end

/* Specialized function to set up the messages from the cells
   for which spike times will be recorded.

    Calculate spike times for n_per_row equally spaced cells on each
    row from row_min through row_max.  Rows are numbered from 0 to Ex_Ny-1.

    The Vm message source will have to be customized
*/

function make_rasterplot_msgs(row_min, row_max, n_per_row, Vm_src, dest_table)
    int i, j, cell_num, row_min, row_max, n_per_row
    str Vm_src, dest_table
    // spacing between cell numbers when n_per_row are plotted
    int spacing = {trunc {Ex_NX/(n_per_row + 1)}}    
    int num_plots = 0
    for (i = {row_min}; i <= {row_max}; i = i + 1)
        if (n_per_row <= 1)  // Just plot the middle cell
            cell_num = i*Ex_NX + spacing
            addmsg {Vm_src} {dest_table}[{i-row_min}] INPUT val[0][{cell_num}]
	else
            for (j = 1; j <= {n_per_row}; j = j + 1)
                cell_num = i*Ex_NX + j*spacing
                addmsg {Vm_src} {dest_table}[{num_plots}] INPUT val[0][{cell_num}]
	        num_plots = num_plots + 1
            end
        end // if (n_per_row <= 1)
    end // for (i = {row_min}; i <= {row_max};)
end

/* Wrapper functions using the above, called from main program */

function setup_rasterplot(n_per_row)  // assume all target rows
    // Number of cells per row to plot
    int n_per_row
    // Target rows for MGBv inputs are numbered 1 through Nrows
    int targ_min = 1; int targ_max = {Nrows}
    int row_min = targ_min + {round {rows_per_octave/3.0}}
    int row_max = targ_max + {round {rows_per_octave/3.0}}
    int Nplots = (targ_max - targ_min + 1)*n_per_row
    make_spike_data_tables {Nplots} {tmax} {spikedata}
    make_rasterplot_msgs {row_min} {row_max} {n_per_row} /Ex_diskin {spikedata}
end

/* This would be for use without the control panel.  Currently,
   make_spike_time_file is called with proper args via the button
   "Write spike times to file" and -script do_write_rasterfile
*/
function write_rasterfile(n_per_row)  // assume all target rows
    int n_per_row
    int Nplots = n_per_row*Nrows
    str spike_time_file = "spike_times_" @ {RUNID} @ ".txt"
    make_spike_time_file {Nplots} {spike_time_file} {spikedata}
    if (debug)
        echo "Wrote spike time data file "{spike_time_file}
    end
end

//==========================================================
//    Functions to create the GUI for the spike analysis
//==========================================================

function histoverlay(widget)
    str widget
    setfield /histform/##[TYPE=xgraph] overlay {getfield {widget} state}
end

function make_hist  // for display of spike freq distribution
    float hgraph_xmax = {hbins*hbinwidth}
    hgraph_xmax = 100 // hack to lower plot range
    str formpath = "/histform"
    float ymax = 100
    create xform {formpath}  [270,430,700,300]
    create xgraph {formpath}/hgraph [0,0%,100%,90%] -ymax 100 -bg ivory
    setfield {formpath}/hgraph XUnits "interval" YUnits count \
        xmax {hgraph_xmax} title "Firing rate distribution"
    create xbutton  {formpath}/display -title "Display Bins" [0,90%,25%,25] \
        -script "xhide "{formpath} -script display_bins
    create xbutton  {formpath}/clear -title "Clear Bins" [25%,90%,25%,25] \
        -script "xhide "{formpath} -script clearbins
    create xbutton  {formpath}/DISMISS [50%,90%,25%,25] \
        -script "xhide "{formpath}
    create xtoggle {formpath}/overlay [75%,90%,25%,25] -script "histoverlay <w>"
    setfield {formpath}/overlay offlabel "Overlay OFF" \
        onlabel "Overlay ON" state 0
    makegraphscale {formpath}/hgraph
end

/* plot a bar on a histogram */
function plotbar(xplotpath, x, y, dx)
    str xplotpath
    float x, y, dx
    call {xplotpath} ADDPTS {x-dx/2} 0
    call {xplotpath} ADDPTS {x-dx/2} {y}
    call {xplotpath} ADDPTS {x+dx/2} {y}
    call {xplotpath} ADDPTS {x+dx/2} 0
end

function del_hist(formpath)
    str formpath, elm
    if({getfield {formpath}/overlay state} == 0)
        foreach elm ({el {formpath}/##[ISA=xplot]})
            delete {elm}
        end
    else // This is getting much less general
        move /histform/hgraph/Count /histform/hgraph/Count#0.0
        setfield /histform/hgraph/Count#0.0 fg orange
    end
    call /histform/hgraph RESET
end

/* post-run analysis */
function display_bins
    str dataform = "/histform"
    str hgraphpath = "/histform/hgraph"
    str hplot = {dataform}@"/hgraph/Count"
    int Ncells = Ex_NX*Ex_NY
    del_hist /histform
    if (!{exists {hplot}})
        create xplot {hplot}
    end
//    setfield {hplot} linewidth 2
    int i, n, index
    float x, y, ymax, count
    call {hgraphpath} RESET

    // loop through the spikecatcher[n]/spikecounter output fields to get
    // the spike count for that cell, normalize to spike freq, and add 1
    // to the appropriate bin of /rate_dist/count_table.

    for (n = 0; n < Ncells; n = n + 1)
        count = {getfield /rate_dist/spikecatcher[{n}]/spikecounter output}
        index = {round {(count/tmax)/hbinwidth}}
        setfield /rate_dist/count_table table->table[{index}] \
            {{getfield /rate_dist/count_table table->table[{index}]} + 1}
    end

    // plot histogram
    ymax = 0.0

    for (i=0; i <  hbins; i=i+1)
        x = (i + 0.5)*hbinwidth
        y = {getfield /rate_dist/count_table table->table[{i}]}
        ymax = {max {y} {ymax}}
        plotbar {hplot} {x} {y} {hbinwidth}
    end
    setfield {hgraphpath} ymax {ymax + 1}
    setfield {hgraphpath} xmax {(hbins + 1)*hbinwidth}
// hack to reduce range of histogram
//    setfield {hgraphpath} xmax 50
    xshow {dataform}
end

/* Functions for ISI histogram and spike analysis */

function clearbins
    int i
    for (i=0; i <  hbins; i=i+1)
        setfield /rate_dist/count_table table->table[{i}] 0
    end
end
