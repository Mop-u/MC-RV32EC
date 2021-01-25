#!/bin/bash
if [ -z "$1" ]
then
    echo "Provide the name of the desired toplevel testbench in the rtl directory!"
else
    toplevel=${1%.*}
    toplevel=${toplevel##*/}
    toplevel=${toplevel##*\\} # just in case a windows path was passed...
    tmp="$PWD/../tmp"
    convertfile () {
        modname=${1%.*}
        modname=${modname##*/}
        sv2v $1 > $tmp/$modname.v
    }
    find ../rtl/ -iname "*.*v" | while read file; do convertfile "$file"; done
    iverilog -o $tmp/out.tmp -g2012 -grelative-include -y $tmp $tmp/$toplevel.v
    vvp $tmp/out.tmp
fi