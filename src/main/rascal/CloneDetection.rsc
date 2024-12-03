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

// Type alias for clone results
alias CloneResult = tuple[loc, list[int], loc, list[int]];

// Step 1: Parse program and generate AST (already handled by M3)
list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    return [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
}

// Step 2: Serialize AST
// "We serialize the AST by a preorder traversal. For each visited AST node N, 
// we emit N as root and associate the number of arguments with it"
list[str] serializeAst(Declaration ast) {
    list[str] serialized = [];
    
    visit(ast) {
        case \class(str name, _, list[Declaration] body, _): {
            serialized += ["class<size(body)>"];
            // Continue with body nodes through visit
        }
        case \method(_, str name, _, _, list[Statement] body): {
            serialized += ["method<size(body)>"];
            // Continue with body nodes through visit
        }
        case \if(Expression condition, Statement thenBranch): {
            serialized += ["if2"];  // 2 arguments: condition and then
        }
        case \if(Expression condition, Statement thenBranch, Statement elseBranch): {
            serialized += ["if3"];  // 3 arguments: condition, then, else
        }
        case \block(list[Statement] statements): {
            serialized += ["block<size(statements)>"];
        }
        case \variable(str name, _): {
            serialized += ["var0"];  // Leaf node, 0 arguments
        }
        case \variable(str name, _, Expression init): {
            serialized += ["var1"];  // 1 argument: initializer
        }
    }
    
    return serialized;
}

// Step 3: Apply suffix tree detection
// Data structure for Suffix Tree Nodes
data SuffixTreeNode = suffixNode(str label, map[str, SuffixTreeNode] children, map[loc, list[int]] positions);

// Function to detect clones using suffix tree
list[CloneResult] detectClones(list[Declaration] asts) {
    // First serialize all ASTs
    list[tuple[loc, list[str]]] serializedAsts = [<ast@src, serializeAst(ast)> | ast <- asts];
    
    // Build suffix tree
    SuffixTreeNode root = suffixNode("", (), ());
    for (tuple[loc, list[str]] astInfo <- serializedAsts) {
        loc l = astInfo[0];
        list[str] sequence = astInfo[1];
        for (int i <- [0..size(sequence)-1]) {  // Corrected loop range
            addSuffix(root, sequence[i..], l, i);
        }
    }
    
    return findClones(root);
}

// Helper functions for suffix tree operations
void addSuffix(SuffixTreeNode current, list[str] suffix, loc file, int pos) {
    if (isEmpty(suffix)) return;
    
    str first = suffix[0];
    if (first notin current.children) {
        current.children[first] = suffixNode(first, (), ());
    }
    
    if (file notin current.children[first].positions) {
        current.children[first].positions[file] = [];
    }
    current.children[first].positions[file] += [pos];
    
    addSuffix(current.children[first], suffix[1..], file, pos + 1);
}

list[CloneResult] findClones(SuffixTreeNode currentNode) {
    list[CloneResult] clones = [];
    for (key <- domain(currentNode.children)) {
        SuffixTreeNode child = currentNode.children[key];
        if (size(child.positions) > 1) {
            list[loc] files = [f | f <- keys(child.positions)];
            for (int i <- [0..size(files)-1]) {  
                for (int j <- [i+1..size(files)-1]) {  
                    clones += [<files[i], child.positions[files[i]], 
                              files[j], child.positions[files[j]]>];
                }
            }
        }
        clones += findClones(child);
    }
    return clones;
}

