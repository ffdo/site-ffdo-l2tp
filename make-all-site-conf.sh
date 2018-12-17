#!/bin/bash

set -e

# The output dir will be deleted and recreated in the process!
OUTPUT_DIR=./generated/sites

for target in "./sites/configs/"*
do
	./create_sitedir.py "./sites/templates" "./sites/common" "$target" "$OUTPUT_DIR/$(basename "$target" .yaml)"
done
echo "Site configurations created in $OUTPUT_DIR"
