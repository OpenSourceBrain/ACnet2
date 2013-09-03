//genesis - spectra_funcs2.g

/* Functions for calculating/displaying spectra

   Assumes global definitions for:
   float tmax   // simulation time in sec
   float out_dt // time step for output from the data source
   int graphics, debug //flags for using graphics or printing extra info

   A typical usage is:

   str timedata ="/time_data" // name of table object for data to analyze
   str data_source = "/EPSCsummer"  // name of object that generates time data
   include spectra_funcs2.g
   setclock  1  {out_dt}
   make_EPSCsummer
   // assume that make_Vmgraph created a graph to plot sum of EPSCs
   addmsg /EPSCsummer /data/Iksum PLOT output *EPSC_sum *red
   make_time_data_table
   addmsg {data_source} {timedata} INPUT output
   make_FTgraph {x} {y}
*/

/* If use_fft_processor =  0, the Fourier Transform will be performed with a
   GENESIS script function to perform the slow Discrete Fourier Transform.

   Otherwise, the function plot_FT invokes an external compiled program
   fft_processor (http://www.arachnoid.com/signal_processing/fft.html).
   It communicates with the program via files {fft_infile} and {fft_outfile}.
*/

int use_fft_processor = 0

int debug = 1

setclock  1  {out_dt}

function make_FTgraph(xpos, ypos)
    str form = "/spectra_form"
    float xpos, ypos
    float xmin = 0; float xmax = 200;
    float ymin = 0; float ymax = 1;
    create xform {form} [{xpos},{ypos},400,380]
    pushe {form}
    create xgraph power_spectrum  -hgeom 70% -bg white
    setfield ^ xmin {xmin} xmax {xmax} ymin 0 ymax {ymax}
    create xbutton do_FT -script calc_spectra \
	-label "Calculate frequency spectra of network activity"
    create xdialog min_time -wgeom 50% -label "Minimum time (sec)" \
	-value 0.0
    create xdialog max_time -wgeom 50% -ygeom 0:do_FT -xgeom 0:min_time \
        -label "Maximum time (sec)" -value {tmax}
    create xdialog max_freq -label "Maximum frequency (Hz)" \
	-value 200
    create xbutton DISMISS -script "xhide "{form}
    pope
    makegraphscale  {form}/power_spectrum
    xshow /spectra_form
end

// make table to hold time series data to Fourier analyse
function make_time_data_table
    int xdivs = {round {2*tmax/{getclock 1}}} + 2 // twice as large as needed
    float xmin = 0; float xmax = {tmax} // this is arbitrary
    if ({exists {timedata}}) // Get rid of any existing one with old xdivs
        delete {timedata}    // table doesn't seem to have a TABDELETE action
    end
    create table {timedata}
    call {timedata} TABCREATE {xdivs} {xmin} {xmax}
    setfield {timedata} step_mode 3
    useclock {timedata}  1
    // One could add a RC element here between {data_source} and {timedata}
    // as low-pass filter, but aliasing of high frequency spectral components
    // doesn't seem to be problem
end

