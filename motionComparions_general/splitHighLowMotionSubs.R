options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)

splitMotion<-function(data=args[1],prefix){
  test<-read.csv(data,header = F)
  med<-median(test[,2])
  high<-test[test[,2]>=med,]
  low<-test[test[,2]<med,]
  write.table(high,paste(prefix,"_highMotionSubs.csv",sep=""),quote = F,row.names = F,sep = ",",col.names = F)
  write.table(low,paste(prefix,"_lowMotionSubs.csv",sep=""),quote = F,row.names = F,sep=",",col.names = F)
}

splitMotion(args[1],args[2])

