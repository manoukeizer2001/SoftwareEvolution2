module CloneDetection

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Map;
import Location;
import Node;

// Type alias for clone results
alias CloneResult = tuple[loc location1, loc location2];

// Step 1: Parse program and generate ASTs
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
}
// Step 2: Gather all subtrees into a map[node, list[loc]]
map[node, list[loc]] gatherSubtrees(list[Declaration] asts) {
    map[node, list[loc]] subtreeMap = ();

    for (Declaration ast <- asts) {
        visit(ast) {
            case node n: {
                // println("Visiting node: <getName(n)>");
                // println("Visiting node: <getName(n)> with source location: <n@src?>");
                if (n@src?) {
                    if (loc srcLoc := n@src) {
                        // println("Node <getName(n)> has source location: <srcLoc>");
                        node normalized = unsetRec(n);
                        if (normalized notin subtreeMap) {
                            subtreeMap[normalized] = [srcLoc];
                        } else {
                            subtreeMap[normalized] += srcLoc;
                        }
                    }
                }
            }
        }
    
    }

    // Optionally, filter to keep only subtrees that appear more than once
    // println("Subtree map: <subtreeMap>");
    // return (n : subtreeMap[n] | n <- subtreeMap, size(subtreeMap[n]) > 1);
    return subtreeMap;
}




// Step 3: Detect Clones by traversing ASTs
list[CloneResult] detectClones(list[Declaration] asts) {
    list[CloneResult] clones = [];
    
    println("Starting clone detection using gathered subtrees.");

    map[node, list[loc]] subtrees = gatherSubtrees(asts);
    println("Gathered <size(subtrees)> unique subtrees.");

    for(node n <- subtrees) {
        list[loc] locations = subtrees[n];
        if(size(locations) > 1) {
            println("Subtree <getName(n)> found in <size(locations)> locations.");
            for(i <- [0..size(locations)-1]) {
                for(j <- [i+1..size(locations)]) {
                    clones += <locations[i], locations[j]>;
                }
            }
        }
    }

    return clones;
}

// Example usage
