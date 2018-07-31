#!/bin/bash
# Runs the function `<function>` for the groups $1 .. $2 in the list `group`,
# where `group` is loaded from the given workspace <workspace>
GAP="/home/sergio/projects/gap-master/bin/gap.sh"
#GAP="/opt/gap/current/bin/gap.sh"
if [ $# != 2 -a $# != 4 ]; then
    echo "usage: benchmark.sh [<from> <till>] <function> <workspace>"
    exit 1
fi
if [ $# == 2 ]; then
    function=$1
    workspace=$2
    I=1
    J=$(echo "Length(groups);" | ${GAP} -q -L ${workspace})
    # gap introduces a carriage return character \r when working with pipes
    J=${J//$'\r'}
fi
if [ $# == 4 ]; then
    I=$1
    J=$2
    function=$3
    workspace=$4
fi
folder="data"
filename="${function}_${workspace}_${I}_${J}"
echo "i, Degree, ONanScottType, Socle, Finished, Mean, Median" \
    > ${folder}/${filename}
echo "$((I - 1)),0" > "${folder}/${filename}_tracking"
for (( ; J - I + 1 ; I++ )) ; do
    echo ${I}
    nohup ${GAP} -q -L ${workspace} \
        ../../utils.g benchmark.g nonbasic.g product-action.g \
        &> 'nohup.out' \
        <<- EOF &
    ChangeDirectoryCurrent("./${folder}");;
    ChangeDirectoryCurrent("./");;
    forget := x -> Group(GeneratorsOfGroup(x));;
    norm := x -> Normalizer(SymmetricParentGroup(x), x);;
    funcWithForget := x -> ${function}(forget(x));;
    BenchmarkCallForGroups("${filename}", funcWithForget, groups);
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
    for (( i=0 ; 30 - i ; i++ )) ; do
        # If computations finished continue with the next group
        ps -p ${pid} > /dev/null
        if [ $? != 0 ]; then
            continue 2
        fi
        sleep 10
    done
    # If the script reaches this place the computation did not finish
    # after roughly 5 minutes
    while [ -e "${folder}/__lock_${filename}" ]; do
        sleep 1
    done
    kill ${pid}
    wait ${pid}
done
rm "${folder}/${filename}_tracking"
