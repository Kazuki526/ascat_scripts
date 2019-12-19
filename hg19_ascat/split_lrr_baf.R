library(tidyverse)
library(pipeR)
## Rscript split_lrr.baf.R LRR_BAF.txt CEL_LIST.txt PWD
argv <- commandArgs(TRUE)
setwd(argv[3])

if(substring(argv[1],1,4)=="norm"){nt="normal"}else{nt="tumor"}

#files=data_frame(filename=c("norm.CEL","tumor.CEL"),patient=c("testt","testt"))
files=read_tsv(argv[2])
rowlength=length(files$filename)
for(l in 0:(rowlength%/%50)){
  row_rest=50
  if(l==rowlength){row_rest=(rowlength%%50)}
  filenames = files$filename[(l*50+1):(l*50+row_rest)]
  patients  = files$patient[(l*50+1):(l*50+row_rest)]
  logrname = paste(filenames,"Log R Ratio"  ,sep=".")
  bafname  = paste(filenames,"B Allele Freq",sep=".")
  cols=c("Name","Chr","Position",logrname,bafname) %>>%
  {setNames(c("c","c","i",rep("d",row_rest*2)),.)} %>>%
  {do.call(readr::cols_only,as.list(.))}
  each=read_tsv(argv[1],col_type=cols)
  snpos=each %>>%dplyr::select(Name,Chr,Position)
  CNprobe=substring(snpos$Name,1,2)=="CN"
  for(m in seq_len(row_rest)){
    print(paste0("now print out ",l*50+m,": ",patients[m]," LogR & BAF"))
    .filename =filenames[m]
    .each=each %>>% dplyr::select(starts_with(.filename))
    .baf = .each %>>% dplyr::select(ends_with("B Allele Freq"))%>>%unlist(use.names = F)
    .baf[.baf==2] =NA
    .logr = .each %>>% dplyr::select(ends_with("Log R Ratio"))%>>%unlist(use.names = F)
    .logr[CNprobe] = .logr[CNprobe] - mean(.logr[CNprobe],na.rm=T)
    .logr[!CNprobe] = .logr[!CNprobe] - mean(.logr[!CNprobe],na.rm=T)
    
    write.table(cbind(snpos,.logr),paste("ascat" ,patients[m], paste(nt,"LogR.txt",sep="."), sep="/"),
                sep="\t",row.names=F,col.names=c("","Chr","Position",patients[m]),quote=F)
    write.table(cbind(snpos,.baf) ,paste("ascat",patients[m], paste(nt,"BAF.txt" ,sep="."), sep="/"),
                sep="\t",row.names=F,col.names=c("","Chr","Position",patients[m]),quote=F)
  }
}
