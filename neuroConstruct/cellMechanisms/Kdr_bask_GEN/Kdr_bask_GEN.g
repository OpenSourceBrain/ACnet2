/* FILE INFORMATION
     GENESIS implementation by D. Beeman of the channel models described in
     Alain Destexhe and Denis Par, Impact of network activity on the
     integrative properties of neocortical pyramidal neurons in vivo.
     Journal of Neurophysiology 81: 1531-1547, 1999

   Some adjustments were made to represent the model in

     Destexhe A, Rudolph M, Fellous JM and Sejnowski TJ.
     Fluctuating synaptic conductances recreate in-vivo-like activity in
     neocortical neurons. Neuroscience 107: 13-24, 2001.

   Based on the NEURON demonstration 'FLUCT' by Alain Destexhe.
   http://cns.iaf.cnrs-gif.fr
*/

// passive membrane parameters
float   CM
float   RA
float   RM

// channel equilibrium potentials (V)
float   EREST_ACT = -0.063  // value for vtraub in Destexhe et al. (2001)
// float   EREST_ACT = -0.058 // value for vtraub in Destexhe and Par (1999)
float   ENA       =  0.050
float   EK        = -0.090

/* These channels use the setupalpha function to create tabchannel tables
   to represent alpha and beta values in the form (A+B*V)/(C+exp((V+D)/F))
   The first 6 arguments are the coefficients for alpha, and the last 6
   are for beta
*/



//========================================================================
//                Tabchannel K(DR) Hippocampal cell channel
// Based on Traub, R. D. and Miles, R.  Neuronal Networks of the hippocampus
// Cambridge University Press (1991)
//========================================================================


function make_%Name%
    str chanpath = "/library/%Name%"
    if ({argc} == 1)
       chanpath = {argv 1}
    end
    if (({exists {chanpath}}))
                return
    end

    /* This version scales the tau values by 0.5 */
    float tau_scale = 0.5
            
    create tabchannel {chanpath}
    setfield ^  \
        Ek      {EK}    \               //      V
        Ik      0       \               //      A
        Gk      0       \               //      S
        Xpower  4       \
        Ypower  0       \
        Zpower  0

    setupalpha {chanpath} X  \
        {(32e3 * (0.015 + EREST_ACT))/{tau_scale}}    \
        {-32e3/{tau_scale}}                        \
        -1.0                            \
        {-1.0 * (0.015 + EREST_ACT) }   \
        -0.005                          \
        {500/{tau_scale}}                \
        0.0                             \
        0.0                             \
        {-1.0 * (0.010 + EREST_ACT) }   \
        0.04
end
