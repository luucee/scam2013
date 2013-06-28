#!/bin/bash

echo "Biostring" `Rscript hmm.R -train train-rtextbook.txt -lmatrix WMatrix-rtextbook.txt -lkeys R -test bios.txt -performance`
