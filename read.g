LoadPackage("io");
Read("./benchmark.g");
Read("./benchmark-call-for-groups.g");

partitionBacktrack := x -> Normalizer(SymmetricParentGroup(x), x);
