# Create Workspace
almostSimpleGroups :=
    AllPrimitiveGroups(NrMovedPoints, [3..1000], ONanScottType, ["2"]);
almostSimpleSmallBaseGroups :=
    Filtered(almostSimpleGroups, g -> not IsAlternatingGroup(Socle(g)));
groups := almostSimpleSmallBaseGroups;
SaveWorkspace("data/workspaces/almost-simple-small-base.gapws");
