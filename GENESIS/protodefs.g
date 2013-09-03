
// protodefs.g - Definition of prototype elements for Auditory Cortex Cells

/* Included files are in genesis/Scripts/neurokit/prototypes */

float EREST_ACT = -0.07       // resting membrane potential (volts)
float ENA   = 0.045           // sodium equilibrium potential
float EK    = -0.082          // potassium equilibrium potential

/* file for standard compartments */
include compartments

// include the definitions for the functions to create channels
include  pyrchans.g

// Make a "library element" to hold the prototypes, which will be used
// by the cell reader to add compartments and channels to the cell.

if (!{exists /library})     // But, only if it doesn't already exist
    create neutral /library
end

// We don't want the library to try to calculate anything, so we disable it
disable /library

// To ensure that all subsequent elements are made in the library
pushe /library

/* Make a prototype compartment.  The internal fields will be set by
   the cell reader, so they do not need to be set here.  The
   make_cylind_compartment function is defined in compartments.g.
*/

make_cylind_compartment

/* makes "symcompartment", if needed */
// make_cylind_symcompartment

/* Make the pyramidal cell channels.  

   Note that pyrchans.g changes some global variables.  Different
   values could be added here.
*/

/* the values in pyrchans.g are
float EREST_ACT = -0.060 // hippocampal cell resting potl
float ENA = 0.115 + EREST_ACT // 0.055
float EK = -0.015 + EREST_ACT // -0.075
float ECA = 0.140 + EREST_ACT // 0.080
*/

make_Na_hip_traub91 Na_pyr
make_Kdr_hip_traub91 Kdr_pyr
// slow down the firng by doubling Kdr_pyr
scaletabchan Kdr_pyr X tau 1.0 2.0 0.0 0.0

make_Ca_hip_traub91  // This needs to keep the name Ca_hip_traub91
make_Kahp_hip_traub91 Kahp_pyr
/* The original traub91 Kahp tau had a max of 1 sec at [Ca]=0, dropping
   to 0.2 when [Ca]=200, and 0.1 at higher values.  This scaling makes the
   typical range 10-50 msec, which is roughly the time for adaptation in
   neocortical pyramidal cells.
*/
scaletabchan Kahp_pyr Z tau 1.0 0.05 0.0 0.0

make_Ca_hip_conc Ca_conc
/* The original Ca_conc tau was 0.0133 sec.  A value of 0.05 sec gives
    [Ca] more time to decay.
*/
setfield Ca_conc tau 0.1

/* Make the synaptically activated channels */
make_AMPA_pyr AMPA_pyr /* synchan with Ek = 0.0, tau1 = tau2 = 3 msec */
make_GABA_pyr GABA_pyr /* synchan with Ek = -0.080, tau1 = 3, tau2 = 8 msec */

/* make a spike generator */
create spikegen spike
setfield spike  thresh 0.00  abs_refract 1.0e-3  output_amp 1

/* Make the Fast Spiking basket cell channels.  */
include FSchans.g

/*   Note that FSchans.g changes some global variables.  Different
     values could be added here, before creating the channels.
*/

/* the values in baskchans.g are
float   EREST_ACT = -0.063  // value for vtraub in Destexhe et al. (2001)
float   ENA       =  0.050
float   EK        = -0.090
*/

make_Na_traub_mod Na_bask
make_K_traub_mod  Kdr_bask
// speed them up by scaling the activation time constants by 0.5
scaletabchan Na_bask X tau 1.0 0.5  0.0 0.0
scaletabchan Na_bask Y tau 1.0 0.5  0.0 0.0
scaletabchan Kdr_bask X tau 1.0 0.5 0.0 0.0

/* Make the synaptically activated channels */
// Presently, AMPA_bask and GABA_bask are the same as AMPA_pyr and GABA_pyr

make_AMPA_bask AMPA_bask // synchan with Ek = 0.0, tau1 = tau2 = 3 msec */
copy AMPA_bask AMPA_bask_drive // make a similar channel for Ex drive input
make_GABA_bask GABA_bask // synchan with Ek = -0.080, tau1 = 3, tau2 = 8 msec

pope // Return to the original place in the element tree
