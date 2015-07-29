#!/bin/bash
[[ -d authors ]] && rm -r authors/* || mkdir authors
for f in *.zip; do unzip -O big5 "$f"; done
for f in `ls */*.zip`; do unzip -O big5 -d authors "$f"; done
for d in `ls -d */*/ | grep -v '^authors/'`; do mv "$d" authors; done
for d in `ls -d */ | grep -v '^authors/'`; do rm -r "$d"; done
