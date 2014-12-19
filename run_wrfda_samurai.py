#!/usr/bin/python

import sys, os

# MUST edit namelist.obsproc and namelist.input to match 
# your choice of domains
domain = str(3)

rtpth = '/Users/brbrown/WRF/arthur2014/da/'
oppth = rtpth + 'obwork'
dapth = rtpth + 'varwork'
smrpth = '/Users/brbrown/matlab_scripts/samurai/'
toolpth = '/Users/brbrown/tools/datools/graphics/ncl/'
imagenm = '_pp_nobg_d0'

# create obs file
os.chdir(smrpth)
# compile samurai_to_littler if necessary
os.system('gfortran samurai_to_littler.f90 -o samurai_test -I/usr/local/Cellar/netcdf/4.3.2/include -L/usr/local/Cellar/netcdf/4.3.2/lib -lnetcdff -lnetcdf')
os.system('./samurai_test')

# clean directories and recopy essential files
os.chdir(oppth)
os.system('rm -f *')
os.system('cp -a ../obsproc.exe .')
os.system('cp ../obserr.txt .')
os.system('cp ../namelist.obsproc .')
os.system('cp '+smrpth+'/test_f90_samurai_littler .')

os.chdir(dapth)
os.system('rm -f *')
os.system('cp -a ../da_wrfvar.exe .')
os.system('cp ../LANDUSE.TBL .')
os.system('cp ../namelist.input .')
os.system('cp ../be.dat .')
os.system('cp ../../morsn/wrfinput_d0' + domain +' fg')

# run obsproc
os.chdir(oppth)
os.system('./obsproc.exe >& obsproc.log')

# run 3DVAR
os.chdir(dapth)
os.system('cp ../obwork/obs_gts_2014-07-03_12:00:00.3DVAR ob.ascii')
os.system('./da_wrfvar.exe >& wrfvar.log')

# create diagnostic images
os.chdir(toolpth)
os.system('ncl plot_ob_ascii_loc.ncl')
os.system('ncl WRF-Var_plot.ncl')


# move/save diagnostic figures
os.system('cp WRF-VAR_U_level_8.pdf ' +rtpth +'images/level8U'+imagenm+domain+'.pdf')
os.system('cp obsloc20140703.pdf ' +rtpth +'images/obsloc'+imagenm+domain+'.pdf')
os.system('rm WRF-VAR_U_level_8.pdf')
os.system('rm obsloc20140703.pdf')
os.chdir(rtpth+'images')
os.system('open level8U'+imagenm+domain+'.pdf')
os.system('open obsloc'+imagenm+domain+'.pdf')
