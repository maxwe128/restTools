library(ggplot2)
maskAves2QCRSFC<-function(maskAveTable,motionFile,prefix,dir){ #inputs need to have each row match subjects
  maskAves<-read.table(maskAveTable,header = F)
  bigCorTable<-{}
  for(i in 1:nrow(maskAves)){
    testDat<-read.table(as.character(maskAves[i,]))
    corTest<-cor(t(testDat))
    corTest[upper.tri(corTest)]<-NA
    diag(corTest)<-NA
    longCor<-na.omit(as.vector(corTest))
    bigCorTable<-cbind(bigCorTable,longCor)
  }
  distMat<-read.csv(paste(dir,"/Dosenbach_Science_160ROI_Euclidean",sep=""),header=F)
  distMat[upper.tri(distMat)]<-NA
  diag(distMat)<-NA
  longDist<-na.omit(as.vector(as.matrix(distMat)))
  
  motion<-read.table(motionFile)
  QC<-cbind(longDist,apply(bigCorTable,MARGIN = 1,cor,y=motion))
  colnames(QC)<-c("Distance","Correlation")
  QC<-as.data.frame(QC)
  corr<-cor(QC[,1],QC[,2])
  p1 <- ggplot(QC, aes(x = Distance, y = Correlation))
  p2<-p1 + geom_point()+geom_smooth(method = "lm")+geom_text(data=QC, aes(label=paste("r=", format(cor(Distance,Correlation),digits=2), sep="")), x=145, y=-.6)+ggtitle(as.character(paste(prefix,corr)))+labs(x="Distance (mm)",y="FC-FD Correlation (r)") + ylim(-.75, .75)
  png(filename=prefix)
  print(p2)
  dev.off()
  #return(head(QC))
  
  #write.table(bigCorTable,"test")
  #return(dim(bigCorTable))
}

##command to Run







#library(ggplot2)
#install.packages("gridExtra")
#library(gridExtra)
#mtc <- mtcars
#p1 <- ggplot(mtc, aes(x = hp, y = mpg))
#p1 + geom_point()+geom_smooth(method = "lm")+geom_text(data=mtc, aes(label=paste("r=", format(cor(hp,mpg),digits=2), sep="")), x=100, y=10)
#geom_text(data=cors, aes(label=paste("r=", cor, sep="")), x=1, y=-0.25)
