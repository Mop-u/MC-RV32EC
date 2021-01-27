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
    rtl="$mypath/../rtl"
    rm $tmp/*
    incdirlist=$(find $rtl/ -not -path */testbench -and -type d -exec echo -I {} \; )
    filelist="$(find $rtl/ -name $1) $(find $rtl/ -not -path */testbench/* -and \( -iname *.v -o -iname *.vh -o -iname *.sv \) )"
    sv2v $incdirlist $filelist > "$tmp/$toplevel.sv"
    cp $mypath/../rom/rom.bin $tmp/rom.bin
    cd $tmp/
    iverilog -o $tmp/out.tmp -g2012 -grelative-include -Y .sv -y $tmp $tmp/$toplevel.sv
    vvp $tmp/out.tmp
fi