/* Calculate and plot the spectra using a Fast Fourier Transform program
   fft_processor (http://www.arachnoid.com/signal_processing/fft.html).
   If this isn't available, set use_fft_processor =  0 to use a GENESIS
   script function to perform the slow Discrete Fourier Transform.
*/
function plot_FT(timedata, tmin, tmax, fmax)
    str timedata
    float tmin, tmax, fmax, delta_t, delta_f
    float fmin = 0.0
    float h_k, a_n, b_n, p_n, twoPIbyN, scalefactor, pmax
    int i, n, k, kmin, kmax, Npts, Nfreqs
    int maxindex = {getfield {timedata} output}  // index of last entry
    // Use the largest even number for Npts, in order to calc Npts/2 freqs
    int maxpts = 2*{trunc {(maxindex + 1)/2.0}}
    delta_t = {getclock 1}
    kmin = {trunc {tmin/delta_t}}
    kmax = {round {tmax/delta_t}}
    if ({kmax} > {maxpts})
            kmax = maxpts
    end
    delta_f = 1.0/((kmax - kmin)*delta_t)
    Npts = kmax - kmin + 1
    // Limit the range of frequencies calculated
    // fmax must be <= maxpts*delta_f -- this is not checked for!
    Nfreqs = {round {fmax/delta_f}} + 1
    if (debug)
      echo "Index of last time step: " {kmax}
      echo {Npts} " time points from " {tmin} " to " {tmax}
      echo {Nfreqs} " frequency points from 0 to " {(Nfreqs - 1)*delta_f}
      echo "time interval: " {delta_t} " sec; freq interval: " {delta_f} " Hz."
     end

    /* If graphics are used, set up the plots */
    if (graphics)
        str spectraplot = "/spectra_form/power_spectrum/FTpower"
        float ymin = 0; float ymax = 1.0;
        setfield /spectra_form/power_spectrum xmin {fmin} xmax {fmax} \
		ymin 0 ymax {ymax}
        if ({exists {spectraplot}})
	    delete {spectraplot}
        end
        create xplot {spectraplot}
	setfield {spectraplot} fg blue ysquish 0
        call /spectra_form/power_spectrum RESET
    end  // if (graphics)

    if (use_fft_processor) // Use the external program "fft_processor"
      str fft_infile = "fft_infile.txt"
      str fft_outfile = "fft_outfile.txt"
      int array_size // size of array given to fft_processor
      int sample_rate // Sample rate in Hz (integer for fft_processor)
      float new_delta_f // Frequency interval in {fft_outfile}
      int new_Nfreqs // Number of frequencies to plot from {fft_outfile}
      str ablist // Will hold a line read from {fft_outfile}

      // Make a new table of the size to hold the data from tmin thru tmax
      create table /temp_data

      /* Allocate space with xdivs xmin xmax.  Here xmin/xmax are relative to
         the start and end of the selected time range. i.e. xmin = 0,
         xmax = tmax - tmin.
      */
      call /temp_data TABCREATE {Npts - 1} 0 {(Npts - 1)*out_dt}

      i = 0 
      for (k = {kmin}; k <= {kmax}; k = k +1) // Loop over desired time interval
            h_k = {getfield {timedata} table->table[{k}]}
            setfield /temp_data table->table[{i}] {h_k}
            i = i + 1
      end

      // Number of points in the output file have to be a power of 2
      // Horrible curly brackets have to be just right!
      array_size = {pow 2 { {trunc { {log {Npts} }/{log 2} } } + 1 } }
      sample_rate = {round  {(array_size/out_dt)/Npts} }
      if (debug)
        echo "array_size = "{array_size}
        echo "sample_rate = "{sample_rate}
        echo "Before expansion /temp_data last entry " {Npts-1}
        echo {getfield /temp_data table->table[{Npts-1}]}
      end
      // Expand the table to array_size
      call /temp_data TABFILL {array_size - 1} 0

      openfile {fft_infile} w
      writefile  {fft_infile} {array_size}
      writefile  {fft_infile} {sample_rate}
      for (i = 0; i < {array_size}; i = i +1)
          writefile {fft_infile} {getfield /temp_data  table->table[{i}] } 0.0
      end
      closefile {fft_infile}
      if (debug)
        echo "After expansion /temp_data last entry " {array_size - 1}
        echo {getfield /temp_data table->table[{array_size-1}]}
      end
  
      delete /temp_data // delete table, allowing repeated calls to plot_FT

      // Unix shell command using fft_processor.  If this line produces an
      // error, set use_fft_processor = 0, and see the comments earlier
      cat fft_infile.txt | fft_processor > {fft_outfile}

      // now read the resulting fft_outfile
      openfile {fft_outfile} r
      array_size = {readfile  {fft_outfile}}
      sample_rate = {readfile  {fft_outfile}}
      new_delta_f = 1.0*sample_rate/array_size  // cast to float
      new_Nfreqs = {trunc {Nfreqs*delta_f/new_delta_f}}

      if (debug)
        echo "array_size = "{array_size}
        echo "sample_rate = "{sample_rate}
        echo "new_delta_f = "{new_delta_f}
        echo "new_Nfreqs = "{new_Nfreqs}
      end

      // Will store power spectrum in a table
      create table /temp_spectra
      call /temp_spectra TABCREATE {new_Nfreqs - 1} 0 \
          {(new_Nfreqs - 1)*new_delta_f}
      pmax = 0.0
      ablist = {readfile {fft_outfile} -l}  // ignore the zero freq data
      setfield /temp_spectra table->table[0] 0 // replace it with 0

      for (n = 1; n < {new_Nfreqs}; n = n + 1)
        // This is a trick to separately get the two values on one line
        // without doing another read
        ablist = {readfile {fft_outfile} -l}
        a_n = {getarg {arglist {ablist}} -arg 1}
        b_n = {getarg {arglist {ablist}} -arg 2}
        p_n = a_n*a_n + b_n*b_n
        setfield /temp_spectra table->table[{n}] {p_n}
        pmax = {max {pmax} {p_n}} // Find spectrum max for normalization
      end // loop over frequencies

      scalefactor = 1.0/pmax
      if (debug)
           echo "max p_n = " {pmax}
      end
      closefile {fft_outfile}

      if (graphics)
        for (n = 0; n < {new_Nfreqs}; n = n + 1)
          p_n = scalefactor * {getfield /temp_spectra table->table[{n}]}
          call {spectraplot} ADDPTS {n*new_delta_f} {p_n}
        end
      end
      delete /temp_spectra

    else  // Use script function for DFT
      /* Calculate the spectra with a "Slow Fourier Transform".  This is
	 much slower than the Fast Fourier Transform algorithm, which
	 cleverly combines terms in the double sum in the Discrete Fourier
	 Transform.  But it is simple to implemement in GENESIS, and doesn't
         require Npts to be a power of 2.
      */
      // Will store power spectrum in a table
      create table /temp_spectra
      call /temp_spectra TABCREATE {Nfreqs - 1} 0 {(Nfreqs - 1)*delta_f}
      pmax = 0.0
      twoPIbyN = 2*3.14159265/Npts
      if (debug)
          echo {getdate}
      end
      // Now do the slow double summation
      // First, sum over frequencies, skipping the zero frequency component
      setfield /temp_spectra table->table[0] 0 // replace it with 0
      for (n = 1; n < {Nfreqs}; n = n + 1)
        a_n = 0.0
        b_n = 0.0
        for (k = {kmin}; k <= {kmax}; k = k +1) // Sum over time data
            h_k = {getfield {timedata} table->table[{k}]}
            a_n = a_n + h_k*{cos {twoPIbyN*n*k}}
            b_n = b_n + h_k*{sin {twoPIbyN*n*k}}
        end // time loop
        p_n = a_n*a_n + b_n*b_n
        setfield /temp_spectra table->table[{n}] {p_n}
        pmax = {max {pmax} {p_n}} // Find spectrum max for normalization
      end // loop over frequencies
      if (debug)
          echo {getdate}
      end
      scalefactor = 1.0/pmax
      if (graphics)
        for (n = 0; n < {Nfreqs}; n = n + 1)
          p_n = scalefactor * {getfield /temp_spectra table->table[{n}]}
          call {spectraplot} ADDPTS {n*delta_f} {p_n}
        end
      end
    end  // if(use_fft_processor)
end

function calc_spectra
    str dialog = "/spectra_form"
    float tmin = {getfield {dialog}/min_time value}
    float tmax = {getfield {dialog}/max_time value}
    float fmax = {getfield {dialog}/max_freq value}
    plot_FT {timedata} {tmin} {tmax} {fmax}
end
