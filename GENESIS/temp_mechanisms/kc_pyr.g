// genesis - kc_pyr.g - channels for cortical pyramidal cells
// based on genesis/Scripts/neurokit/prototypes/traub91chan.g 

/* Note some hacks below:
   I've added an optional chanpath arg to the make_xxx_traub91 functions
   to allow renaming them.  But, if the Ca-dependent channels are to
   work properly, the Ca_concen element must be named "Ca_conc" and
   the Ca channel must be named Ca_hip_traub91
*/

/* FILE INFORMATION
** The 1991 Traub set of voltage and concentration dependent channels
** Implemented as tabchannels by : Dave Beeman
**      R.D.Traub, R. K. S. Wong, R. Miles, and H. Michelson
**	Journal of Neurophysiology, Vol. 66, p. 635 (1991)
**
** This file depends on functions and constants defined in defaults.g
** As it is also intended as an example of the use of the tabchannel
** object to implement concentration dependent channels, it has extensive
** comments.  Note that the original units used in the paper have been
** converted to SI (MKS) units.  Also, we define the ionic equilibrium 
** potentials relative to the resting potential, EREST_ACT.  In the
** paper, this was defined to be zero.  Here, we use -0.060 volts, the
** measured value relative to the outside of the cell.
*/

/* November 1999 update for GENESIS 2.2: Previous versions of this file used
   a combination of a table, tabgate, and vdep_channel to implement the
   Ca-dependent K Channel - K(C).  This new version uses the new tabchannel
   "instant" field, introduced in GENESIS 2.2, to implement an
   "instantaneous" gate for the multiplicative Ca-dependent factor in the
   conductance.   This allows these channels to be used with the fast
   hsolve chanmodes > 1.
*/

// CONSTANTS
float EREST_ACT = -0.060 /* hippocampal cell resting potl */
float ENA = 0.115 + EREST_ACT // 0.055
float EK = -0.015 + EREST_ACT // -0.075
float ECA = 0.140 + EREST_ACT // 0.080
float SOMA_A = 3.320e-9       // soma area m^2 - usually will be changed

/*
For these channels, the maximum channel conductance (Gbar) has been
calculated using the CA3 soma channel conductance densities and soma
area.  Typically, the functions which create these channels will be used
to create a library of prototype channels.  When the cell reader creates
copies of these channels in various compartments, it will set the actual
value of Gbar by calculating it from the cell parameter file.
*/
//========================================================================
//  Voltage- and Ca-dependent K Channel - K(C))
//========================================================================
/*
The expression for the conductance of the potassium C-current channel has a
typical voltage and time dependent activation gate, where the time dependence
arises from the solution of a differential equation containing the rate
parameters alpha and beta.  It is multiplied by a function of calcium
concentration that is given explicitly rather than being obtained from a
differential equation.  Therefore, we need a way to multiply the activation
by a concentration dependent value which is determined from a lookup table.
This is accomplished by using the Z gate with the new tabchannel "instant"
field, introduced in GENESIS 2.2, to implement an "instantaneous" gate for
the multiplicative Ca-dependent factor in the conductance.
*/

function make_Kc_hip_traub91
    str chanpath = "Kc_hip_traub91"
    if ({argc} == 1)
       chanpath = {argv 1}
    end
    if ({exists {chanpath}})
       return
    end
    create  tabchannel      {chanpath}
                setfield        ^       \
                Ek              {EK}    \                       //      V
                Gbar            { 100.0 * SOMA_A }      \       //      S
                Ik              0       \                       //      A
                Gk              0                               //      S

// Now make a X-table for the voltage-dependent activation parameter.
        float   xmin = -0.1
        float   xmax = 0.05
        int     xdivs = 49
        call {chanpath} TABCREATE X {xdivs} {xmin} {xmax}
        int i
        float x,dx,alpha,beta
        dx = (xmax - xmin)/xdivs
        x = xmin
        for (i = 0 ; i <= {xdivs} ; i = i + 1)
            if (x < EREST_ACT + 0.05)
                alpha = {exp {53.872*(x - EREST_ACT) - 0.66835}}/0.018975
                    beta = 2000*{exp {(EREST_ACT + 0.0065 - x)/0.027}} - alpha
            else
                alpha = 2000*{exp {(EREST_ACT + 0.0065 - x)/0.027}}
                beta = 0.0
            end
            setfield {chanpath} X_A->table[{i}] {alpha}
            setfield {chanpath} X_B->table[{i}] {alpha+beta}
            x = x + dx
        end

// Expand the tables to 3000 entries to use without interpolation
    setfield {chanpath} X_A->calc_mode 0 X_B->calc_mode 0
    setfield {chanpath} Xpower 1
    call {chanpath} TABFILL X 3000 0

// Create a table for the function of concentration, allowing a
// concentration range of 0 to 1000, with 50 divisions.  This is done
// using the Z gate, which can receive a CONCEN message.  By using
// the "instant" flag, the A and B tables are evaluated as lookup tables,
//  rather than being used in a differential equation.
        float   xmin = 0.0
        float   xmax = 1000.0
        int     xdivs = 50

        call {chanpath} TABCREATE Z {xdivs} {xmin} {xmax}
        int i
        float x,dx,y
        dx = (xmax - xmin)/xdivs
        x = xmin
        for (i = 0 ; i <= {xdivs} ; i = i + 1)
            if (x < 250.0)
                y = x/250.0
            else
                y = 1.0
            end
            /* activation will be computed as Z_A/Z_B */
            setfield {chanpath} Z_A->table[{i}] {y}
            setfield {chanpath} Z_B->table[{i}] 1.0
            x = x + dx
        end
        setfield {chanpath} Z_A->calc_mode 0 Z_B->calc_mode 0
        setfield {chanpath} Zpower 1
// Make it an instantaneous gate (no time constant)
    setfield {chanpath} instant {INSTANTZ}
// Expand the table to 3000 entries to use without interpolation.
    call {chanpath} TABFILL Z 3000 0

// Now we need to provide for messages that link to external elements.
// The message that sends the Ca concentration to the Z gate tables is stored
// in an added field of the channel, so that it may be found by the cell
// reader.
        addfield Kc_hip_traub91 addmsg1
        setfield Kc_hip_traub91 addmsg1  "../Ca_conc  . CONCEN Ca"
end
