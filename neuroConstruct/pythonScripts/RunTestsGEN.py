# -*- coding: utf-8 -*-
#
#   File to compare the behaviour of cells using original GENESIS channels & nC generated code based on ChannelML
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

simConfigs.append("Compare_PyramidalBask_CML_GEN")

simDt =                 0.0025
 
simulators =            ["GENESIS_SI"]


numConcurrentSims =     4

varTimestepNeuron =     True
varTimestepTolerance =  0.00001

plotSims =              True
plotVoltageOnly =       True
runInBackground =       True
analyseSims =           True

verbose = True

#############################################


def testAll(argv=None):
    if argv is None:
        argv = sys.argv

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

    simManager.reloadSims(plotVoltageOnly =   plotVoltageOnly,
                          plotSims =          plotSims,
                          analyseSims =       analyseSims)

    # These were discovered using analyseSims = True above.
    # They need to hold for all simulators
    pyr_times = [106.83, 126.59, 149.69, 176.83, 206.94, 238.54, 270.78, 303.27, 335.85, 368.45, 401.03, 433.57, 466.05, 498.49, 530.88, 563.24, 595.56]
    bask_times = [112.66, 131.97, 151.27, 170.57, 189.87, 209.17, 228.48, 247.78, 267.08, 286.38, 305.68, 324.98, 344.29, 363.59, 382.89, 402.19, 421.49, 440.80, 460.1, 479.4, 498.7, 518.0, 537.3, 556.6, 575.91, 595.21]
    spikeTimesToCheck = {'pyramidals_0': pyr_times,
                         'pyramidals_GEN_0': pyr_times,
                         'baskets_0': bask_times,
                         'baskets_GEN_0': bask_times}

    spikeTimeAccuracy = 1

    report = simManager.checkSims(spikeTimesToCheck = spikeTimesToCheck,
                                  spikeTimeAccuracy = spikeTimeAccuracy)

    print report

    return report


if __name__ == "__main__":
    testAll()
