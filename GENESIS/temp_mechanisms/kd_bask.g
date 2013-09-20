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
function make_K_traub_mod
    str chanpath = "K_traub_mod"
    if ({argc} == 1)
       chanpath = {argv 1}
    end
    if (({exists {chanpath}}))
                return
    end

    create tabchannel {chanpath}
    setfield ^  \
        Ek      {EK}    \               //      V
        Ik      0       \               //      A
        Gk      0       \               //      S
        Xpower  4       \
        Ypower  0       \
        Zpower  0

    setupalpha {chanpath} X  \
        {32e3 * (0.015 + EREST_ACT)}    \
        -32e3                           \
        -1.0                            \
        {-1.0 * (0.015 + EREST_ACT) }   \
        -0.005                          \
        500                             \
        0.0                             \
        0.0                             \
        {-1.0 * (0.010 + EREST_ACT) }   \
        0.04
end

