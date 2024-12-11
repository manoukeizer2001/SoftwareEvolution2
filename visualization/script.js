// Add this at the very top of your script.js
console.log('Vega available:', typeof vega !== 'undefined');
console.log('Vega-Lite available:', typeof vegaLite !== 'undefined');
console.log('Vega-Embed available:', typeof vegaEmbed !== 'undefined');

// Extended test data structure
const cloneData = {
    "1": {
        files: [
            {
                path: "src/Calculator.java",
                startLine: 15,
                endLine: 25,
                code: `public class Calculator {
    private int value;
    
    public Calculator() {
        this.value = 0;
    }
    
    public int add(int a, int b) {
        return a + b;
    }
    
    public int subtract(int a, int b) {
        return a - b;
    }
    // ... more code ...
}`
            },
            {
                path: "src/MathUtils.java",
                startLine: 30,
                endLine: 40,
                code: `public class MathUtils {
    public static int add(int a, int b) {
        return a + b;
    }
    
    public static int subtract(int a, int b) {
        return a - b;
    }
    
    public static int multiply(int a, int b) {
        return a * b;
    }
    // ... more code ...
}`
            }
        ]
    },
    // Add more clone groups as needed
};

// Test data
const fileCloneData = {
    "src/Calculator.java": {
        filename: "src/Calculator.java",
        cloneIds: ["1", "3"],
        clonedLines: 25,
        totalLines: 100
    },
    "src/MathUtils.java": {
        filename: "src/MathUtils.java",
        cloneIds: ["1", "2", "4"],
        clonedLines: 40,
        totalLines: 80
    },
    "src/Utils.java": {
        filename: "src/Utils.java",
        cloneIds: ["2"],
        clonedLines: 10,
        totalLines: 50
    }
};

// Add config variable at the top
let config;

// Function to fetch config
async function fetchConfig() {
    try {
        const response = await fetch('/api/config');
        config = await response.json();
        return config;
    } catch (error) {
        console.error('Error fetching config:', error);
        return null;
    }
}

// Function to read file content
async function readFile(filePath) {
    try {
        const response = await fetch(`/api/file?path=${filePath}`);
        if (!response.ok) {
            throw new Error(`Failed to load file: ${filePath}`);
        }
        return await response.text();
    } catch (error) {
        console.error('Error reading file:', error);
        return null;
    }
}

// Function to get all Java files from directory
async function getJavaFiles(directoryPath) {
    try {
        const response = await fetch(`/api/files?path=${directoryPath}`);
        if (!response.ok) {
            throw new Error(`Failed to load directory: ${directoryPath}`);
        }
        return await response.json();
    } catch (error) {
        console.error('Error reading directory:', error);
        return [];
    }
}

function createTreemapData(fileCloneData) {
    const values = [
        {
            "id": "root",
            "name": "",
            "parent": null
        }
    ];

    Object.entries(fileCloneData).forEach(([path, data]) => {
        values.push({
            "id": path,
            "name": path,
            "parent": "root",
            "size": data.clonedLines,
            "totalLines": data.totalLines,
            "details": `${data.clonedLines}/${data.totalLines} lines`
        });
    });

    return { values };
}

