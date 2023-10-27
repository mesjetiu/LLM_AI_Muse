#!/bin/bash
lualatex main.tex
makeindex main
bibtex main
lualatex main.tex
lualatex main.tex
