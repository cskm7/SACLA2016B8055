#!/home/software/SACLA_tool/bin/python2.7
import numpy as np
import h5py 
import matplotlib
import matplotlib.pyplot as plt
import argparse
import time
#import pandas as pd
import sys
  
from argparse import ArgumentParser

parser = ArgumentParser()
parser = ArgumentParser(description="Plot intense ice shots")

parser.add_argument("-run", "--run-number",  type=int, dest="run", required=True,
                help="run to process")
parser.add_argument("-t", "--threshold",  type=float, dest="threshold", default=10.0,
                help="photon threshold (default: 10 photons)")
parser.add_argument("-exp", "--exp-year",  type=int, dest="exp", default=2016,
                help="experimental year to compress (default: 2016)")
parser.add_argument("-multi", "--multi-run", action="store_true", dest="multi", required=False, default=False,
                help="process multi-file run converted using DataConvert4")
parser.add_argument("-tag", "--output-tag", type=str, dest="tag", default="run",
                help="tag for output folder (default: run)")
parser.add_argument("-o", "--output-flag", type=str, dest="outputFlag",
                help="where to process runs. 'W' refers to /work/perakis/ and 'UD' refers to '/UserData/fperakis' (default: UD)",
                choices=['W','UD'], default='UD')

args = parser.parse_args()

# -- default parameters
file_folder = '/UserData/fperakis/2016_6/%s%d/'%(args.tag,args.run) # h5 files folder
src_folder  = '/home/fperakis/2016_06/git/SACLA2016A8015/src/' # src files folder
adu_gain = 75.0 # adu/photon @ 5 keV

# -- files and folders
file_name = '%d.h5'%(args.run)
file_path = file_folder+file_name
sys.path.insert(0, src_folder)
from img_class import *

# -- import data
fh5       = h5py.File(file_path, 'r')
run_key   = [ k for k in fh5.keys() if k.startswith('run_') ][0]
tags      = fh5['/%s/detector_2d_assembled_1'%run_key].keys()[1:]

# -- image generator
img_gen = ( fh5['%s/detector_2d_assembled_1/%s/detector_data'%(run_key,tag) ].value for tag in tags )
num_im = len(tags)
mean_int = np.zeros(num_im)

# -- average image
im = img_gen.next()
i=1
if (np.average(im.flatten()) > adu_gain*args.threshold):
    im_avg = im
    i_avg=1
else:
    im_avg = np.zeros_like(im)
    i_avg=0

for im_next in img_gen:
    t1 = time.time() 
    mean_int[i] = np.average(im_next.flatten())
    avg_int = np.average(im_next.flatten())
    if (mean_int[i] > 75*10):
        im_avg += im_next
        i_avg += 1
    i += 1
    print 'R.%d | S.%d/%d/%d | %.1f Hz'%(args.run,i_avg,i,num_im,1.0/(time.time() - t1))
im_avg /= num_im

# -- run mean
total_mean = np.average(im.flatten())

# -- plot
title = 'r.%d - average %d shots'%(args.run,num_im)
i = img_class(im_avg, title)
i.savefig(file_folder+'%d_ice.png'%args.run)
i.draw_img()
