module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;


int main(int testArgument=0) {
    // smallsql0.21_src
    // hsqldb-2.3.1
    loc projectLocation = |home:///Documents/UVA_SE/SE/series0/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    // int volume = calculateVolume(asts);
    int volume = calculateVolumeWithoutComments(asts);
    map[str, int] unitSizes = calculateUnitSize(asts);

    println("Volume without comments: <volume>");
    
    // println("Total lines of code (volume): <volume>");
    // println("Unit sizes per method:");
    // for (methodName <- domain(unitSizes)) {
    //     println("  - <methodName>: <unitSizes[methodName]> lines");
    // }
    tuple[real percentage, int totalLines, int duplicateLines] duplicationResult = calculateDuplication(asts);
    println("Duplication percentage: <precision(duplicationResult.percentage, 2)>%");
    println("Total lines analyzed: <duplicationResult.totalLines>");
    println("Duplicate lines found: <duplicationResult.duplicateLines>");
    
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int calculateVolumeWithoutComments(list[Declaration] asts) {
    return (0 | it + size(cleanCode(readFileLines(types[0].src))) | 
        /\compilationUnit(_, list[Declaration] types) := asts) +
        (0 | it + size(cleanCode(readFileLines(types[0].src))) | 
        /\compilationUnit(_, _, list[Declaration] types) := asts);
}

map[str, int] calculateUnitSize(list[Declaration] asts) {
    map[str, int] methodSizes = ();
    
    visit(asts) {
        case \method(_, name, _, _, impl): {
            int linesOfCode = (impl.src.end.line - impl.src.begin.line) + 1;
            methodSizes[name] = linesOfCode;
        }
        case \constructor(name, _, _, impl): {
            int linesOfCode = (impl.src.end.line - impl.src.begin.line) + 1;
            methodSizes[name] = linesOfCode;
        }
    }
    
    return methodSizes;
}



str removeComments(str source) {
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

list[str] cleanCode(list[str] lines) {
    // First join lines and remove all comments
    str source = intercalate("\n", lines);
    source = removeComments(source);
    
    // Then split back into lines and clean
    return [trim(l) | l <- split("\n", source), trim(l) != ""];
}

// str removeComments(str source) {
//     // First remove all block comments (handles nested and multi-line)
//     source = visit(source) {
//         case /\/\*([^*]|\*+[^*\/])*\*+\// => ""
//     }
    
//     // Then handle single line comments and clean up
//     list[str] lines = split("\n", source);
//     list[str] cleanedLines = [];
    
//     for (str line <- lines) {
//         // Remove everything after // if it exists
//         if (/\/\// := line) {
//             line = substring(line, 0, findFirst(line, "//"));
//         }
        
//         // Only add non-empty lines
//         if (trim(line) != "") {
//             cleanedLines += trim(line);
//         }
//     }
    
//     return intercalate("\n", cleanedLines);
// }

// list[str] cleanCode(list[str] lines) {
//     // Skip empty input
//     if (size(lines) == 0) return [];
    
//     // Process the code
//     str source = intercalate("\n", lines);
//     source = removeComments(source);
//     return [trim(l) | l <- split("\n", source), trim(l) != ""];
// }

tuple[real percentage, int totalLines, int duplicateLines] calculateDuplication(list[Declaration] asts) {
    /*
    First pass: 
        - Sliding window algorithm
        - Map all 6-line blocks to their locations using a map
    Second pass:
        - Sort blocks by their first occurrence
        - Process blocks in order, marking duplicated lines
        - Use a set to ensure each line is only counted once
        This should handle overlapping duplicates (more accurately).
        For example, if lines 1-10 are duplicated somewhere else, 
        all those lines will be marked as duplicates only once, 
        even though they're part of multiple 6-line blocks.
    */
    // Get all source lines from ASTs
    list[str] allLines = [];
    // Process entire compilation units instead of individual methods
    visit(asts) {
        case \compilationUnit(_, list[Declaration] decls): {
            loc sourceFile = decls[0].src.top;
            allLines += cleanCode(readFileLines(sourceFile));
        }
        case \compilationUnit(_, _, list[Declaration] decls): {
            loc sourceFile = decls[0].src.top;
            allLines += cleanCode(readFileLines(sourceFile));
        }
    }
    // First pass: Store blocks and their locations
    map[str, list[int]] blockLocations = (); 
    int totalLines = size(allLines);
    println("Total lines: <totalLines>");
    
    // Map all 6-line blocks
    for (i <- [0..totalLines-5]) {
        str block = intercalate("\n", allLines[i..i+6]);
        blockLocations[block] = (block in blockLocations) ? blockLocations[block] + [i] : [i];
    }
    
    // Second pass: Track duplicated lines, handling overlaps
    set[int] duplicatedLineIndices = {};
    
    // Sort blocks by their first occurrence to handle overlaps properly
    list[tuple[str block, list[int] locations]] sortedBlocks = 
        sort([<block, locs> | block <- blockLocations, list[int] locs := blockLocations[block], size(locs) > 1],
             bool(tuple[str, list[int]] a, tuple[str, list[int]] b) { 
                 return min(a[1]) < min(b[1]); 
             });
    
    // Process blocks in order
    for (<block, locations> <- sortedBlocks) {
        for (startIndex <- locations) {
            set[int] newLines = {startIndex + k | k <- [0..6]};
            duplicatedLineIndices += newLines;
        }
    }
    
    int duplicateLines = size(duplicatedLineIndices);
    real percentage = totalLines > 0 ? (toReal(duplicateLines) / totalLines) * 100 : 0.0;
    return <percentage, totalLines, duplicateLines>;
}
