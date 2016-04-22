#!/bin/bash

###used to make partially inflated surface for any spec file, this is often the best way to visualize surface results

#call From the SUMA dir, Assumes this is a standard mesh with typical SUMA naming conventions

bothSpec=$1 #the both spec file that you want to create a partially inflated suface for
iter=$2 #iterations of surf smooth, this controls how inflated the surface will be. 200 and 500 seem like common inputs

lhSpec=$(echo $bothSpec | sed 's/_both.spec/_lh.spec/g')
rhSpec=$(echo $bothSpec | sed 's/_both.spec/_rh.spec/g')
meshPre=$(echo $bothSpec | cut -d "." -f1-2)
#make new inflation with SurfSmooth
SurfSmooth -spec $lhSpec -surf_A lh.smoothwm.asc -met NN_geom -surf_out $meshPre.lh.smoothwm.SS$iter.asc -Niter $iter -match_area 0.01
SurfSmooth -spec $rhSpec -surf_A rh.smoothwm.asc -met NN_geom -surf_out $meshPre.rh.smoothwm.SS$iter.asc -Niter $iter -match_area 0.01
#Edit the spec files to accomadate new surface, kind of a hassle
#lh
sed -i 's/StateDef = std.sphere.reg/StateDef = std.sphere.reg\n        StateDef = std.SS'$iter'/g' $lhSpec
printf "\nNewSurface\n       SurfaceFormat = ASCII\n       SurfaceType = FreeSurfer\n       FreeSurferSurface = ./$meshPre.lh.smoothwm.SS$iter.asc\n       LocalDomainParent = ./SAME\n       SurfaceState = std.SS$iter\n       EmbedDimension = 3\n       Anatomical = N\n       LocalCurvatureParent = ./SAME" >> $lhSpec
#rh
sed -i 's/StateDef = std.sphere.reg/StateDef = std.sphere.reg\n        StateDef = std.SS'$iter'/g' $rhSpec
printf "\nNewSurface\n       SurfaceFormat = ASCII\n       SurfaceType = FreeSurfer\n       FreeSurferSurface = ./$meshPre.rh.smoothwm.SS$iter.asc\n       LocalDomainParent = ./SAME\n       SurfaceState = std.SS$iter\n       EmbedDimension = 3\n       Anatomical = N\n       LocalCurvatureParent = ./SAME" >> $rhSpec
#both
sed -i 's/StateDef = std.sphere.reg/StateDef = std.sphere.reg\n        StateDef = std.SS'$iter'/g' $bothSpec
printf "\nNewSurface\n       SurfaceFormat = ASCII\n       SurfaceType = FreeSurfer\n       FreeSurferSurface = ./$meshPre.lh.smoothwm.SS$iter.asc\n       LocalDomainParent = ./SAME\n       SurfaceState = std.SS$iter\n       EmbedDimension = 3\n       Anatomical = N\n       LocalCurvatureParent = ./SAME" >> $bothSpec
printf "\nNewSurface\n       SurfaceFormat = ASCII\n       SurfaceType = FreeSurfer\n       FreeSurferSurface = ./$meshPre.rh.smoothwm.SS$iter.asc\n       LocalDomainParent = ./SAME\n       SurfaceState = std.SS$iter\n       EmbedDimension = 3\n       Anatomical = N\n       LocalCurvatureParent = ./SAME" >> $bothSpec
