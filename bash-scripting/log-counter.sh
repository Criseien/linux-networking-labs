#!/bin/bash
set -ex
FILES="/var/log/*.log"

function errores {
        for FILE in $FILES; do
                WL=$(wc -l < "$FILE")
                ERROR=$(grep -cie "error" "$FILE")
                NAME=$(basename "$FILE")
                echo "$NAME: $WL líneas, $ERROR errores"
        done
}
errores