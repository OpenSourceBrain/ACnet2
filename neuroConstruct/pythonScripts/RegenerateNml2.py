# -*- coding: utf-8 -*-
#
#   A file to regenerate the NeuroML 2 files from this neuroConstruct project
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

simConfigs = []
simConfigs.append("TestSoma")

nc.generateNeuroML2(projFile, simConfigs)

# Some extra files have been committed for testing or to provide other LEMS/NeuroML 2 examples
# This just pulls them from the repository, since they get wiped by the generateNeuroML2 function 
extra_files = ['.test.*', 'LargeNet.net.nml', 'TwoCell.net.nml', 'bask.cell.nml', 'pyr_4_sym.cell.nml']
if len(sys.argv)==2 and sys.argv[1] == "-f":
    extra_files.append('ACnet2.net.nml')
    extra_files.append('LEMS_ACnet2.xml')
    
from subprocess import call
for f in extra_files:
    call(["git", "checkout", "../generatedNeuroML2/%s"%f])

quit()
