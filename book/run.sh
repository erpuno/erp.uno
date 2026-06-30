#!/bin/sh
pdflatex --interaction=nonstopmode erp.tex
makeindex erp.idx
pdflatex --interaction=nonstopmode erp.tex
pdflatex --interaction=nonstopmode erp.tex
exit 0
