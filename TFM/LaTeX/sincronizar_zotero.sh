#!/bin/bash

#!/bin/bash

# Define la URL de la colección de Zotero
ZOTERO_URL="http://127.0.0.1:23119/better-bibtex/export/collection?/1/IA%20-%20LLM.biblatex"

# Define la ruta donde deseas guardar el archivo BibTeX
BIBTEX_PATH="./bibtex/biblio.bib"

# Usa curl para descargar el archivo BibTeX de la URL proporcionada
curl -L $ZOTERO_URL -o $BIBTEX_PATH

# lualatex main.tex
# makeindex main
# bibtex main
# lualatex main.tex
# lualatex main.tex
