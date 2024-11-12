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
    loc projectLocation = |home:///Documents/se/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    // Calculate all metrics
    int volume = calculateVolumeWithoutComments(asts);
    map[str, int] unitSizes = calculateUnitSize(asts);
    tuple[real percentage, int totalLines, int duplicateLines] duplicationResult = calculateDuplication(asts);
    tuple[int, int, int, int, int, int, int, int] complexity = calculateComplexity(asts);
    tuple[real, real, real, real] complexity_dist = calculateComplexityDistribution(complexity, volume);
    
    // Calculate maintainability scores
    str analysabilityScore = calculateAnalysabilityScore(volume, complexity_dist, duplicationResult, unitSizes);
    str changeabilityScore = calculateChangeabilityScore(complexity_dist, duplicationResult);
    str testabilityScore = calculateTestabilityScore(complexity_dist, unitSizes);
    
    println("Analysability score:  <analysabilityScore>");
    println("Changeability score:  <changeabilityScore>");
    println("Testability score:    <testabilityScore>");
    
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

private int calculateMethodComplexity(Statement impl) {
    int complexity = 1;  // Base complexity
    
    visit(impl) {
        // Conditional statements
        case \if(_, _): complexity += 1;            // if without else
        case \if(_, _, _): complexity += 1;         // if-else
        case \switch(_,_): complexity += 1;         // switch statement itself
        case \case(_): complexity += 1;             // each case adds a path
        case \defaultCase(): complexity += 1;       // default case adds a path
        
        // Loops
        case \while(_, _): complexity += 1;         // while loop
        case \do(_, _): complexity += 1;            // do-while loop
        case \for(_, _, _, _): complexity += 1;     // for loop with condition
        case \for(_, _, _): complexity += 1;        // for loop without condition
        case \foreach(_, _, _): complexity += 1;    // foreach loop
        
        // Exception handling
        case \catch(_, _): complexity += 1;         // catch clause
        
        // Conditional expressions (usually in conditions)
        case \infix(_, "&&", _): complexity += 1;   // logical AND
        case \infix(_, "||", _): complexity += 1;   // logical OR
    }
    
    return complexity;
}
tuple[int, int, int, int, int, int, int, int] calculateComplexity(list[Declaration] asts) {
    // Risk categories: [count_low, count_moderate, count_high, count_veryHigh, 
    //                  lines_low, lines_moderate, lines_high, lines_veryHigh]
    int count_low = 0, count_moderate = 0, count_high = 0, count_veryHigh = 0;
    int lines_low = 0, lines_moderate = 0, lines_high = 0, lines_veryHigh = 0;
    
    void categorizeUnit(int complexity, int size) {
        // Categorize based on cyclomatic complexity thresholds from Heitlager2007
        if (complexity <= 15) { 
            count_low += 1; 
            lines_low += size; 
        }
        else if (complexity <= 30) { 
            count_moderate += 1; 
            lines_moderate += size; 
        }
        else if (complexity <= 60) { 
            count_high += 1; 
            lines_high += size; 
        }
        else { 
            count_veryHigh += 1; 
            lines_veryHigh += size; 
        }
    }

    visit(asts) {
        // Handle methods with implementation
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
            int complexity = calculateMethodComplexity(impl);
            int methodSize = countMethodLines(m@src);
            categorizeUnit(complexity, methodSize);
        }
        
        // Handle interface methods (no implementation)
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
            count_low += 1;
            lines_low += countMethodLines(m@src);
        }
    }
    
    return <count_low, count_moderate, count_high, count_veryHigh,
            lines_low, lines_moderate, lines_high, lines_veryHigh>;
}

int countMethodLines(loc methodLocation) {
    return size(cleanCode(readFileLines(methodLocation)));
}

