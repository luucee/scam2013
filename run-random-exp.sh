#!/bin/bash


for ml in nfs LKML pm pci
do
for i in {1..10}
do
./generate-random-test.perl linux-$ml > text-random.txt
cp text-random.txt text-random.txt.$i
find linux-* -size -10 | grep -v linux-$ml | grep comments | xargs cat > nltext-linux.txt
find linux-* -size -10 | grep -v linux-$ml | grep patch | xargs cat > patch-linux.txt
cat codice-linuxkernel.c > c-code.c
echo "E2.4" $i $ml `Rscript hmm.R -train train-random.txt -lmatrix WMatrix-random.txt -lkeys c -test text-random.txt -performance`
cp nltext-linux.txt nltext-linux.temp
cp text-frankenstein.txt nltext-linux.txt
echo "E2.3" $i $ml `Rscript hmm.R -train train-random.txt -lmatrix WMatrix-random.txt -lkeys c -test text-random.txt -performance`
cp codice-postgresql.c c-code.c
echo "E2.2" $i $ml `Rscript hmm.R -train train-random.txt -lmatrix WMatrix-random.txt -lkeys c -test text-random.txt -performance`
cp nltext-linux.temp nltext-linux.txt
echo "E2.1" $i $ml `Rscript hmm.R -train train-random.txt -lmatrix WMatrix-random.txt -lkeys c -test text-random.txt -performance`
done
done