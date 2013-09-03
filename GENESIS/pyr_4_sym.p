// layer5.p - Cell parameter file for the Bush and Sejnowski (1993)
// reduced 9 compartment layer 5 (deep) cortical pyramidal cell.

*relative
*cartesian
*symmetric

// membrane constants (SI units)
*set_global        RM      0.7042     // ohm*m^2
*set_global        RA      2.0        // ohm*m
*set_global        CM      0.0284     // farad/m^2
*set_global     EREST_ACT  -0.066     // volts (leakage potential)

// Populate soma wih modified traub91 channels

soma    none  0  0 17 23 \
    Na_pyr             1200  \
    Kdr_pyr             800  \
    Ca_hip_traub91      100  \
    Kahp_pyr             25  \
    Ca_conc            -7.769e12    \
    spike 0.0

apical0 soma       0   0  60   6
apical2 apical0    0   0  400  4.4
apical3 apical2    0   0  400  2.9 AMPA_pyr 2.6526
apical4 apical3    0   0  250  2
apical1 apical0 -150   0   0   3 AMPA_pyr 2.6526
basal0  soma     0     0   -50     4 GABA_pyr 2.6526
basal1  basal0 106.07  0  -106.07  5 AMPA_pyr 5.0
basal2  basal0 -106.07 0  -106.07  5
