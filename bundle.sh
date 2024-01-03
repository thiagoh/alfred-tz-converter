#!/bin/bash

rm -rf /tmp/alfred-tz-converter
mkdir /tmp/alfred-tz-converter
cp -r * /tmp/alfred-tz-converter
rm -rf /tmp/alfred-tz-converter/.git

f=alfred-tz-converter.alfredworkflow && rm $f ; ditto -ck /tmp/alfred-tz-converter $f && open $f
