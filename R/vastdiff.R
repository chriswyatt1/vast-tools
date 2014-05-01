#!/usr/bin/Rscript --vanilla

# Copyright (C) 2014 Tim Sterne-Weiler
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the Software 
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


argv <- commandArgs(trailingOnly = F)
scriptPath <- dirname(sub("--file=","",argv[grep("--file",argv)]))

# Source Rlib.
source(paste(c(scriptPath,"/Rlib/include.R"), collapse=""))
source(paste(c(scriptPath,"/Rlib/include_diff.R"), collapse=""))

# custom install from include.R
loadPackages(c("getopt", "RColorBrewer", "reshape2", "ggplot2", "grid"))

argv <- commandArgs(TRUE)

spec = matrix(c(
	'verbose', 'v', 0, "logical",
	'help', 'h', 0, "logical",
	'plotSig', 'p', 0, "logical",
	'repA', 'a', 1, "character",
	'repB', 'b', 1, "character"
), byrow=TRUE, ncol=4)

opt = getopt(spec)

if ( !is.null(opt$help) ) {
	cat(getopt(spec, command="vast diff", usage=TRUE))
	q(status=1)
}

#set some defaults for the options
if ( is.null(opt$verbose ) ) { opt$verbose = FALSE }
if ( is.null(opt$plotSig ) ) { opt$plotSig = FALSE }

if(opt$plotSig) {
  dir.create("diff_out")
  q()
}

#-replicatesA=name1@name2@name3 -replicatesB=name4@name5

firstRepN <- 2
secondRepN <- 2

psiFirst <- vector("list", firstRepN)
psiSecond <- vector("list", secondRepN)

### READ INPUT ###

inputFile <- file( opt$repA, 'r' ) 

while (length(lines <- readLines(inputFile, n=1000)) > 0){ 
  for (i in 1:length(lines)){ 
    #?
    writeLines(lines[i])
  } 
}

q()
### END READ INPUT ###

#sample here from rbeta(N, alpha, beta)

psiFirstComb <- do.call(c, psiFirst)
psiSecondComb <- do.call(c, psiSecond)

shuffOne <- shuffle(psiFirstComb)  #unless paired=T
shuffTwo <- shuffle(psiSecondComb) # unless paired=T



#GET FROM INPUT
Sample_1_Name <- "SamA"
Sample_2_Name <- "SamB"

sampOneName <- paste(c(substr(Sample_1_Name, 1, 4), "(n=", as.character(firstRepN), ")"), collapse="")
sampTwoName <- paste(c(substr(Sample_2_Name, 1, 4), "(n=", as.character(secondRepN), ")"), collapse="")

# calculate the probability that the first dist is > than second
distPlot <- ggplot(melt(as.data.frame(
			do.call(cbind,list(psiFirstComb, psiSecondComb))
			)), aes(fill=variable, x=value))+
			geom_histogram(aes(y=..density..),alpha=0.5, col="grey", position="identity")+
			theme_bw()+xlim(c(0,1))+xlab(expression(hat(Psi)))+
			scale_fill_manual(values=cbb[2:3], labels=c(sampOneName, sampTwoName), name="Samples")


probPlot <- ggplot(as.data.frame(cbind(seq(0,1,0.01), 
				unlist(lapply(seq(0,1,0.01), function(x) { 
					pDiff(shuffTwo, shuffOne, x) 
				})))), aes(x=V1, y=V2))+
				geom_line()+theme_bw()+
				geom_vline(x=maxDiff(shuffTwo, shuffOne), lty="dashed")+
				ylab(expression(P((hat(Psi)[1]-hat(Psi)[2]) > x)))+
				xlab(expression(x))+
				geom_text(x=maxDiff(shuffTwo, shuffOne), y=-0.1, label=maxDiff(shuffTwo, shuffOne))

pdf(sprintf("%s_%d_mer.pdf", argv[3], n), width=7, height=6)
multiplot(distPlot, probPlot, cols=2)
dev.off()

q(status=0)