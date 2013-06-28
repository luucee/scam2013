
require(HMM)

args <- commandArgs(trailingOnly = TRUE)

# default arg values
W<-read.table("WMatrix-random.txt",stringsAsFactors=FALSE)
lkeys<-"perl"
f.train<-read.table("train-random.txt",stringsAsFactors=FALSE)
f.test<-"text-random.txt"

hmmm<-NULL
performance<-FALSE
withother<-FALSE
if (length(args)>0) {
# Rscript hmm.R -hmm model.Rdata -lmatrix WMatrix3.txt -train train3-files.txt -test text-random.txt -lkeys c
# train3-files.txt: traning text file each line a language syntax with the format: lkeys textfile languageSyntax
  for (argi in 1:length(args)) {
		if (args[argi] == "-hmm") {
			if (file.exists("model.Rdata")) {
				cat("file model.Rdata exists, taking existing hmm model\n",file=stderr())
				load("model.Rdata")
			}
#			load(args[argi+1])
		}
		if (args[argi] == "-lmatrix") {
			W<-read.table(args[argi+1],stringsAsFactors=FALSE)
		}
		if (args[argi] == "-train") {
			f.train<-read.table(args[argi+1],stringsAsFactors=FALSE)
		}
		if (args[argi] == "-test") {
			f.test<-args[argi+1]
		}
		if (args[argi] == "-lkeys") {
			lkeys<-args[argi+1]
		}
		if (args[argi] == "-performance") {
			performance<-TRUE
		}
		if (args[argi] == "-withother") {
			withother<-TRUE
		}
	}
}
W<-as.matrix(W)
t2s<-"./text2states.perl "
system(paste(t2s,lkeys," < ",f.test," > ",f.test,".states",sep=""))
test<-read.table(paste(f.test,".states",sep=""),sep="\t",quote="",comment.char = "",as.is=TRUE,header=FALSE)

if (withother) { ## aggiungo un altro stato
	ss<-unique(test$V2)
	sq<-c()
	for(i in 0:(length(ss)-1)) {
		for(j in (i+1):length(ss)) {
			sq<-c(sq,ss[j],ss[j-i])
		}
	}
	write.table(data.frame(sq),file="text-other.txt",quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)
	f.train<-rbind(f.train,c(lkeys,"text-other.txt","Other"))
	wr<-nrow(W)
	dW<-diag(W)
	pother<-sapply(1:wr,function(x) (sum(W[x,])-W[x,x])/wr)
	W<-W-pother/(wr-1)
	W[W<0]<-0
	diag(W)<-dW
	W<-cbind(W,pother)
	W<-rbind(W,c(rep(0.1/wr,wr),0.9))
}

langdescr<-f.train[,3]
write.table(f.train,file=stderr(),quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)
write.table(W,file=stderr(),quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)
write.table(t(c(f.test,lkeys)),file=stderr(),quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)

if (is.null(hmmm)) {


	
	train.states<-list()
	for (i in 1:nrow(f.train)) {
		system(paste(t2s,f.train[i,1]," < ",f.train[i,2]," > ",f.train[i,2],".states",sep=""))
		train.states[[length(train.states)+1]]<-read.table(paste(f.train[i,2],".states",sep=""),sep="\t",quote="",comment.char = "",as.is=TRUE,header=FALSE)
	}
	
	states<-list()
	symb<-c()
	for (i in 1:nrow(f.train)) {
		suff<-paste("S",i,sep="")
		states[[length(states)+1]]<-paste(unique(train.states[[i]]$V2),suff,sep="_")
		symb<-c(symb,unique(train.states[[i]]$V2))
	}

	
	symb<-unique(symb)
	
	allstates<-unlist(states)
# all states are equal starts
	start<-rep(1/length(allstates),length(allstates))
	names(start)<-allstates
# or if you like to start with a particular state eg 1
	the.state<-grep("_S1",allstates)
	start[the.state]<-rep(1/length(the.state),length(the.state))
	start[-the.state]<-0
	
	trans<-matrix(0,nrow=length(allstates),ncol=length(allstates))
	rownames(trans)<-allstates
	colnames(trans)<-allstates
	
	for(k in 1:length(states)) {
		suff<-paste("S",k,sep="")
		for(i in 2:nrow(train.states[[k]])) {
			st1<-paste(train.states[[k]][i-1,"V2"],suff,sep="_")
			st2<-paste(train.states[[k]][i,"V2"],suff,sep="_")
			if (withother & k==length(states)) {
				trans[st1,st2]<-1
			} else {
			  trans[st1,st2]<-trans[st1,st2]+1
			}
		}
	}
	trans<-trans/apply(trans,1,sum)
	trans[is.nan(trans)]<-0
	
	
	for(i in 1:nrow(W)) {
		suff<-paste("_S",i,sep="")
		fromst<-grep(suff,allstates)
		for(j in 1:ncol(W)) {
			suff<-paste("_S",j,sep="")
			tost<-grep(suff,allstates)
			if (i==j) {
				trans[fromst,tost]<-trans[fromst,tost]*W[i,j]
			} else {
				trans[fromst,tost]<-W[i,j]/length(tost)
			}
		}
	}
	
	emis<-matrix(0,nrow=length(allstates),ncol=length(symb))
	rownames(emis)<-allstates
	colnames(emis)<-symb
	for(s in symb) {
		for(k in 1:length(states)) {
			suff<-paste("_S",k,sep="")
			st<-paste(s,suff,sep="")
			if (st %in% allstates) {
				emis[st,s]<-1	
			}
		}
	}
	

	hmmm<-initHMM(allstates, symb, startProbs=start, transProbs=trans, emissionProbs=emis)
	save(hmmm,file="model.Rdata")
	
}

obs<-test$V2
test<-test[obs %in% hmmm$Symbols,]
obs<-obs[obs %in% hmmm$Symbols]

out<-viterbi(hmmm, obs)
result<-rep(1,length(obs))
for(k in unique(substring(hmmm$States,nchar(hmmm$States),nchar(hmmm$States)))) {
	suff<-paste("_S",k,sep="")
	result[grep(suff,out)]<-as.numeric(k)
}
test[,5]<-result
test[,6]<-langdescr[result]

if (!performance) {
  write.table(test,file=stdout(),quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)
} else {
	tb<-table(test$V4,test$V5)
	if(ncol(tb) < nrow(tb)) {
		newtb<-NULL
		for(k in 1:nrow(tb)) {
			if (!k %in% colnames(tb)) {
				newtb<-cbind(newtb,rep(0,nrow(tb)))
			} else {
				newtb<-cbind(newtb,tb[,as.character(k)])
			}
		}
		tb<-newtb
	}
	colnames(tb)<-langdescr
	rownames(tb)<-langdescr
	acc<-sprintf("%.3f",sum(diag(tb))/sum(tb))
	tab.res<-NULL
	for (lsi in 1:nrow(tb)) {
		pr1<-sprintf("%.3f",tb[lsi,lsi]/sum(tb[,lsi]))
		rc1<-sprintf("%.3f",tb[lsi,lsi]/sum(tb[lsi,]))
		tab.res<-rbind(tab.res,as.numeric(c(pr1,rc1)))
	}
	colnames(tab.res)<-c("P","R")
  tab.res<-cbind(tb,tab.res)
	write.table(tab.res,file=stderr(),quote=FALSE,sep="\t",col.names=TRUE,row.names=FALSE)
	write.table(tb[1:length(tb)],file=stdout(),quote=FALSE,sep="\t",col.names=FALSE,row.names=FALSE)
}





