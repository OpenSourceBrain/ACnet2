/*
Section 18.7.3 of the BoG (Utility Functions for Synapses) describes and
gives a listing for the synapse_info function.

Usage:   synapse_info path_to_synchan
Example: synapse_info /network/cell[5]/apical1/Ex_channel

This is used to return a list of synaptic connections to the channel, their
sources, weights, and delays.  It uses some of the built-in GENESIS commands:

getsyncount [presynaptic-element] [postsynaptic-element]
getsynindex <presynptic-element> <postpostsynaptic-element> [-number n]
getsynsrc <postsynaptic-element> <index>
getsyndest  <presynptic-element> <n> [-index] //n is the no of spike message

*/

function synapse_info(path)
   str path,src
   int i
   float weight,delay, x0, y0, z0, x, y, z, r
   floatformat %.3g
   for(i=0;i<{getsyncount {path}};i=i+1)
       src={getsynsrc {path} {i}}
       weight={getfield {path} synapse[{i}].weight}
       delay={getfield {path} synapse[{i}].delay }
       echo synapse[{i}] : rc = {src} weight ={weight} delay ={delay}
       x0 = {getfield {src} x}
       y0 = {getfield {src} y}
       z0 = {getfield {src} z}
       x =  {getfield {path} x}
       y =  {getfield {path} y}
       z =  {getfield {path} z}
       r = {sqrt {(x0-x)*(x0-x) + (y0-y)*(y0-y)}}
       echo "radial distance = "{r} 
   end
end
