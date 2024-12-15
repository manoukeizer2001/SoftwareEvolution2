module CloneDetection

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Map;
import Location;
import Node;
import DataTypes;

// At the top of the file with other constants
int MIN_SUBTREE_SIZE = 20;

// Step 1: Parse program and generate ASTs
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
}

// Step 2: Gather all subtrees into a map[str, list[loc]]
map[str, list[loc]] gatherSubtrees(list[Declaration] asts, int cloneType) {
    map[str, list[loc]] subtreeMap = ();

    for (Declaration ast <- asts) {
        visit(ast) {
            case node n: {
                if (n@src?) {
                    if (loc srcLoc := n@src) {
                        // println("Source location: <srcLoc>");
                        node normalized = unsetRec(n);
                        // println("Normalized node: <normalized>");
                        if (cloneType == 2) {
                            normalized = normalizeForType2(normalized); // Normalize for type-2 clones
                        }

                        int size = countNodes(normalized);
                        // println("Size of normalized node: <size>");
            
                        if (size >= MIN_SUBTREE_SIZE) {
                            str subtreeId = toString(normalized);
                            if (subtreeId notin subtreeMap) {
                                subtreeMap[subtreeId] = [srcLoc];
                            } else {
                                subtreeMap[subtreeId] += srcLoc;
                            }
                        }
                    }
                }
            }
        }
    }
    // println("Subtree map: <domain(subtreeMap)>");
    // Filter the map to only keep entries with more than one location
    return (key : subtreeMap[key] | key <- subtreeMap, size(subtreeMap[key]) > 1);
}


// Count the number of nodes in a subtree
int countNodes(node n) {
    int count = 0; // Initialize count

    visit(n) {
        case node _: {
            count += 1; // Count the current node
        }
    }

    return count;
}

node normalizeForType2(node n) {
    return visit(n) {
        // Normalize Types by converting them all to Type String
        case Type _ => string()

        // Normalize variable names
        case \variable(str _, Expression _) => 
            \variable("VAR", _)
        case \variable(str _, Expression _, int _) => 
            \variable("VAR", _, _)

        // Normalize literals
        case \number(_) => \number("CONST")
        case \booleanLiteral(_) => \booleanLiteral("CONST")
        case \stringLiteral(_, _) => \stringLiteral("CONST", "CONST")
        case \characterLiteral(_) => \characterLiteral("CONST")
        case \textBlock(_, _) => \textBlock("CONST", "CONST")

        // Default: Preserve other constructs
        // case _ => _
    }
}

map[str, list[loc]] filterContainedSubtrees(map[str, list[loc]] subtrees) {
    set[str] discard = {};

    // Iterate through every pattern
    for (str key1 <- subtrees) {
        if (key1 in discard) continue;

        list[loc] key1Locs = subtrees[key1];
        bool fullyContained = true;

        // Track which locations of key1 are covered by other patterns
        set[loc] coveredLocations = {};

        // Compare key1 against all other patterns
        for (str key2 <- subtrees) {
            if (key1 == key2 || key2 in discard) continue;

            list[loc] key2Locs = subtrees[key2];

            // Check if each location of key1 is contained in key2
            for (loc loc1 <- key1Locs) {
                if (loc1 in coveredLocations) continue; // Already covered

                for (loc loc2 <- key2Locs) {
                    if (isStrictlyContainedIn(loc1, loc2)) {
                        coveredLocations += loc1;
                        break;
                    }
                }
            }
        }

        // Check if all locations of key1 are covered by other patterns
        for (loc loc1 <- key1Locs) {
            if (loc1 notin coveredLocations) {
                fullyContained = false;
                break;
            }
        }

        // If all locations are covered, mark key1 for discard
        if (fullyContained) {
            discard += key1;
        }
    }

    // Rebuild the map without discarded patterns
    map[str, list[loc]] filtered = ();
    for (str k <- subtrees) {
        if (k notin discard) {
            filtered[k] = subtrees[k];
        }
    }

    return filtered;
}



// New function to build clone classes
list[CloneClass] buildCloneClasses(map[str, list[loc]] subtrees) {
    list[CloneClass] classes = [];
    
    // Each list of locations for a pattern becomes a clone class with its pattern
    for (str pattern <- subtrees) {
        list[loc] locations = subtrees[pattern];
        if (size(locations) > 1) {  // Only include if there are actual clones
            classes += [<pattern, locations>];
        }
    }
    
    return classes;
}

// New function to combine sequential subtrees
map[str, list[loc]] combineSequentialSubtrees(map[str, list[loc]] subtrees) {
    map[str, list[loc]] sequentialSubtrees = ();
    
    // For each pattern
    for (str pattern1 <- subtrees) {
        for (str pattern2 <- subtrees) {
            if (pattern1 == pattern2) continue;
            
            list[loc] locs1 = subtrees[pattern1];
            list[loc] locs2 = subtrees[pattern2];
            
            // Try to combine locations from both patterns
            list[loc] combinedLocs = [];
            
            for (loc loc1 <- locs1) {
                for (loc loc2 <- locs2) {
                    // Check for containment/overlap or if loc2 is sequential to loc1 in the same line
                    if (isContainedIn(loc1, loc2)) {
                        loc combinedLoc = cover([loc1, loc2]);
                        combinedLocs += combinedLoc;
                    }
                    // Check if loc2 is sequential to loc1 in the next adjacent line
                    loc expandedLoc1 = loc1;
                    expandedLoc1.end.line += 1;  // Extend loc1 by one line
                    expandedLoc1.end.column = 1000;  // Use a large column number to cover the whole next line

                    if (isContainedIn(loc2, expandedLoc1)) {
                        loc combinedLoc = cover([loc1, loc2]);
                        combinedLocs += combinedLoc;
                    }
                }
            }
            
            // If we found sequential locations, add them as a new pattern
            if (size(combinedLocs) > 1) {
                str combinedPattern = pattern1 + "+" + pattern2;
                sequentialSubtrees[combinedPattern] = combinedLocs;
            }
        }
    }
    
    // Filter to keep only entries with more than one location
    return (key : sequentialSubtrees[key] | key <- sequentialSubtrees, size(sequentialSubtrees[key]) > 1);
}

// Step 3: Detect Clones by traversing ASTs
public list[CloneClass] detectClones(list[Declaration] asts, int cloneType) {
    println("Starting clone detection of type <cloneType> using gathered subtrees.");

    map[str, list[loc]] subtrees = gatherSubtrees(asts, cloneType);
    println("Gathered <size(subtrees)> unique subtrees.");

    // Combine sequential subtrees
    map[str, list[loc]] sequentialSubtrees = combineSequentialSubtrees(subtrees);
    
    // Combine sequential subtrees and original subtrees
    map[str, list[loc]] combinedSubtrees = subtrees + sequentialSubtrees;

    println("After combining sequential subtrees: <size(combinedSubtrees)> patterns.");

    // Filter out smaller clones fully contained in larger ones
    map[str, list[loc]] filteredSubtrees = filterContainedSubtrees(combinedSubtrees);

    // Convert directly to clone classes
    list[CloneClass] cloneClasses = buildCloneClasses(filteredSubtrees);

    println("Detected <size(cloneClasses)> clone classes of type <cloneType>");
    return cloneClasses;
}

