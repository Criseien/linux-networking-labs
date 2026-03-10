#!/bin/bash
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <log_path> <pattern>" >&2
    echo "Example: $0 /var/log/appservice ERROR" >&2
    exit 1
fi

LOG_DIR="$1"
PATTERN="$2"

if [[ ! -d "$LOG_DIR" ]]; then
    echo "Error: '$LOG_DIR' is not a valid directory" >&2
    exit 1
fi

for FILE in "$LOG_DIR"/*.log; do
    if [[ -r "$FILE" ]]; then
        NAME=$(basename "$FILE")
        LINES=$(wc -l < "$FILE")
        
        ERRORES=$(grep -E -ci "$PATTERN" "$FILE")
        
        echo "File: $NAME, Lines: $LINES, Errors: $ERRORES"
    else
        echo "File is not readable by $(whoami): $FILE" >&2
        INCOMPLETE=1
    fi
done

if [[ $INCOMPLETE -eq 1 ]]; then
    exit 2
fi