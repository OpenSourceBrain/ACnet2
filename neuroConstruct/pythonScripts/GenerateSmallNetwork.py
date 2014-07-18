# -*- coding: utf-8 -*-
#
#   File to generate the "SmallNetwork" simulation configuration from the nC project 
#
#   Author: Padraig Gleeson
#
#   This file has been developed as part of the neuroConstruct project
#   This work has been funded by the Medical Research Council and the
#   Wellcome Trust
#
#

import sys
import os

try:
    from java.io import File
except ImportError:
    print "Note: this file should be run using 'nC.bat -python XXX.py' or 'nC.sh -python XXX.py'"
    print "which use Jython (and so can access the Java classes in nC), as opposed to standard C based Python"
    print "See http://www.neuroconstruct.org/docs/python.html for more details"
    quit()

sys.path.append(os.environ["NC_HOME"]+"/pythonNeuroML/nCUtils")

import ncutils as nc # Many useful functions such as SimManager.runMultipleSims found here

projFile = File(os.getcwd(), "../ACnet2.ncx")

##############  Main settings  ##################

simConfigs = []

simConfigs.append("SmallNetwork")

simDt =                 0.025

simulators =            []

numConcurrentSims =     2

varTimestepNeuron =     True
varTimestepTolerance =  0.00001

plotSims =              True
plotVoltageOnly =       True
runInBackground =       False

verbose = True

#############################################


def testAll(argv=None):
    if argv is None:
        argv = sys.argv

    if len(argv)==1:
        print("\nNo options specified! Run this file using\n" + \
              "   nC.sh -python %s [-neuron|-genesis]\n"%argv[0])
        quit()
    
    if '-neuron' in argv:
        simulators.append('NEURON')
    if '-genesis' in argv:
        simulators.append('GENESIS_SI')
        
        
    if '-neuroml2' in argv:
        # Not yet working...
        nc.generateNeuroML2(projFile, simConfigs)
    
    if len(simulators)>0:
        print "Loading project from "+ projFile.getCanonicalPath()

        simManager = nc.SimulationManager(projFile,
                                          numConcurrentSims = numConcurrentSims,
                                          verbose = verbose)

        simManager.runMultipleSims(simConfigs =           simConfigs,
                                   simDt =                simDt,
                                   simulators =           simulators,
                                   runInBackground =      runInBackground,
                                   varTimestepNeuron =    varTimestepNeuron,
                                   varTimestepTolerance = varTimestepTolerance)

        print("\nSimulation(s) set running. Check the ../simulations directory for output.\n")
        
    quit()

if __name__ == "__main__":
    testAll()
