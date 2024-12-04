module BasicMetricsCalculation

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

// list[Declaration] getDeclarationTypeASTs(list[Declaration] asts) {
//     list[Declaration] declarations = [];
//     visit(asts) {
//         case d: Declaration => declarations += [d];
//     }
//     return declarations;
// }

// list[Expression] getExpressionASTs(list[Declaration] asts) {
//     list[Expression] expressions = [];
//     visit(asts) {
//         case e: Expression => expressions += [e];
//     }
//     return expressions;
// }

// list[Statement] getStatementASTs(list[Declaration] asts) {
//     list[Statement] statements = [];
//     visit(asts) {
//         case s: Statement => statements += [s];
//     }
//     return statements;
// }

// Simple method to get volume
int calculateVolumeWithoutComments(list[str] allLines) {
    return size(allLines);
}

// Reusable method to get clean lines from AST
list[str] getAllLines(list[Declaration] asts) {
    list[str] allLines = [];
    visit(asts) {
        // Visit each compilation unit (each .java file)
        case \compilationUnit(_, list[Declaration] decls): {
            loc sourceFile = decls[0].src.top;
            allLines += cleanCode(readFileLines(sourceFile));
        }
        case \compilationUnit(_, _, list[Declaration] decls): {
            loc sourceFile = decls[0].src.top;
            allLines += cleanCode(readFileLines(sourceFile));
        }
    }
    return allLines;
}

// Calculate size of each unit (method)
map[str, int] calculateUnitSize(list[Declaration] asts) {
    map[str, int] methodSizes = ();
    int overloadCount = 0;
    
    visit(asts) {
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
            list[str] methodLines = cleanCode(readFileLines(m@src));
            // Add unique identifier for overloaded methods
            str uniqueName = name;
            if (uniqueName in methodSizes) {
                uniqueName = name + "_" + toString(overloadCount);
                overloadCount += 1;
            }
            methodSizes[uniqueName] = size(methodLines);
        }
        
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
            list[str] methodLines = cleanCode(readFileLines(m@src));
            // Add unique identifier for overloaded methods
            str uniqueName = name;
            if (uniqueName in methodSizes) {
                uniqueName = name + "_" + toString(overloadCount);
                overloadCount += 1;
            }
            methodSizes[uniqueName] = size(methodLines);
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

// Calculate unit counts and lines per risk category for unit sizes
tuple[int count_low, int count_moderate, int count_high, int count_veryHigh,
      int lines_low, int lines_moderate, int lines_high, int lines_veryHigh] 
calculateUnitSizeDistribution(map[str, int] unitSizes) {
    int count_low = 0, count_moderate = 0, count_high = 0, count_veryHigh = 0;
    int lines_low = 0, lines_moderate = 0, lines_high = 0, lines_veryHigh = 0;
    
    // Categorize each unit and sum up lines
    for (methodName <- unitSizes) {
        int size = unitSizes[methodName];
        if (size <= 15) {
            count_low += 1;
            lines_low += size;
        }
        else if (size <= 30) {
            count_moderate += 1;
            lines_moderate += size;
        }
        else if (size <= 60) {
            count_high += 1;
            lines_high += size;
        }
        else {
            count_veryHigh += 1;
            lines_veryHigh += size;
        }
    }
    
    return <count_low, count_moderate, count_high, count_veryHigh,
            lines_low, lines_moderate, lines_high, lines_veryHigh>;
}

// Calculate percentage distribution
tuple[real, real, real, real] calculateUnitSizePercentages(tuple[int, int, int, int, int, int, int, int] unit_sizes, int totalLines) {
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

// Calculate number of units for each complexity risk category
tuple[int, int, int, int, int, int, int, int] calculateComplexityDistribution(list[Declaration] asts) {
    // Risk categories: [count_low, count_moderate, count_high, count_veryHigh, 
    //                  lines_low, lines_moderate, lines_high, lines_veryHigh]
    int count_low = 0, count_moderate = 0, count_high = 0, count_veryHigh = 0;
    int lines_low = 0, lines_moderate = 0, lines_high = 0, lines_veryHigh = 0;
    
    void categorizeUnit(int complexity, int size) {
        // Categorize based on cyclomatic complexity thresholds from Heitlager2007
        if (complexity <= 10) { 
            count_low += 1; 
            lines_low += size; 
        }
        else if (complexity <= 20) { 
            count_moderate += 1; 
            lines_moderate += size; 
        }
        else if (complexity <= 50) { 
            count_high += 1; 
            lines_high += size; 
        }
        else { 
            count_veryHigh += 1; 
            lines_veryHigh += size; 
        }
    }

    // visit(asts) {
    //     // Handle methods with implementation
    //     case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
    //         int complexity = calculateMethodComplexity(impl);
    //         int methodSize = countMethodLines(m@src);
    //         categorizeUnit(complexity, methodSize);
    //     }
        
    //     // Handle interface methods (no implementation)
    //     case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
    //         count_low += 1;
    //         lines_low += countMethodLines(m@src);
    //     }   
    // }

    visit(asts) {
        // Handle methods with implementation
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
            int complexity = calculateMethodComplexity(impl);
            list[str] methodLines = cleanCode(readFileLines(m@src));
            int methodSize = size(methodLines);
            categorizeUnit(complexity, methodSize);
        }
        
        // Handle interface methods (no implementation)
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
            list[str] methodLines = cleanCode(readFileLines(m@src));
            int methodSize = size(methodLines);
            count_low += 1;
            lines_low += methodSize;
        }   
    }
    
    return <count_low, count_moderate, count_high, count_veryHigh,
            lines_low, lines_moderate, lines_high, lines_veryHigh>;
}

int countMethodLines(loc methodLocation) {
    return size(cleanCode(readFileLines(methodLocation)));
}

tuple[real, real, real, real] calculateComplexityPercentages(tuple[int, int, int, int, int, int, int, int] unit_sizes, int totalLines) {
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
        
tuple[real percentage, int totalLines, int duplicateLines] calculateDuplication(list[str] allLines) {
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

    // First pass: Store blocks and their locations
    map[str, list[int]] blockLocations = (); 
    int totalLines = size(allLines);
    // println("Total lines: <totalLines>");
    
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
