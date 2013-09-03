// bask.p - Cell parameter file for fast spiking basket cell based on FScell06

//	Format of file :
// x,y,z,dia are in microns, all other units are SI (Meter Kilogram Sec Amp)
// In polar mode 'r' is in microns, theta and phi in degrees 
// readcell options start with a '*'
// The format for each compartment parameter line is :
//name	parent	r	theta	phi	d	ch	dens ...
//in polar mode, and in cartesian mode :
//name	parent	x	y	z	d	ch	dens ...
// For channels, "dens" =  maximum conductance per unit area of compartment
// For spike elements, "dens" is the spike threshold
//		Coordinate mode
*relative
*cartesian
*asymmetric

//		Specifying constants  -- SI units
*set_compt_param	RM	0.7
*set_compt_param	RA	0.7
*set_compt_param	CM	0.015
*set_compt_param     EREST_ACT	-0.065

// reorient this along -z axis if I want dendrite to point down instead of up

soma  none   0  0  40  40  Na_bask 1000  Kdr_bask 500  GABA_bask 1.0 spike 0.0
dend  soma  0  0  200   2  AMPA_bask 1.0  AMPA_bask_drive 1.0
