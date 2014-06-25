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

simConfigs = []
simConfigs.append("TestSoma")

nc.generateNeuroML2(projFile, simConfigs)

extra_files = ['.test.*', 'LargeNet.net.nml', 'TwoCell.net.nml', 'bask.cell.nml', 'pyr_4_sym.cell.nml']
if len(sys.argv)==2 and sys.argv[1] == "-f":
    extra_files.append('ACnet2.net.nml')
    extra_files.append('LEMS_ACnet2.xml')
    
from subprocess import call
for f in extra_files:
    call(["git", "checkout", "../generatedNeuroML2/%s"%f])

quit()
