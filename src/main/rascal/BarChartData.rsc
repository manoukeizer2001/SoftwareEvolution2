module BarChartData

import List;
import Map;
import IO;
import lang::java::m3::AST;
import DataTypes;

public map[int, int] calculateCloneSizeFrequencies(list[CloneClassWithId] cloneClassesWithIds) {
    map[int, int] frequencies = ();
    
    int count = 0;
    for (CloneClassWithId cls <- cloneClassesWithIds) {
        count += 1;
        // println("Debug: Number of locations: <size(cls.locations)>");
        
        if (!isEmpty(cls.locations)) {
            loc firstLoc = cls.locations[0];
            // println("Debug: First location: <firstLoc>");
            
            int lineCount = firstLoc.end.line - firstLoc.begin.line + 1;
            // println("Debug: Line count: <lineCount>");
            
            frequencies[lineCount] = (lineCount in frequencies) ? frequencies[lineCount] + 1 : 1;
            // println("Debug: Updated frequencies for line count <lineCount>: <frequencies[lineCount]>");
        }
    }
    
    // println("Debug: Final frequencies map: <frequencies>");
    return frequencies;
}