async function createTreemap(fileCloneData) {
    const treeData = createTreemapData(fileCloneData);
    const container = document.getElementById('treemap');
    const width = container.clientWidth || 960;
    const height = 500;

    const spec = {
        "$schema": "https://vega.github.io/schema/vega/v5.json",
        "width": width,
        "height": height,
        "padding": 5,

        "data": [
            {
                "name": "tree",
                "values": treeData.values,
                "transform": [
                    {
                        "type": "stratify",
                        "key": "id",
                        "parentKey": "parent"
                    },
                    {
                        "type": "treemap",
                        "field": "size",
                        "size": [{"signal": "width"}, {"signal": "height"}],
                        "padding": 2,
                        "as": ["x0", "y0", "x1", "y1"]
                    }
                ]
            }
        ],

        "scales": [
            {
                "name": "color",
                "type": "sequential",
                "domain": {"data": "tree", "field": "size"},
                "range": {"scheme": "reds"}
            }
        ],

        "marks": [
            {
                "type": "rect",
                "from": {"data": "tree"},
                "encode": {
                    "enter": {
                        "stroke": {"value": "#ffffff"},
                        "strokeWidth": {"value": 2}
                    },
                    "update": {
                        "x": {"field": "x0"},
                        "y": {"field": "y0"},
                        "x2": {"field": "x1"},
                        "y2": {"field": "y1"},
                        "fill": {"scale": "color", "field": "size"},
                        "tooltip": {
                            "signal": "{'File': datum.name, 'Clone Lines': datum.size, 'Total Lines': datum.totalLines}"
                        }
                    },
                    "hover": {
                        "strokeWidth": {"value": 3}
                    }
                }
            },
            {
                "type": "text",
                "from": {"data": "tree"},
                "encode": {
                    "enter": {
                        "align": {"value": "center"},
                        "baseline": {"value": "middle"},
                        "fill": {"value": "#000"},
                        "text": {"field": "name"},
                        "fontSize": {"value": 11},
                        "fontWeight": {"value": "bold"}
                    },
                    "update": {
                        "x": {"signal": "(datum.x0 + datum.x1) / 2"},
                        "y": {"signal": "(datum.y0 + datum.y1) / 2"},
                        "opacity": {"signal": "datum.x1 - datum.x0 > 50 && datum.y1 - datum.y0 > 30 ? 1 : 0"}
                    }
                }
            }
        ]
    };

    try {
        await vegaEmbed('#treemap', spec, {
            actions: false,
            renderer: 'svg'
        });
        console.log('Treemap created successfully');
    } catch (error) {
        console.error('Error creating treemap:', error);
    }
}

function initializeCloneDropdown() {
    // Use the existing dropdown
    const select = document.querySelector('.clone-selection select') || document.querySelector('select');
    const fileList = document.getElementById('fileList');
    const fileListItems = document.getElementById('fileListItems');
    const codeViewer = document.getElementById('codeViewer');
    
    // Clear existing options
    select.innerHTML = '<option value="">Select a clone group...</option>';
    
    // Populate dropdown with clone groups
    Object.keys(cloneData).forEach(cloneId => {
        const option = document.createElement('option');
        option.value = cloneId;
        option.textContent = `Clone Group ${cloneId}`;
        select.appendChild(option);
    });
    
    // Handle clone selection
    select.addEventListener('change', (e) => {
        const selectedClone = e.target.value;
        if (selectedClone) {
            showFileList(selectedClone);
            codeViewer.style.display = 'none';
        } else {
            fileList.style.display = 'none';
            codeViewer.style.display = 'none';
        }
    });
}

function showFileList(cloneId) {
    const fileList = document.getElementById('fileList');
    const fileListItems = document.getElementById('fileListItems');
    fileListItems.innerHTML = '';
    
    cloneData[cloneId].files.forEach(file => {
        const li = document.createElement('li');
        li.textContent = file.path;
        li.addEventListener('click', () => showCode(file));
        fileListItems.appendChild(li);
    });
    
    fileList.style.display = 'block';
}

function showCode(fileData) {
    const codeViewer = document.getElementById('codeViewer');
    const currentFile = document.getElementById('currentFile');
    const codeTable = document.getElementById('codeTable');
    
    currentFile.textContent = fileData.path;
    codeTable.innerHTML = '';
    
    // Split code into lines
    const lines = fileData.code.split('\n');
    const contextLines = 4; // Number of lines to show before and after
    
    // Calculate visible range
    const startLine = Math.max(1, fileData.startLine - contextLines);
    const endLine = Math.min(lines.length, fileData.endLine + contextLines);
    
    // Create table rows
    for (let i = startLine - 1; i < endLine; i++) {
        const row = document.createElement('tr');
        
        // Line number cell
        const lineNum = document.createElement('td');
        lineNum.className = 'line-number';
        lineNum.textContent = i + 1;
        
        // Code cell
        const code = document.createElement('td');
        code.textContent = lines[i] || '';
        
        // Highlight clone lines
        if (i + 1 >= fileData.startLine && i + 1 <= fileData.endLine) {
            row.className = 'highlighted';
        }
        
        row.appendChild(lineNum);
        row.appendChild(code);
        codeTable.appendChild(row);
    }
    
    codeViewer.style.display = 'block';
}

// Simplified initializeCloneViewer function
async function initializeCloneViewer() {
    // Create initial treemap with test data
    await createTreemap(fileCloneData);
    
    // Initialize clone dropdown
    initializeCloneDropdown();
}

// Initialize when the page loads
document.addEventListener('DOMContentLoaded', initializeCloneViewer);
  