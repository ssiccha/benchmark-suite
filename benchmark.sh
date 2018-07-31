#!/bin/bash
# In the workspace <workspace> a variable `groups` must be defined.
# Starts GAP sessions for each group in `groups{[$1 .. $2]}` which do:
# - Read the file <file-to-read>.
# - Measure time of the function call <function> on the current group.
# - Collect the result in a csv file.
# If a GAP session does not finish in a certain time window, its process
# is killed and the script continues with the next group.
GAP="/home/sergio/projects/gap-master/bin/gap.sh"
#GAP="/opt/gap/current/bin/gap.sh"
if [ $# != 3 -a $# != 5 ]; then
    echo -n "usage: benchmark.sh [<from> <till>] <function> <file-to-read>"
    echo " <workspace>"
    exit 1
fi
if [ $# == 3 ]; then
    function=$1
    to_read=$2
    workspace=$3
    I=1
    J=$(echo "Length(groups);" | ${GAP} -q -L ${workspace})
    # gap introduces a carriage return character \r when working with pipes
    J=${J//$'\r'}
fi
if [ $# == 5 ]; then
    I=$1
    J=$2
    function=$3
    to_read=$4
    workspace=$5
fi
folder="data/results"
filename="${function}_${workspace//$'.gapws'}_${I}_${J}.csv"
echo "i, Degree, ONanScottType, Socle, Finished, Mean, Median" \
    > ${folder}/${filename}
echo "$((I - 1)),0" > "${folder}/${filename}_tracking"
for (( ; J - I + 1 ; I++ )) ; do
    echo ${I}
    nohup ${GAP} -q -L ${workspace} \
        ../../utils.g benchmark.g  \
        &> 'nohup.out' \
        <<- EOF &
    ChangeDirectoryCurrent("./${folder}");;
    ChangeDirectoryCurrent("./");;
    BenchmarkCallForGroups("${filename}", ${function}, groups);
EOF
    pid=$!
    sleep 1
    # If computations finished continue with the next group
    # Else, wait another 4 seconds
    ps -p ${pid} > /dev/null
    if [ $? != 0 ]; then
        continue 1
    fi
    sleep 4
    for (( i=0 ; 5 - i ; i++ )) ; do
        # If computations finished continue with the next group
        ps -p ${pid} > /dev/null
        if [ $? != 0 ]; then
            continue 2
        fi
        sleep 10
    done
    # FIXME: make the maximum time per run a variable.
    # If the script reaches this place the computation did not finish
    # after roughly 1 minute.
    while [ -e "${folder}/__lock_${filename}" ]; do
        sleep 1
    done
    kill ${pid}
    wait ${pid}
done
rm "${folder}/${filename}_tracking"
