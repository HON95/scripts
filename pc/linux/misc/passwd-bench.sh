#!/bin/bash

iters=1000; procs=$(nproc); passwd_alg=6; outfile=output.txt; >$output; time for i in $(seq 0 $((($iters+$procs-1)/$procs-1))); do (for j in $(seq $(($i*$procs+1)) $(($i*$procs+$procs))); do output="$j\t$(openssl passwd -$passwd_alg -salt abcdabcdabcdabcd "password $j")" && echo -e "$output" >> $outfile & done); done; echo; sleep 1; tail -n$procs $outfile
