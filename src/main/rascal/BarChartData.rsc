module BarChartData

import CloneDetection;
import List;
import Map;
import IO;
import lang::java::m3::AST;

public alias BarChartData = map[int, int];

public map[int, int] calculateCloneSizeFrequencies(list[CloneClass] cloneClasses) {
    println("Debug: Starting calculateCloneSizeFrequencies");
    println("Debug: Number of clone classes: <size(cloneClasses)>");
    
    map[int, int] frequencies = ();
    
    int count = 0;
    for (CloneClass cls <- cloneClasses) {
        count += 1;
        println("Debug: Processing clone class <count>");
        println("Debug: Number of locations: <size(cls.locations)>");
        
        if (!isEmpty(cls.locations)) {
            loc firstLoc = cls.locations[0];
            println("Debug: First location: <firstLoc>");
            
            int lineCount = firstLoc.end.line - firstLoc.begin.line + 1;
            println("Debug: Line count: <lineCount>");
            
            frequencies[lineCount] = (lineCount in frequencies) ? frequencies[lineCount] + 1 : 1;
            println("Debug: Updated frequencies for line count <lineCount>: <frequencies[lineCount]>");
        }
    }
    
    println("Debug: Final frequencies map: <frequencies>");
    return frequencies;
}