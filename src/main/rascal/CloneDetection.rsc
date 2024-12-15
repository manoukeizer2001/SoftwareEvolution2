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
    
    // Group by file
    map[str, list[tuple[str pattern, loc location]]] fileGroups = ();
    for (str pattern <- subtrees) {
        for (loc location <- subtrees[pattern]) {
            if (location.uri notin fileGroups) {
                fileGroups[location.uri] = [];
            }
            fileGroups[location.uri] += [<pattern, location>];
        }
    }
    
    // Process each file - single pass
    for (str file <- fileGroups) {
        // Sort locations by start line
        list[tuple[str pattern, loc location]] sortedLocs = 
            sort(fileGroups[file], bool(tuple[str,loc] a, tuple[str,loc] b) {
                return a[1].begin.line < b[1].begin.line;
            });
        
        // Try to combine sequences
        int i = 0;
        while (i < size(sortedLocs)) {
            int j = i + 1;
            list[tuple[str pattern, loc location]] currentSequence = [sortedLocs[i]];
            
            // Try to extend the sequence as much as possible in one go
            while (j < size(sortedLocs) && 
                   !isContainedIn(sortedLocs[j-1][1], sortedLocs[j][1]) &&
                   !isContainedIn(sortedLocs[j][1], sortedLocs[j-1][1]) &&
                   isNearby(sortedLocs[j][1], sortedLocs[j-1][1], 2)) {
                currentSequence += sortedLocs[j];
                j += 1;
            }
            
            // If we found a sequence longer than 1, create a new combination
            if (size(currentSequence) > 1) {
                str combinedPattern = intercalate("+", [s[0] | s <- currentSequence]);
                loc combinedLoc = cover([s[1] | s <- currentSequence]);
                
                if (combinedPattern notin sequentialSubtrees) {
                    sequentialSubtrees[combinedPattern] = [];
                }
                sequentialSubtrees[combinedPattern] += combinedLoc;
            }
            
            i = j;
        }
    }
    
    return (key : sequentialSubtrees[key] | key <- sequentialSubtrees, 
            size(sequentialSubtrees[key]) > 1);
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
    // map[str, list[loc]] filteredSubtrees = filterContainedSubtrees(subtrees);

    // Convert directly to clone classes
    list[CloneClass] cloneClasses = buildCloneClasses(filteredSubtrees);

    println("Detected <size(cloneClasses)> clone classes of type <cloneType>");
    return cloneClasses;
}

bool isNearby(loc loc2, loc loc1, int gap) {
    // Check if locations are in the same file
    if (loc2.uri != loc1.uri) return false;
    
    // Get end line of first location and start line of second
    int loc1EndLine = loc1.end.line;
    int loc2StartLine = loc2.begin.line;
    
    // Check if they're within the acceptable gap
    return (loc2StartLine - loc1EndLine) <= gap;
}

