args <- commandArgs(trailingOnly = TRUE)
worker<-paste(args[4],"/maskAves2carpet.R",sep="")
source(worker)
maskAves2carpet(args[1],args[2],args[3])
