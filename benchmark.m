createLockFile := function( filename )
    locked := false;
    pid := IntegerToString( Getpid() );
    createLock := "set -o noclobber;" cat "echo " cat pid
        cat " > __lock_" cat filename;
    while not locked do
      locked := System( createLock ) eq 0;
      if not locked then
        System( "sleep 1" );
      end if;
    end while;
    return 0;
end function;

createPrimitives := function(i)
    k := 0;
    d := 1;
    while k + NumberOfPrimitiveGroups(d) lt i do
        k := k + NumberOfPrimitiveGroups(d);
        d := d + 1;
    end while;
    prims := PrimitiveGroups(d);
    return prims, i - k;
end function;

BenchmarkCallForGroups := function(filename, func)
    SimpleGroupName2 := function(x)
        done := false;
        while not done do
            done, res := SimpleGroupName(x);
        end while;
        return res[1];
    end function;

    prepareInfo := function(x, i, status, stats)
        degree := Degree(x);
        onan := _ONanScottType(x);
        if onan ne "1" then
            soc := [ SimpleGroupName2(g) : g in SocleFactors(x) ];
            soc := "\"" cat &cat [ Sprint(x) cat " x " : x in soc ];
            soc := ElementToSequence(soc);
            soc := Remove( soc, #soc );
            soc := Remove( soc, #soc );
            soc := Remove( soc, #soc );
            soc := &cat soc cat "\"";
        else
            soc := "\"Aff:" cat Sprint(Degree(x)) cat "\"";
        end if;
        status := -1 * status;
        if status eq 0 then
            mean := threeSignificantDigits(stats[3]);
            median := threeSignificantDigits(stats[4]);
            upperQuart := threeSignificantDigits(stats[5]);
            max := threeSignificantDigits(stats[6]);
            line := <i, degree, onan, soc, mean, median, upperQuart, max>;
        elif status eq -1 then
            // stats contains the time in which one run finished
            line := <i, degree, onan, soc, status, stats, status, status>;
        else
            line := <i, degree, onan, soc, status, status, status, status>;
        end if;
        line := &cat [ Sprint(x) cat "," : x in line ];
        line := ElementToSequence(line);
        line := Remove( line, #line );
        line := &cat line;
        return line;
    end function;

    trackingFile := filename cat "_tracking";
    file := Open( trackingFile, "r" );
    info := Gets( file );  // first line of file as a string
    info := eval( info );
    i := info[1];
    groups, j := createPrimitives(i);

    // Collect info about previous run
    // status of the last run:
    // 0 - finished
    // 1 - finished one execution but not all
    // 2 - first execution did not terminate in time
    status := info[2];
    // if the last run did not finish properly, write info to filename
    if not status eq 0 then
        G := groups[j];
        line := prepareInfo(G, i, status, info[3]);
        PrintFile(filename, line);
    end if;

    // Write to tracking file: starting calculations for group i
    delete file; // close the file again
    i := i+1;
    groups, j := createPrimitives(i);
    G := groups[j];
    PrintFile(trackingFile, [i,2,0] : Overwrite := true);

    t := GET_REAL_TIME_OF_FUNCTION_CALL(func, [G]);

    // Write to tracking file: one calculation finished for group i
    PrintFile(trackingFile, [i,1,t] : Overwrite := true);

    // Perform the proper benchmark
    stats := Benchmark(func, [G] : warmup := 3, times := 200);
    print i, stats;

    // Write info to file
    // Create lock so we don't get killed while finishing up
    tmp := createLockFile(filename);
    line := prepareInfo(G, i, 0, stats);
    PrintFile(filename, line);
    //  Write to tracking file: finished for group i
    PrintFile(trackingFile, [i,0,0] : Overwrite := true);
    System("rm __lock_" cat filename);

    return 0;
end function;
