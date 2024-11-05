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
    
    int volume_with_comments = calculateVolumeWithComments(asts);
    int volume_without_comments = calculateVolumeWithoutComments(asts);
    
    println("Total lines of code (volume_without_comments): <volume_without_comments>");
    println("Total lines of code (volume_with_comments): <volume_with_comments>");
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int calculateVolumeWithComments(list[Declaration] asts) {
    int totalLinesOfCode = 0;
    
    visit(asts) {
        case \compilationUnit(_, list[Declaration] types): {
            list[str] lines = readFileLines(types[0].src);
            // Count non-empty lines
            totalLinesOfCode += size([l | l <- lines, trim(l) != ""]);
        }
        case \compilationUnit(_, _, list[Declaration] types): {
            list[str] lines = readFileLines(types[0].src);
            // Count non-empty lines
            totalLinesOfCode += size([l | l <- lines, trim(l) != ""]);
        }
    }
    
    return totalLinesOfCode;
}

int calculateVolumeWithoutComments(list[Declaration] asts) {
    int countNonCommentLines(list[str] lines) {
        int count = 0;
        bool inMultiLineComment = false;
        
        for (str line <- lines) {
            str trimmedLine = trim(line);
            if (trimmedLine == "") continue;
            
            if (startsWith(trimmedLine, "/*")) { inMultiLineComment = true; continue; }
            if (endsWith(trimmedLine, "*/")) { inMultiLineComment = false; continue; }
            if (inMultiLineComment || startsWith(trimmedLine, "//")) continue;
            
            count += 1;
        }
        return count;
    }
    
    return (0 | it + countNonCommentLines(readFileLines(types[0].src)) | 
        /\compilationUnit(_, list[Declaration] types) := asts) +
        (0 | it + countNonCommentLines(readFileLines(types[0].src)) | 
        /\compilationUnit(_, _, list[Declaration] types) := asts);
}