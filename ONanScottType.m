_ONanScottType:=function(G)
/*
  Input: a primitive permutation group G
  Output: the ONan-Scott type of G. It returns one of the following strings
  "AffineS","AffineN", "Diagonal", "ProductAction", "AlmostSimple"
*/
  local k,n1,n2,n3,n4,n5;
  k:=PrimitiveGroupIdentification(G);d:=Degree(G);
  n1:=NumberOfPrimitiveSolubleGroups(d);
  n2:=NumberOfPrimitiveAffineGroups(d);
  n3:=NumberOfPrimitiveDiagonalGroups(d);
  n4:=NumberOfPrimitiveProductGroups(d);
  n5:=NumberOfPrimitiveAlmostSimpleGroups(d);
//  print <n1,n2,n3,n4,n5,n2+n>;
  if k in [1..n1] then return "1";end if;
  if k in [n1+1..n2] then return "1";end if;
  if k in [n2+1..n2+n3] then return "3";end if;
  if k in [n2+n3+1..n2+n3+n4] then return "4";end if;
  if k in [n2+n3+n4+1..n2+n3+n4+n5] then return "2";end if;
  return "fail";
end function;
