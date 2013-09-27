/*======================================================================

  Test script used to compare the original Genesis implementation with
  neuroConstruct generated scripts. Notice that channel properties are
  changed in protodefs.g -- the mechanisms in nC thus have to be
  adapted to reflect these changes.

  ======================================================================*/

float celsius = 6.3

//protodefs
include compartments 
include synchans
create neutral /library
disable /library
pushe /library
make_cylind_compartment

//Setting up channels
include ../pyrchans.g
make_Na_hip_traub91 Na_pyr
make_Kdr_hip_traub91 Kdr_pyr
make_Ca_hip_traub91  
make_Kahp_hip_traub91 Kahp_pyr
make_Ca_hip_conc Ca_conc
pope

readcell pyr_4_sym.p /pyramidal


//Adding a current pulse of amplitude: 6.0E-10 A, SingleElectricalInput: [Input: IClamp, cellGroup: pyramidals, cellNumber: 0, segmentId: 0, fractionAlong: 0.5]
create neutral /stim
create neutral /stim/pulse
create neutral /stim/rndspike
create pulsegen /stim/pulse/iclamp


//Pulses are shifted one dt step, so that pulse will begin at delay1, as in NEURON
setfield ^ level1 6.0E-10 width1 0.5 delay1 0.099975 delay2 10000.0  
addmsg /stim/pulse/iclamp /pyramidal/soma INJECT output


create hsolve pyramidal/solve
setfield pyramidal/solve path pyramidal/#[][TYPE=compartment],pyramidal/#[][TYPE=symcompartment] comptmode 1
setmethod pyramidal/solve 11
setfield pyramidal/solve chanmode 0
call pyramidal/solve SETUP
reset

//simulation settings
float dt = 2.5E-5
float duration = 0.8
int steps =  {round {{duration}/{dt}}}

setclock 0 {dt} // Units[GENESIS_SI_time, symbol: s]

//////////////////////////////////////////////////////////////////////
//   Adding 2 plot(s)
//////////////////////////////////////////////////////////////////////

create neutral /plots

create xform /plots/pyramidal_ca [500,100,400,400]  -title "Ca_conc:CONC:ca (Ca) in /pyramidal"
xshow /plots/pyramidal_ca
create xgraph /plots/pyramidal_ca/graph -xmin 0 -xmax {duration} -ymin 0.0 -ymax 1.0E30
addmsg /pyramidal/soma/Ca_conc /plots/pyramidal_ca/graph PLOT Ca *...amidal/soma_Ca_conc:Ca *black

create xform /plots/pyramidal_v [500,100,400,400]  -title "VOLTAGE (Vm) in /pyramidal"
xshow /plots/pyramidal_v
create xgraph /plots/pyramidal_v/graph -xmin 0 -xmax {duration} -ymin -0.09 -ymax 0.05
addmsg /pyramidal/soma /plots/pyramidal_v/graph PLOT Vm *.../pyramidal_soma:Vm *black


//////////////////////////////////////////////////////////////////////
//   Creating a simple Run Control
//////////////////////////////////////////////////////////////////////

if (!{exists /controls})
    create neutral /controls
end
create xform /controls/runControl [700, 20, 200, 140] -title "Run Controls: Sim_108"
xshow /controls/runControl

create xbutton /controls/runControl/RESET -script reset
str rerun
rerun = { strcat "step " {steps} }
create xbutton /controls/runControl/RUN -script {rerun}
create xbutton /controls/runControl/STOP -script stop

create xbutton /controls/runControl/QUIT -script quit


//////////////////////////////////////////////////////////////////////
//   This will run a full simulation when the file is executed
//////////////////////////////////////////////////////////////////////

reset

echo Starting sim: Sim_1 with dur: {duration} dt: {dt} and steps: {steps} (Crank-Nicholson num integration method (11), using hsolve: true, chanmode: 0)
date +%F__%T__%N
step {steps}

echo Finished simulation reference: Sim_108
date +%F__%T__%N
