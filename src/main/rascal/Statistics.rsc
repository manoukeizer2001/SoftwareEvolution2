module Statistics

import CloneDetection;
import List;
import Map;
import IO;
import lang::java::m3::AST;
import Set;
import String;

// Simplified statistics type focusing on the required metrics
alias CloneStats = tuple[
    real duplicatedLinesPercentage,  // Duplicated Lines percentage
    int numberOfClones,              // Total number of clone instances
    int numberOfCloneClasses,        // Number of clone classes
    int biggestCloneSize,            // Size of the biggest clone (in lines)
    int biggestCloneClassSize        // Size of the biggest clone class (number of members)
];

// Calculate all statistics in one go
public CloneStats calculateStatistics(list[CloneClass] cloneClasses, list[Declaration] asts) {
    // Calculate total source lines
    println("Calculating total amount of source lines - might take a while");
    int totalSourceLines = calculateTotalSourceLines(asts);
    
    // Calculate duplicated lines
    println("Calculating total amount of duplicated lines and percentage");
    int totalDuplicatedLines = calculateTotalDuplicatedLines(cloneClasses);
    real duplicatedPercentage = (totalSourceLines > 0) ? (totalDuplicatedLines * 100.0) / totalSourceLines : 0.0;
    
    // Calculate other metrics
    println("Calculating total amount of clones");
    int numberOfClones = calculateTotalClones(cloneClasses);
    println("Calculating total amount of clone classes");
    int numberOfCloneClasses = size(cloneClasses);
    println("Calculating size of the biggest clone");
    int biggestCloneSize = calculateBiggestCloneSize(cloneClasses);
    println("Calculating size of the biggest clone class");
    int biggestCloneClassSize = calculateBiggestCloneClassSize(cloneClasses);
    
    return <
        duplicatedPercentage,
        numberOfClones,
        numberOfCloneClasses,
        biggestCloneSize,
        biggestCloneClassSize
    >;
}

private int calculateTotalSourceLines(list[Declaration] asts) {
    int total = 0;
    for (Declaration ast <- asts) {
        if (ast@src?) {
            loc file = ast@src.top;
            // Remove comments and empty lines
            list[str] lines = cleanCode(readFileLines(file));
            total += size(lines);
        }
    }
    println("Total amount of source lines: <total>");
    return total;
}

private int calculateTotalDuplicatedLines(list[CloneClass] cloneClasses) {
    int total = 0;
    for (CloneClass cls <- cloneClasses) {
        for (loc location <- cls.locations) {
            total += location.end.line - location.begin.line + 1;
        }
    }
    return total;
}

private int calculateTotalClones(list[CloneClass] cloneClasses) {
    int total = 0;
    for (CloneClass cls <- cloneClasses) {
        total += size(cls.locations);
    }
    return total;
}

private int calculateBiggestCloneSize(list[CloneClass] cloneClasses) {
    if (isEmpty(cloneClasses)) return 0;
    
    int biggest = 0;
    for (CloneClass cls <- cloneClasses) {
        for (loc location <- cls.locations) {
            int currentSize = location.end.line - location.begin.line + 1;
            if (currentSize > biggest) {
                biggest = currentSize;
            }
        }
    }
    return biggest;
}

private int calculateBiggestCloneClassSize(list[CloneClass] cloneClasses) {
    if (isEmpty(cloneClasses)) return 0;
    
    int biggest = 0;
    for (CloneClass cls <- cloneClasses) {
        int currentSize = size(cls.locations);
        if (currentSize > biggest) {
            biggest = currentSize;
        }
    }
    return biggest;
}

public str removeComments(str source) {
    // Remove multi-line comments
    source = visit(source) {
        case /\/\*.*?\*\//s => ""
    }
    // Remove single-line comments
    source = visit(source) {
        case /\/\/.*$/ => ""
    }
    return source;
}

public list[str] cleanCode(list[str] lines) {
    // First join lines and remove all comments
    str source = intercalate("\n", lines);
    source = removeComments(source);
    
    // Then split back into lines and clean
    return [trim(l) | l <- split("\n", source), trim(l) != ""];
}