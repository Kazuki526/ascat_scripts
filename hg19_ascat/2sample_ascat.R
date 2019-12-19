library(tidyverse)
library(pipeR)

### Rscript 2sample_ascat.R patient(subdir name)

argv <- commandArgs(TRUE)

sample=argv[1]
setwd(paste(argv[2],"ascat",sample,sep = "/"))

#run ASCAT functions

library(ASCAT)
file.tumor.LogR <- dir(pattern="tumor.LogR")
file.tumor.BAF <- dir(pattern="tumor.BAF")
file.normal.LogR <- dir(pattern="normal.LogR")
file.normal.BAF <- dir(pattern="normal.BAF")

sex = ifelse(argv[3] == "male","XY","XX")

ascat.bc <- ascat.loadData(file.tumor.LogR, file.tumor.BAF, file.normal.LogR, file.normal.BAF, chrs=c(1:22, "X"), gender=sex)
print("now 32")
#GC correction for SNP6 data
#ascat.bc <- ascat.GCcorrect(ascat.bc, "GC_AffySNP6_102015.txt")

#ascat.plotRawData(ascat.bc)

ascat.bc <- ascat.aspcf(ascat.bc)
print("now 39")
#ascat.plotSegmentedData(ascat.bc)

ascat.output <- ascat.runAscat(ascat.bc)
print("now 43")
write_df_watal = function(x, path, delim='\t', na='NA', append=FALSE, col_names=!append, ...) {
  file = if (grepl('gz$', path)) {
    gzfile(path, ...)
  } else if (grepl('bz2$', path)) {
    bzfile(path, ...)
  } else if (grepl('xz$', path)) {
    xzfile(path, ...)
  } else {path}
  utils::write.table(x, file,
                     append=append, quote=FALSE, sep=delim, na=na,
                     row.names=FALSE, col.names=col_names)
}

ascat.output$segments %>>%
  mutate(ploidy=ascat.output$ploidy,purity=ascat.output$aberrantcellfraction) %>>%
  write_df_watal(paste(sample,"ascat.tsv",sep ="_"))
print("finish")