tuple[real, real, real, real] calculateComplexityDistribution(tuple[int, int, int, int, int, int, int, int] unit_sizes, int totalLines) {
    // Extract lines per category from the tuple
    int lines_low = unit_sizes[4];
    int lines_moderate = unit_sizes[5];
    int lines_high = unit_sizes[6];
    int lines_veryHigh = unit_sizes[7];
    
    // Calculate percentages (handle division by zero)
    real percent_low = totalLines > 0 ? (lines_low * 100.0) / totalLines : 0.0;
    real percent_moderate = totalLines > 0 ? (lines_moderate * 100.0) / totalLines : 0.0;
    real percent_high = totalLines > 0 ? (lines_high * 100.0) / totalLines : 0.0;
    real percent_veryHigh = totalLines > 0 ? (lines_veryHigh * 100.0) / totalLines : 0.0;
    
    return <percent_low, percent_moderate, percent_high, percent_veryHigh>;
}
        
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

str calculateAnalysabilityScore(int volume, tuple[real, real, real, real] complexity_dist, 
    tuple[real percentage, int totalLines, int duplicateLines] duplication, map[str, int] unitSizes) {
    
    // Volume rating
    str volumeRating = rateVolume(volume);
    
    // Duplication rating
    str duplicationRating = rateDuplication(duplication.percentage);
    
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizes);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[volumeRating] + 
                    ratingToNum[duplicationRating] + 
                    ratingToNum[unitSizeRating]) / 3;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}

private str rateVolume(int volume) {
    if (volume < 66000) return "++";
    if (volume < 246000) return "+";
    if (volume < 665000) return "o";
    if (volume < 1310000) return "-";
    return "--";
}

private str rateDuplication(real percentage) {
    if (percentage <= 3) return "++";
    if (percentage <= 5) return "+";
    if (percentage <= 10) return "o";
    if (percentage <= 20) return "-";
    return "--";
}

private str rateUnitSize(map[str, int] unitSizes) {
    // Calculate total lines
    int totalLines = sum(range(unitSizes));
    if (totalLines == 0) return "++";  // Handle empty case
    
    // Calculate percentages for each risk category
    real veryHighRisk = 0.0;
    real highRisk = 0.0;
    real moderateRisk = 0.0;
    
    // Iterate over values directly
    for (int size <- range(unitSizes)) {
        if (size > 100) {
            veryHighRisk += (toReal(size) / totalLines) * 100;
        }
        else if (size > 50) {
            highRisk += (toReal(size) / totalLines) * 100;
        }
        else if (size > 20) {
            moderateRisk += (toReal(size) / totalLines) * 100;
        }
    }
    
    // Apply Heitlager's thresholds
    if (moderateRisk <= 25 && highRisk == 0 && veryHighRisk == 0) return "++";
    if (moderateRisk <= 30 && highRisk <= 5 && veryHighRisk == 0) return "+";
    if (moderateRisk <= 40 && highRisk <= 10 && veryHighRisk == 0) return "o";
    if (moderateRisk <= 50 && highRisk <= 15 && veryHighRisk <= 5) return "-";
    return "--";
}

private str rateComplexity(tuple[real, real, real, real] complexity_dist) {
    // Extract percentages [low, moderate, high, very high]
    real moderate = complexity_dist[1];
    real high = complexity_dist[2];
    real veryHigh = complexity_dist[3];
    
    // Apply Heitlager's thresholds
    if (moderate <= 25 && high == 0 && veryHigh == 0) return "++";
    if (moderate <= 30 && high <= 5 && veryHigh == 0) return "+";
    if (moderate <= 40 && high <= 10 && veryHigh == 0) return "o";
    if (moderate <= 50 && high <= 15 && veryHigh <= 5) return "-";
    return "--";
}

str calculateChangeabilityScore(tuple[real, real, real, real] complexity_dist,
    tuple[real percentage, int totalLines, int duplicateLines] duplication) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexity_dist);
    
    // Duplication rating
    str duplicationRating = rateDuplication(duplication.percentage);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[complexityRating] + 
                    ratingToNum[duplicationRating]) / 2;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}

str calculateTestabilityScore(tuple[real, real, real, real] complexity_dist,
    map[str, int] unitSizes) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexity_dist);
    
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizes);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[complexityRating] + 
                    ratingToNum[unitSizeRating]) / 2;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}
