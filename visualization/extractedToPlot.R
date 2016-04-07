args <- commandArgs(trailingOnly = TRUE)
library(ggplot2)
extractedToPlot<-function(data,title,prefix){
  extracted<-read.csv(data)
  
  p <- ggplot(extracted, aes(Group, BetaVal)) + geom_boxplot(aes(fill = factor(Group)))+ geom_jitter(width=.2) + ggtitle(as.character(title))
  
  #violin <-ggplot(extracted, aes(Group, BetaVal, fill=Group)) +
  # geom_violin()+ geom_jitter(width=.1)
  png(filename=as.character(prefix))
  print(p)
  dev.off()
}
extractedToPlot(args[1],args[2],args[3])