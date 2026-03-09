#!/bin/bash

FILE="$1"

if [[ $# -ne 1 ]]; then
        echo "Error: necesitas pasar un archivo"
        exit 1
fi

if [[ ! -f $FILE ]]; then
        echo "Error: archivo no encontrado: $FILE"
        exit 2
else
        echo "Procesando $FILE"
fi