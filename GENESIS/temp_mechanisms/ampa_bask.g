// channel equilibrium potentials (V)
float   EREST_ACT = -0.063  // value for vtraub in Destexhe et al. (2001)
// float   EREST_ACT = -0.058 // value for vtraub in Destexhe and Par (1999)
float   ENA       =  0.050
float   EK        = -0.090

//========================================================================
//                Synaptically activated channels
//========================================================================

float EAMPA = 0.0
float EGABA = -0.080

function make_AMPA_bask
    str chanpath = "AMPA_bask"
    if ({argc} == 1)
       chanpath = {argv 1}
    end
    if ({exists {chanpath}})
       return
    end
    float tau1 = 0.003
    float tau2 = 0.003
    create  synchan      {chanpath}
    setfield        ^       \
        Ek                      {EAMPA} \
        tau1            {tau1} \        // sec
        tau2            {tau2} \        // sec
        gmax            0 // Siemens
end

