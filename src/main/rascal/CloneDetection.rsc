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

// // Step 2: Serialize AST with structure information
SerializedNode serializeAst(node ast) {
    try {
        switch(ast) {
            // CompilationUnit variants
            case \compilationUnit(list[Declaration] imports, list[Declaration] types):
                return serialNode("compilationUnit", 1 + size(imports) + size(types), 
                    [serializeAst(i) | i <- imports] + [serializeAst(t) | t <- types]);
                
            case \compilationUnit(Declaration package, list[Declaration] imports, list[Declaration] types):
                return serialNode("compilationUnit", 1 + size(imports) + size(types), 
                    [serializeAst(package)] + [serializeAst(i) | i <- imports] + [serializeAst(t) | t <- types]);
                
            case \compilationUnit(Declaration \module):
                return serialNode("compilationUnit", 1, [serializeAst(\module)]);
                
            // Enum related
            case \enum(list[Modifier] modifiers, Expression name, list[Type] implements, list[Declaration] constants, list[Declaration] body):
                return serialNode("enum", 2 + size(constants) + size(body),
                    [serializeAst(name)] + [serializeAst(c) | c <- constants] + [serializeAst(b) | b <- body]);
                
            case \enumConstant(list[Modifier] modifiers, Expression name, list[Expression] arguments, Declaration class):
                return serialNode("enumConstant", 2 + size(arguments),
                    [serializeAst(name)] + [serializeAst(a) | a <- arguments] + [serializeAst(class)]);
                
            case \enumConstant(list[Modifier] modifiers, Expression name, list[Expression] arguments):
                return serialNode("enumConstant", 1 + size(arguments),
                    [serializeAst(name)] + [serializeAst(a) | a <- arguments]);
                
            // Class and Interface
            case \class(list[Modifier] modifiers, Expression name, list[Declaration] typeParameters, list[Type] extends, list[Type] implements, list[Declaration] body):
                return serialNode("class", 2 + size(typeParameters) + size(body),
                    [serializeAst(name)] + [serializeAst(t) | t <- typeParameters] + [serializeAst(b) | b <- body]);
                
            case \class(list[Declaration] body):
                return serialNode("anonymousClass", size(body), [serializeAst(b) | b <- body]);
                
            case \interface(list[Modifier] modifiers, Expression name, list[Declaration] typeParameters, list[Type] extends, list[Type] implements, list[Declaration] body):
                return serialNode("interface", 2 + size(typeParameters) + size(body),
                    [serializeAst(name)] + [serializeAst(t) | t <- typeParameters] + [serializeAst(b) | b <- body]);
                
            // Fields and Methods
            case \field(list[Modifier] modifiers, Type \type, list[Declaration] fragments):
                return serialNode("field", 2 + size(fragments),
                    [serialNode("type", 1, [])] + [serializeAst(f) | f <- fragments]);
                
            case \initializer(list[Modifier] modifiers, Statement initializerBody):
                return serialNode("initializer", 1, [serializeAst(initializerBody)]);
                
            case \method(list[Modifier] modifiers, list[Declaration] typeParameters, Type \return, Expression name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
                return serialNode("method", 3 + size(parameters),
                    [serializeAst(\return), serializeAst(name)] + [serializeAst(p) | p <- parameters] + [serializeAst(impl)]);
                
            case \method(list[Modifier] modifiers, list[Declaration] typeParameters, Type \return, Expression name, list[Declaration] parameters, list[Expression] exceptions):
                return serialNode("abstractMethod", 2 + size(parameters),
                    [serializeAst(\return), serializeAst(name)] + [serializeAst(p) | p <- parameters]);
                
            case \constructor(list[Modifier] modifiers, Expression name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
                return serialNode("constructor", 2 + size(parameters),
                    [serializeAst(name)] + [serializeAst(p) | p <- parameters] + [serializeAst(impl)]);
                
            // Imports and Package
            case \import(list[Modifier] modifiers, Expression name):
                return serialNode("import", 1, [serializeAst(name)]);
                
            case \importOnDemand(list[Modifier] modifiers, Expression name):
                return serialNode("importOnDemand", 1, [serializeAst(name)]);
                
            case \package(list[Modifier] modifiers, Expression name):
                return serialNode("package", 1, [serializeAst(name)]);
                
            // Variables and Parameters
            case \variables(list[Modifier] modifiers, Type \type, list[Declaration] fragments):
                return serialNode("variables", 2 + size(fragments),
                    [serialNode("type", 1, [])] + [serializeAst(f) | f <- fragments]);
                
            case \variable(Expression name, list[Declaration] dimensionTypes):
                return serialNode("variable", 1 + size(dimensionTypes),
                    [serializeAst(name)] + [serializeAst(d) | d <- dimensionTypes]);
                
            case \variable(Expression name, list[Declaration] dimensionTypes, Expression initializer):
                return serialNode("variable", 2 + size(dimensionTypes),
                    [serializeAst(name)] + [serializeAst(d) | d <- dimensionTypes] + [serializeAst(initializer)]);
                
            // Type Parameters and Annotations
            case \typeParameter(Expression name, list[Type] extendsList):
                return serialNode("typeParameter", 1 + size(extendsList),
                    [serializeAst(name)] + [serialNode("extends", 1, []) | _ <- extendsList]);
                
            case \annotationType(list[Modifier] modifiers, Expression name, list[Declaration] body):
                return serialNode("annotationType", 2 + size(body),
                    [serializeAst(name)] + [serializeAst(b) | b <- body]);
                
            case \annotationTypeMember(list[Modifier] modifiers, Type \type, Expression name):
                return serialNode("annotationMember", 2,
                    [serialNode("type", 1, []), serializeAst(name)]);
                
            case \annotationTypeMember(list[Modifier] modifiers, Type \type, Expression name, Expression defaultBlock):
                return serialNode("annotationMember", 3,
                    [serialNode("type", 1, []), serializeAst(name), serializeAst(defaultBlock)]);
                
            case \parameter(list[Modifier] modifiers, Type \type, Expression name, list[Declaration] dimensions):
                return serialNode("parameter", 2 + size(dimensions),
                    [serialNode("type", 1, []), serializeAst(name)] + [serializeAst(d) | d <- dimensions]);
                
            case \dimension(list[Modifier] annotations):
                return serialNode("dimension", size(annotations), []);
                
            case \vararg(list[Modifier] modifiers, Type \type, Expression name):
                return serialNode("vararg", 2,
                    [serialNode("type", 1, []), serializeAst(name)]);

            
            // // ... rest of the cases (expressions, statements, etc.) remain the same ...
            
            default: {
                str nodeType = getName(ast);
                println("Warning: Unhandled node type: <nodeType>");
                return serialNode(nodeType, 1, []);
            }
        }
    } catch str errorMsg: {
        println("Error while serializing AST node: <errorMsg>");
        println("Node type: <getName(ast)>");
        return serialNode("error", 1, []);
    } catch: {
        println("Unexpected error while serializing AST node");
        println("Node type: <getName(ast)>");
        return serialNode("error", 1, []);
    }
}


// Helper function to convert SerializedNode to string sequence
list[str] flattenTree(SerializedNode node1) {
    return ["<node1.nodeType>(<node1.subtreeSize>)"] + [s | child <- node1.children, s <- flattenTree(child)];
}

// Suffix tree node with position tracking
data SuffixTreeNode = suffixNode(str label, map[str, SuffixTreeNode] children, map[loc, list[int]] positions);

// Build suffix tree and track positions
void addSuffix(SuffixTreeNode current, list[str] suffix, loc file, int pos, int minSize) {
    if (size(suffix) < minSize) return;
    
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
list[CloneResult] findClones(SuffixTreeNode node1, int minSize) {
    list[CloneResult] clones = [];
    
    // Only consider sequences meeting minimum size
    if (size(node1.positions) > 1) {
        list[loc] files = [f | f <- keys(node1.positions)];
        for (int i <- [0..size(files)-1]) {
            for (int j <- [i+1..size(files)]) {
                list[int] pos1 = node1.positions[files[i]];
                list[int] pos2 = node1.positions[files[j]];
                
                // Check if positions form valid clones
                if (size(pos1) > 0 && size(pos2) > 0) {
                    clones += [<files[i], pos1, files[j], pos2>];
                }
            }
        }
    }
    
    // Recursively check children
    for (str key <- node1.children) {
        clones += findClones(node1.children[key], minSize);
    }
    
    return clones;
}

// Main clone detection function
list[CloneResult] detectClones(list[Declaration] asts) {
    list[CloneResult] clones = [];
    int minCloneSize = 2;
    
    // Debug print
    println("Starting clone detection with <size(asts)> ASTs");
    
    // Process each AST individually
    for (ast <- asts) {
        try {
            if (ast@src?) {
                println("Processing AST at location: <ast@src>");
                SerializedNode serialized = serializeAst(ast);
                println("Successfully serialized AST");
                
                // Just store basic information for now
                if (ast@src?) {
                    clones += [<ast@src, [1], ast@src, [1]>];
                }
            }
        } catch: {
            println("Error processing AST");
            continue;
        }
    }
    
    println("Completed basic clone detection");
    return clones;
}

// Add a helper function to check tree contents
void printSuffixTreeStats(SuffixTreeNode node1, int depth = 0) {
    str indent = "";
    for (_ <- [0..depth]) {
        indent += "  ";
    }
    println("<indent>Node <node1.label> has <size(node1.positions)> positions");
    for (child <- node1.children) {
        printSuffixTreeStats(node1.children[child], depth + 1);
    }
}

// Helper function to get node type name - simplified version
str getNodeType(node n) = getName(n);
