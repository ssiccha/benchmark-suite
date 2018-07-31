I=$1
J=$2
folder="data"
filename="magma_prim_${I}_${J}"
MAGMA="/opt/magma/current/magma"
echo "i, Degree, ONanScottType, Socle, Mean, Median, 3rd Quartile, Maximum" > ${folder}/${filename}
echo "[$((I - 1)),0,0]" > "${folder}/${filename}_tracking"
for (( ; J - I + 1 ; I++ )) ; do
    magma -b ../../utils.m ONanScottType.m benchmark.m <<- EOF
    Alarm(600);
    ChangeDirectory("./${folder}");;
    forget := function(x) return PermutationGroup< Degree(x) | Generators(x) >; end function;
    f := function(x) return Normalizer(SymmetricGroup(Degree(x)), forget(x));; end function;
    BenchmarkCallForGroups("${filename}", f);
EOF
done
rm "${folder}/${filename}_tracking"
