#!/bin/bash
if [ -z "$1" ]
then
    echo "simulate.sh needs the name of a toplevel testbench from the rtl directory!"
else
    toplevel=${1%.*}
    toplevel=${toplevel##*/}
    toplevel=${toplevel##*\\} # just in case a windows path was passed...
    getmypath () {
        echo ${0%/*}/
    }
    mypath=$(getmypath)
    tmp="$mypath/../tmp"
    convertfile () {
        modname=${1%.*}
        modname=${modname##*/}
        sv2v $1 > $tmp/$modname.sv
    }
    find ../rtl/ -iname "*.*v" | while read file; do convertfile "$file"; done
    iverilog -o $tmp/out.tmp -g2012 -grelative-include -Y .sv -y $tmp $tmp/$toplevel.sv
    vvp $tmp/out.tmp
fi