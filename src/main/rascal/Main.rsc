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
    
    int volume = calculateVolumeWithoutComments(asts);
    tuple[int, int, int, int, int, int, int, int] complexity = calculateComplexity(asts);
    
    tuple[real, real, real, real] complexity_dist = calculateComplexityDistribution(complexity, volume);
    
    println("Total lines of code excluding comments and empty lines: <volume>");
    println("Unit counts [low, moderate, high, very high]: \<<complexity[0]>, <complexity[1]>, <complexity[2]>, <complexity[3]>\>");
    println("Lines per category [low, moderate, high, very high]: \<<complexity[4]>, <complexity[5]>, <complexity[6]>, <complexity[7]>\>");
    println("Complexity distribution [low%, moderate%, high%, very high%]: \<<complexity_dist[0]>, <complexity_dist[1]>, <complexity_dist[2]>, <complexity_dist[3]>\>");
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

tuple[int, int, int, int, int, int, int, int] calculateComplexity(list[Declaration] asts) {
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
    
    visit(asts) {
        // Handle methods with implementation
        case m:\method(_, _, _, _, Statement impl): {
            int complexity = calculateMethodComplexity(impl);
            int methodSize = countMethodLines(m@src);
            categorizeUnit(complexity, methodSize);
        }
        
        // Handle interface methods (no implementation)
        case m:\method(_, _, _, _): {
            count_low += 1;
            lines_low += countMethodLines(m@src);
        }
        
        // Handle constructors
        case c:\constructor(_, _, _, Statement impl): {
            int complexity = calculateMethodComplexity(impl);
            int methodSize = countMethodLines(c@src);
            categorizeUnit(complexity, methodSize);
        }
        
        // Handle initializers (static and instance)
        case i:\initializer(Statement impl): {
            int complexity = calculateMethodComplexity(impl);
            int blockSize = countMethodLines(i@src);
            categorizeUnit(complexity, blockSize);
        }
    }
    
    return <count_low, count_moderate, count_high, count_veryHigh,
            lines_low, lines_moderate, lines_high, lines_veryHigh>;
}

int calculateMethodComplexity(Statement impl) {
    int complexity = 1;  // Base complexity is 1
    
    visit(impl) {
        // Count conditional statements
        case \if(_, _): complexity += 1;
        case \if(_, _, _): complexity += 1;
        case \case(_): complexity += 1;
        
        // Count exception handling
        case \try(_, list[Statement] catches): {
            // Each catch block represents a new path
            complexity += size(catches);
        }
        case \catch(_, _): complexity += 1;
        case \finally(_): complexity += 1;  // finally block adds another path
        
        // Count loops
        case \while(_, _): complexity += 1;
        case \for(_, _, _, _): complexity += 1;
        case \for(_, _, _): complexity += 1;
        case \foreach(_, _, _): complexity += 1;
        case \do(_, _): complexity += 1;
        
        // Count switch statements
        case \switch(_, list[Statement] statements): {
            // Each case in a switch creates a new path
            for (/\case(_) := statements) {
                complexity += 1;
            }
            // Default case also creates a new path
            for (/\defaultCase() := statements) {
                complexity += 1;
            }
        }
        
        // Count logical operations that create new paths
        case \infix(_, "&&", _): complexity += 1;
        case \infix(_, "||", _): complexity += 1;
    }
    
    return complexity;
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

str removeComments(str source) {
    // Remove multi-line comments
    source = visit(source) {
        case /\/\.?\*\//s => ""
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