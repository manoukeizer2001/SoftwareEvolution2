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

SerializedNode serializeAst(node ast) {
    // println("Serializing AST node: <ast>");
    switch(ast) {
        // Generic handling for all Declaration types
        
        case Declaration d: {
            str nodeType = getName(d);
            int childCount = 1;  // Base count for the node itself
            list[SerializedNode] children = [];
            
            // Get all child nodes that can be serialized
            for (child <- getChildren(d)) {
                if (Declaration _ := child || Expression _ := child || Statement _ := child || Type _ := child) {
                    children += serializeAst(child);
                    childCount += 1;
                }
            }
            
            
            return serialNode(nodeType, childCount, children);
        }
        
        // Handle Expression nodes
        case Expression e: {
            str nodeType = getName(e);
            int childCount = 1; // Base count for the node itself
            list[SerializedNode] children = [];
            
            // Serialize all relevant child nodes
            for (child <- getChildren(e)) {
                if (Declaration _ := child || Expression _ := child || Statement _ := child || Type _ := child) {
                    children += serializeAst(child);
                    childCount += 1;
                }
            }
            
            return serialNode(nodeType, childCount, children);
        }
        
        // Handle Statement nodes
        case Statement s: {
            str nodeType = getName(s);
            int childCount = 1; // Base count for the node itself
            list[SerializedNode] children = [];
            
            // Serialize all relevant child nodes
            for (child <- getChildren(s)) {
                if (Declaration _ := child || Expression _ := child || Statement _ := child || Type _ := child) {
                    children += serializeAst(child);
                    childCount += 1;
                }
            }
            
            return serialNode(nodeType, childCount, children);
        }
        
        // case Type t: {
        //     return serialNode(getName(t), 1, []);
        // }
        
        default: {
            return serialNode(getName(ast), 1, []);
        }
    }
}

// SerializedNode serializeAst(list[Declaration] asts) {
//     list[SerializedNode] serializedNodes = [];
    
//     visit(asts) {
//         // Handle Method Declarations
//         case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
//             println("Visiting method: <name>");
//             list[SerializedNode] methodChildren = [];
            
//             // Serialize parameters
//             for (param <- parameters) {
//                 methodChildren += serializeAst(param);
//             }
            
//             // Serialize method implementation
//             if (impl != null) {
//                 methodChildren += serializeAst(impl);
//             }
            
//             serializedNodes += serialNode("method", size(methodChildren) + 1, methodChildren);
//         }
        
//         // Handle Class Declarations
//         case c:\class(list[Modifier] modifiers, str name, list[Declaration] typeParameters, list[Type] extends, list[Type] implements, list[Declaration] body): {
//             println("Visiting class: <name>");
//             list[SerializedNode] classChildren = [];
            
//             // Serialize class body
//             for (decl <- body) {
//                 classChildren += serializeAst(decl);
//             }
            
//             serializedNodes += serialNode("class", size(classChildren) + 1, classChildren);
//         }
//     }
    
//     // Combine everything under a "compilationUnit" root
//     return serialNode("compilationUnit", size(serializedNodes) + 1, serializedNodes);
// }



/* Uncomment for normalization if needed in the future
str normalizeNodeType(str nodeType) {
    switch(nodeType) {
        case "Identifier": return "id"; // Normalize identifiers to "id"
        case "Literal": return "const"; // Normalize literals to "const"
        default: return nodeType; // Keep other node types as-is
    }
}
*/

str normalizeNodeType(str nodeType) {
    switch(nodeType) {
        case "Identifier": return "id"; // Normalize identifiers
        case "Literal": return "const"; // Normalize literals
        case "Method": return "method"; // Normalize method names
        case "Class": return "class"; // Normalize class names
        default: return nodeType; // Keep other node types as-is
    }
}


// Helper function to flatten SerializedNode into string sequence
list[str] flattenTree(SerializedNode serializedNode) {
    return ["<serializedNode.nodeType>(<serializedNode.subtreeSize>)"] + 
           [s | child <- serializedNode.children, s <- flattenTree(child)];
}

// Suffix tree node with position tracking
data SuffixTreeNode = suffixNode(str label, map[str, SuffixTreeNode] children, map[loc, list[int]] positions);

// Build suffix tree and track positions
void addSuffix(SuffixTreeNode current, list[str] suffix, loc file, int pos, int minSize) {
    if (size(suffix) < minSize) return; // Skip short sequences
    
    str first = suffix[0];
    if (first notin current.children) {
        current.children[first] = suffixNode(first, (), ());
    }
    
    if (file notin current.children[first].positions) {
        current.children[first].positions[file] = [];
    }
    current.children[first].positions[file] += [pos];
    
    if (size(suffix) > 1) {
        addSuffix(current.children[first], suffix[1..], file, pos + 1, minSize);
    }
}

// Find clones with minimum size requirement
list[CloneResult] findClones(SuffixTreeNode currentNode, int minSize) {
    list[CloneResult] clones = [];
    
    // Only consider nodes with positions in multiple files
    if (size(currentNode.positions) > 1) {
        list[loc] files = [f | f <- keys(currentNode.positions)];
        for (int i <- [0..size(files)-1]) {
            for (int j <- [i+1..size(files)-1]) {
                list[int] pos1 = currentNode.positions[files[i]];
                list[int] pos2 = currentNode.positions[files[j]];
                
                if (size(pos1) > 0 && size(pos2) > 0) {
                    clones += [<files[i], pos1, files[j], pos2>];
                }
            }
        }
    }
    
    // Recursively process children
    for (str key <- currentNode.children) {
        clones += findClones(currentNode.children[key], minSize);
    }
    
    return clones;
}


// Main clone detection function
list[CloneResult] detectClones(list[Declaration] asts) {
    int minCloneSize = 3; // Minimum size of clone (adjustable)
    
    list[tuple[loc, list[str]]] serializedAsts = [];
    for (Declaration astNode <- asts) {
        if (astNode@src?) {
            SerializedNode serialized = serializeAst(astNode);
            println("Serialized Node: <serialized>");
            list[str] flattened = flattenTree(serialized);
            serializedAsts += <astNode@src, flattened>;
        }
    }
    
    SuffixTreeNode root = suffixNode("", (), ());
    for (tuple[loc, list[str]] astInfo <- serializedAsts) {
        loc file = astInfo[0];
        list[str] sequence = astInfo[1];
        for (int i <- [0..size(sequence)-1]) {
            addSuffix(root, sequence[i..], file, i, minCloneSize);
        }
    }
    
    return findClones(root, minCloneSize);
}

// Example usage
void main(loc projectLocation) {
    list[Declaration] asts = getASTs(projectLocation);
    list[CloneResult] clones = detectClones(asts);
    
    println("Detected Clones:");
    for (CloneResult clone <- clones) {
        println("<clone>");
    }
}
