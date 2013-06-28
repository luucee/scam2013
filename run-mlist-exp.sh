#!/bin/bash

for i in `ls -a $1/*.txt`
do
echo $i
Rscript hmm.R -hmm -train train-httpd.txt -lmatrix WMatrix-httpd.txt -lkeys c -test $i | ./annotate.perl $i > $i.html
done
