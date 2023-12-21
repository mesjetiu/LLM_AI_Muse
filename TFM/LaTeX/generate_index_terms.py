# Script en Python para procesar index_terms.txt y generar index_terms.tex

terminos = []
with open('index_terms.txt', 'r') as file:
    for line in file:
        termino = line.strip()
        if termino:
            terminos.append(termino)

lista_terminos = ','.join(terminos)
latex_command = f"\\IndexList{{mylist}}{{{lista_terminos}}}"

with open('index_terms.tex', 'w') as outfile:
    outfile.write(latex_command)
