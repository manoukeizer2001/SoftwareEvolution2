module CloneDetection

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;
import Node;

// Type alias for clone results
alias CloneResult = tuple[loc, list[int], loc, list[int]];

// Node representation with size information
data SerializedNode = serialNode(str nodeType, int subtreeSize, list[SerializedNode] children);

// Step 1: Parse program and generate AST
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
}

// Helper function to extract identifiers from nodes
str extractIdentifier(node n) {
    switch(n) {
        case \method(_, name, _, _, _): return "<name>";
        case \constructor(name, _, _, _): return "<name>";
        case \variable(name, _): return "<name>";
        case \variable(name, _, _): return "<name>";
        case \parameter(_, name, _): return "<name>";
        case \field(_, name): return "<name>";
        case \id(name): return "<name>";
        default: return "";
    }
}

// Modify serializeAst to include identifiers
SerializedNode serializeAst(node ast) {
    list[SerializedNode] result = [];
    
    visit(ast) {
        case node n: {
            if (n@src?) {
                // Extract identifier if present
                str nodeType = getName(n);
                str identifier = extractIdentifier(n);
                
                // Append identifier to nodeType if it exists
                if (identifier != "") {
                    nodeType += ":" + identifier;
                }
                
                // Count subtree size
                int subtreeSize = 0;
                visit(n) {
                    case node child: {
                        if (child@src?) {
                            subtreeSize += 1;
                        }
                    }
                }
                result += serialNode(nodeType, subtreeSize, []);
            }
        }
    }
    
    // Count total size for root
    int totalSize = 0;
    visit(ast) {
        case node n: {
            if (n@src?) {
                totalSize += 1;
            }
        }
    }
    
    return serialNode("root", totalSize, result);
}

bool areNodesEqual(SerializedNode a, SerializedNode b) {
    if (size(a.children) != size(b.children)) return false;
    
    for (i <- [0..size(a.children)]) {
        if (a.children[i].nodeType != b.children[i].nodeType ||
            a.children[i].size != b.children[i].size) {
            return false;
        }
    }
    return true;
}

set[tuple[loc, loc]] findType1Clones(list[Declaration] asts) {
    // Convert ASTs to serialized form
    list[SerializedNode] serializedAsts = [serializeAst(ast) | ast <- asts];
    set[tuple[loc, loc]] clones = {};
    
    // Extract methods from each AST
    list[SerializedNode] extractMethods(SerializedNode ast) {
        list[SerializedNode] methods = [];
        // Find all method nodes in the AST
        visit(ast) {
            case n:serialNode("method", _, children): {
                list[SerializedNode] methodBody = [c | c <- children, c.nodeType == "block"];
                methods += serialNode("method", 1, methodBody);
            }
        }
        return methods;
    }
    
    // Get all methods from all files
    list[SerializedNode] allMethods = [];
    for(ast <- serializedAsts) {
        allMethods += extractMethods(ast);
    }
    
    println("Found <size(allMethods)> methods to compare");
    
    // Compare method bodies
    for(i <- [0..size(allMethods)], j <- [i+1..size(allMethods)]) {
        SerializedNode method1 = allMethods[i];
        SerializedNode method2 = allMethods[j];
        
        // Compare the structure and operations
        bool areMethodsEqual = true;
        if(size(method1.children) == size(method2.children)) {
            for(k <- [0..size(method1.children)]) {
                if(method1.children[k].nodeType != method2.children[k].nodeType) {
                    areMethodsEqual = false;
                    break;
                }
            }
            if(areMethodsEqual) {
                clones += <|dummy:///method1|, |dummy:///method2|>;
                println("Found clone between methods!");
            }
        }
    }
    
    return clones;
}

// Helper function to flatten SerializedNode into string sequence
list[str] flattenTree(SerializedNode node1) {
    // Start with current node
    list[str] result = ["<node1.nodeType>(<node1.subtreeSize>)"];
    
    // Add all children's sequences
    for (child <- node1.children) {
        result += flattenTree(child);
    }
    
    return result;
}

// Suffix tree node with position tracking
data SuffixTreeNode = suffixNode(str label, map[str, SuffixTreeNode] children, map[loc, list[int]] positions);

// Build suffix tree and track positions
SuffixTreeNode addSuffix(SuffixTreeNode current, list[str] suffix, loc file, int pos, int minSize) {
    if (size(suffix) < minSize) return current;

    str first = suffix[0];
    println("Adding node with label: <first>");
    
    // Create a new map for positions and children to avoid mutation issues
    map[loc, list[int]] newPositions = current.positions;
    map[str, SuffixTreeNode] newChildren = current.children;
    
    // Update positions for current node
    if (file notin newPositions) {
        newPositions[file] = [pos];
    } else if (pos notin newPositions[file]) {
        newPositions[file] += [pos];
    }
    
    // Create new node if it doesn't exist
    if (first notin newChildren) {
        println("Creating new node for: <first>");
        newChildren[first] = suffixNode(first, (), ());
    }
    
    // Recursively process the rest of the suffix
    if (size(suffix) > 1) {
        println("Processing rest of suffix: <suffix[1..]>");
        newChildren[first] = addSuffix(newChildren[first], suffix[1..], file, pos + 1, minSize);
    }
    
    println("Returning node with children: <size(newChildren)>");
    return suffixNode(current.label, newChildren, newPositions);
}

// Find clones with minimum size requirement
list[CloneResult] findClones(SuffixTreeNode currentNode, int minSize) {
    list[CloneResult] clones = [];
    println("Current Node: <currentNode.label>");

    // Only consider nodes with positions in multiple files
    if (size(currentNode.positions) > 1) {
        list[loc] files = toList(domain(currentNode.positions));
        for (int i <- [0..size(files)-1]) {
            for (int j <- [i+1..size(files)]) {
                list[int] pos1 = currentNode.positions[files[i]];
                list[int] pos2 = currentNode.positions[files[j]];
                
                if (size(pos1) > 0 && size(pos2) > 0) {
                    clones += [<files[i], pos1, files[j], pos2>];
                }
            }
        }
    }
    
    // Recursively process children
    for (str key <- domain(currentNode.children)) {
        clones += findClones(currentNode.children[key], minSize);
    }
    
    return clones;
}


// Main clone detection function
list[CloneResult] detectClones(list[Declaration] asts) {
    int minCloneSize = 3;
    
    list[tuple[loc, list[str]]] serializedAsts = [];
    for (Declaration astNode <- asts) {
        if (astNode@src?) {
            SerializedNode serialized = serializeAst(astNode);
            list[str] flattened = flattenTree(serialized);
            serializedAsts += <astNode@src, flattened>;
        }
    }
    
    SuffixTreeNode root = suffixNode("", (), ());
    for (tuple[loc, list[str]] astInfo <- serializedAsts) {
        loc file = astInfo[0];
        list[str] sequence = astInfo[1];
        for (int i <- [0..size(sequence)-1]) {
            root = addSuffix(root, sequence[i..], file, i, minCloneSize);
        }
    }
    
    return findClones(root, minCloneSize);
}
