module CloneDetection

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Map;
import Location;
import Node;
import DataExtraction;

// New type alias for clone classes
alias CloneClass = tuple[str pattern, list[loc] locations];

// Step 1: Parse program and generate ASTs
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
}

// Minimum subtree size in terms of nodes
int MIN_SUBTREE_SIZE = 4;

// Count the number of nodes in a subtree
int countNodes(node n) {
    int count = 1; // count this node
    for (node child <- n) {
        count += countNodes(child);
    }
    return count;
}

// Step 2: Gather all subtrees into a map[str, list[loc]]
// We now use str as the key, obtained by toString(normalized) of the node.
map[str, list[loc]] gatherSubtrees(list[Declaration] asts) {
    map[str, list[loc]] subtreeMap = ();

    for (Declaration ast <- asts) {
        visit(ast) {
            case node n: {
                if (n@src?) {
                    if (loc srcLoc := n@src) {
                        node normalized = unsetRec(n);
                        int size = countNodes(normalized);
                        // Only store if meets the minimum size requirement
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

    // Filter the map to only keep entries with more than one location
    return (key : subtreeMap[key] | key <- subtreeMap, size(subtreeMap[key]) > 1);
}

// Utility: get the length of a pattern by one of its occurrences
// int getLength(str key, map[str, list[loc]] nodes) {
//     list[loc] locs = nodes[key];
//     loc first = locs[0];
//     return first.end - first.begin;
// }

// Utility: get the length of a pattern by one of its occurrences
int getLength(str key, map[str, list[loc]] nodes) {
    list[loc] locs = nodes[key];
    loc first = locs[0];
    int length = first.end - first.begin; // works if first is offset-based
    return length;
}

// Check if all occurrences of 'smaller' are contained in some occurrences of 'larger'
bool isAlwaysContained(str smaller, str larger, map[str, list[loc]] nodes) {
    list[loc] smallerLocs = nodes[smaller];
    list[loc] largerLocs = nodes[larger];

    for (loc sLoc <- smallerLocs) {
        bool containedSomewhere = false;
        for (loc lLoc <- largerLocs) {
            if (isStrictlyContainedIn(sLoc, lLoc)) {
                containedSomewhere = true;
                break;
            }
        }
        if (!containedSomewhere) {
            return false; // Found a smaller occurrence not contained in 'larger'
        }
    }
    return true;
}

// Filter out subtree patterns that are strictly and exclusively contained within larger patterns
map[str, list[loc]] filterContainedSubtrees(map[str, list[loc]] subtrees) {
    // Sort patterns by size (descending)
    // println("Nodes: <domain(nodes)>");

    // println("Patterns:");
    list[str] patterns = [ k | k <- domain(subtrees) ];

    // patterns = sort(patterns, (str k1, str k2) {
    //     return getLength(k2, nodes) - getLength(k1, nodes);
    // });
    
    set[str] discard = {};
    
    // Compare each smaller pattern with larger ones
    for (i <- [0..size(patterns)-1]) {
        str largeKey = patterns[i];
        if (largeKey in discard) continue;

        for (j <- [i+1..size(patterns)-1]) {
            str smallKey = patterns[j];
            if (smallKey in discard) continue;
            
            // Check if smaller is always contained in the larger
            if (isAlwaysContained(smallKey, largeKey, subtrees)) {
                // Before discarding, check if smallKey appears somewhere outside largeKey
                bool appearsOutside = false;
                list[loc] smallerLocs = subtrees[smallKey];
                list[loc] largerLocs = subtrees[largeKey];

                // Check if there's an occurrence of smallKey not contained by largeKey
                for (loc sLoc <- smallerLocs) {
                    bool containedSomewhere = false;
                    for (loc lLoc <- largerLocs) {
                        if (isStrictlyContainedIn(sLoc, lLoc)) {
                            containedSomewhere = true;
                            break;
                        }
                    }
                    if (!containedSomewhere) {
                        appearsOutside = true;
                        break;
                    }
                }

                // If smaller never appears outside, discard it
                if (!appearsOutside) {
                    discard += smallKey;
                }
            }
        }
    }

    // Rebuild nodes without discarded ones
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

// Step 3: Detect Clones by traversing ASTs
public list[CloneClass] detectClones(list[Declaration] asts) {
    println("Starting clone detection using gathered subtrees.");

    map[str, list[loc]] subtrees = gatherSubtrees(asts);
    println("Gathered <size(subtrees)> unique subtrees.");

    // Filter out smaller clones fully contained in larger ones
    map[str, list[loc]] filteredSubtrees = filterContainedSubtrees(subtrees);

    // Convert directly to clone classes
    list[CloneClass] cloneClasses = buildCloneClasses(filteredSubtrees);

    println("Detected <size(cloneClasses)> clone classes:");
    // for (CloneClass cls <- cloneClasses) {
    //     println("\nClone Class:");
    //     println("  Pattern: <cls.pattern>");
    //     println("  Locations:");
    //     for (loc location <- cls.locations) {
    //         println("    - <location>");
    //     }
    // }

    return cloneClasses;
}


