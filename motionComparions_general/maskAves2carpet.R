##maskAves2Carpet

library(ggplot2)
library(gridExtra)
library(reshape2)
library(RColorBrewer)
maskAves2carpet<-function(maskAveTable, motionFileTable, prefix){
  maskAve<-read.table(maskAveTable)
  motionFiles<-read.table(motionFileTable)
  for(i in 1:nrow(maskAve)){
    tmpSubString<-strsplit(as.character(maskAve[i,]),"/")
    nameIndex<-length(tmpSubString[[1]])
    tmpSubName<-tmpSubString[[1]][nameIndex]
    subName<-paste(strsplit(as.character(tmpSubName),"_")[[1]][2],strsplit(as.character(tmpSubName),"_")[[1]][3],sep="_")
    subMaskAve<-read.table(as.character(maskAve[i,]))
    subMaskAve<-t(subMaskAve)
    maskAve_rowcenter<-subMaskAve-apply(subMaskAve, 2, mean)
    subFD<-read.table(as.character(motionFiles[i,]))
    subFD<-cbind(1:nrow(subFD),subFD)
    colnames(subFD)<-c("TR","FD")
    if(nrow(subMaskAve) != nrow(subFD)){
      stop(paste("the length of",subName, "dataset is: ",nrow(subMaskAve),"the length of FD file is: ",nrow(subFD),"These Don't match up and they need to!! double check that FD and rest scans are either both censored or NOT!!!!!"))
    }
    p1<-ggplot(subFD, aes(TR,FD)) + geom_line(colour="red", size=1)+ theme_bw()+scale_x_continuous(limits=c(0,nrow(subFD)), expand = c(0, 0)) + scale_y_continuous(limits=c(0,2), expand = c(0, 0))
    p2<-ggplot(melt(as.matrix(maskAve_rowcenter)), aes(Var1,Var2, fill=value)) + geom_raster()+scale_fill_gradient(low = "black",high = "white")+ theme(legend.position="none")+ scale_y_continuous(expand = c(0, 0))+scale_x_discrete(labels="test",breaks=c())
    png(filename=paste(prefix,subName,"png",sep="."))
    print(grid.arrange(p1, p2, ncol = 1))
    dev.off()
  }
}