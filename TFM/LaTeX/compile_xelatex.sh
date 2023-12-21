#!/bin/bash

# Este script compilará el documento principal del proyecto en xelatex y generará el pdf final. Incluye la generación de la bibliografía y el índice.

bibtex main
# lualatex main.tex
xelatex main.tex
python ./generate_index_terms.py    
makeindex main
bibtex main
# lualatex main.tex
xelatex main.tex
