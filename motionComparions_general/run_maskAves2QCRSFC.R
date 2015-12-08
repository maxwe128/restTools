args <- commandArgs(trailingOnly = TRUE)
worker<-paste(args[4],"/maskAves2QCRSFC.R",sep="")
source(worker)
maskAves2QCRSFC(args[1],args[2],args[3],args[4])
