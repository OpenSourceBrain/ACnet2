#
#
#   File to test current configuration of this neuroConstruct project. 
#
#   To execute this type of file, type '..\..\..\nC.bat -python XXX.py' (Windows)
#   or '../../../nC.sh -python XXX.py' (Linux/Mac). Note: you may have to update the
#   NC_HOME and NC_MAX_MEMORY variables in nC.bat/nC.sh
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
    print "Note: this file should be run using ..\\..\\..\\nC.bat -python XXX.py' or '../../../nC.sh -python XXX.py'"
    print "See http://www.neuroconstruct.org/docs/python.html for more details"
    quit()

sys.path.append(os.environ["NC_HOME"]+"/pythonNeuroML/nCUtils")

import ncutils as nc # Many useful functions such as SimManager.runMultipleSims found here

projFile = File(os.getcwd(), "../ACnet2.ncx")

##############  Main settings  ##################

simConfigs = []

simConfigs.append("Default Simulation Configuration")

simDt =                 0.0025

simulators =            ["NEURON", "GENESIS_PHYS"]
simulators =            ["NEURON", "GENESIS_SI"]

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
    spikeTimesToCheck = {'baskets_0': [112.816, 136.064, 159.31, 182.558, 205.81, 229.058, 252.307, 275.555, 298.801, 322.053, 345.299, 368.55, 391.796, 415.046, 438.294, 461.544, 484.793, 508.042, 531.29, 554.536, 577.787, 601.208],
                         'pyramidals_0': [106.88, 118.28, 129.407, 140.497, 151.601, 162.725, 173.878, 185.066, 196.292, 207.545, 218.826, 230.141, 241.486, 252.861, 264.263, 275.701, 287.158, 298.649, 310.163, 321.705, 333.277, 344.872, 356.49, 368.135, 379.804, 391.5, 403.219, 414.956, 426.72, 438.511, 450.318, 462.146, 473.996, 485.873, 497.767, 509.675, 521.611, 533.563, 545.537, 557.529, 569.539, 581.572, 593.622]}

    spikeTimeAccuracy = 0.65

    report = simManager.checkSims(spikeTimesToCheck = spikeTimesToCheck,
                                  spikeTimeAccuracy = spikeTimeAccuracy)

    print report

    return report


if __name__ == "__main__":
    testAll()
