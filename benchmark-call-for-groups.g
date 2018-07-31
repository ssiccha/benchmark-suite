Exec2 := function( arg )
    local   cmd,  i,  shell,  cs,  dir;

    # simply concatenate the arguments
    cmd := ShallowCopy( arg[1] );
    if not IsString(cmd) then
      Error("the command ",cmd," is not a name.\n",
      "possibly a binary is missing or has not been compiled.");
    fi;
    for i  in [ 2 .. Length(arg) ]  do
        Append( cmd, " " );
        Append( cmd, arg[i] );
    od;

    # select the shell, bourne shell is the default: sh -c cmd
    if ARCH_IS_WINDOWS() then
        # on Windows, we use the native shell such that behaviour does
        # not depend on whether cygwin is installed or not.
        # cmd.exe is preferrable to old-style `command.com'
        shell := Filename( DirectoriesSystemPrograms(), "cmd.exe" );
        cs := "/C";
    else
        shell := Filename( DirectoriesSystemPrograms(), "sh" );
        cs := "-c";
    fi;

    # execute in the current directory
    dir := DirectoryCurrent();

    # execute the command
    return Process( dir, shell, InputTextUser(), OutputTextUser(), [ cs, cmd ] );
end;

createLockFile := function( filename )
    local locked, pid, createLock;
    locked := false;
    pid := String( IO_getpid() );
    createLock := Concatenation(
        "set -o noclobber;",
        "echo ",
        pid,
        " > __lock_",
        filename
    );
    while not locked do
      locked := Exec2( createLock ) = 0;
      if not locked then
        Exec2( "sleep 1" );
      fi;
    od;
end;

prepareInfo := function( G, i, status, stats )
    local degree, onan, soc, mean, median, line;
    degree := NrMovedPoints(G);
    onan := ONanScottType(G);
    soc := StructureDescription(Socle(G));
    soc := Concatenation("\"", soc, "\"");
    if status = 0 then
        mean := threeSignificantDigits(stats[3]);
        median := threeSignificantDigits(stats[4]);
        line := List([i, degree, onan, soc, status, mean, median], String);
    elif status = 1 then
        # stats is the time in which one run finished
        line := List([i, degree, onan, soc, status, stats, "NA"], String);
    elif status = 2 then
        line := List([i, degree, onan, soc, status, "NA", "NA"], String);
    fi;
    line := JoinStringsWithSeparator(line);
    return line;
end;

BenchmarkCallForGroups := function(filename, func, groups, options...)
    local nrRuns, file, tracking, str, i, status, G, degree, onan, soc, line,
    res, t, benchmarkData, stats, mean, median, timeSingleRun;
    if not IsEmpty(options) then
        options := options[1];
        if IsBound(options.nrRuns) then
            nrRuns := options.nrRuns;
        else
            nrRuns := 30;
        fi;
    fi;
    file := OutputTextFile(filename, true);
    tracking := InputTextFile(Concatenation(filename, "_tracking"));

    ## Collect info about previous run
    str := Chomp(ReadAll(tracking));
    str := SplitString(str, ",");
    i := Int(str[1]);
    # status of the last run:
    # 0 - finished
    # 1 - finished one execution but not all
    # 2 - first execution did not terminate in time
    status := Int(str[2]);
    # if the last run did not finish properly, write info to filename
    if not status = 0 then
        G := groups[i];
        timeSingleRun := str[3];
        line := prepareInfo( G, i, status, timeSingleRun );
        AppendTo(filename, line);
        AppendTo(filename, "\n");
    fi;

    ## Write to tracking file: starting calculations for group i
    CloseStream(tracking);
    tracking := Concatenation(filename, "_tracking");
    i := i+1;
    G := groups[i];
    G := Group(GeneratorsOfGroup(G));
    PrintTo(tracking, Concatenation(String(i), ",2,NA"));

    res := GET_REAL_TIME_OF_FUNCTION_CALL(func, [G]);
    t := res.time;
    t := Round(t / 1000.);

    ## Write to tracking file: one calculation finished for group i
    PrintTo(tracking, Concatenation(String(i), ",1,", String(t)));

    ## Perform the proper benchmark
    benchmarkData := Benchmark(func, [G], rec(warmup := 0, times := nrRuns));

    ## Write info to file
    # Create lock so we don't get killed while finishing up
    createLockFile(filename);
    stats := benchmarkData.statistics;
    line := prepareInfo( G, i, 0, stats );
    AppendTo(filename, line);
    AppendTo(filename, "\n");
    ## Write to tracking file: finished for group i
    PrintTo(tracking, Concatenation(String(i), ",0"));
    Exec(Concatenation("rm __lock_", filename));
end;
