// Add these console logs at the top of the file
console.log('Script loaded');
console.log('Vega available:', typeof vega !== 'undefined');
console.log('Vega-Lite available:', typeof vegaLite !== 'undefined');
console.log('Vega-Embed available:', typeof vegaEmbed !== 'undefined');

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
    console.log('Treemap data:', fileCloneData);
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

// Replace generateDummyCloneGroups with actual clone data
function generateCloneGroups() {
    return {
        "1": {
            name: "Basic Addition Clone",
            files: [
                {
                    path: "dummy_project/src/AddTwoNumbers.java",
                    startLine: 6,
                    endLine: 8,
                    code: `package dummy_project.src;

public class AddTwoNumbers {

    // Method 1: Adds two integers
    public int add(int a, int b) {
        return a + b;
    }

    // Method 2: Multiplies two integers (not a clone)
    public int multiply(int a, int b) {
        return a * b;
    }

    public int divide(int a, int b) {
        return a / b;
    }
}`
                },
                {
                    path: "dummy_project/src/SumTwoNumbers.java",
                    startLine: 6,
                    endLine: 8,
                    code: `package dummy_project.src;

public class SumTwoNumbers {

    // Method 1: Adds two integers (Type 1 clone of AddTwoNumbers.add)
    public int sum(int a, int b) {
        return a + b;
    }

    // Method 2: Subtracts two integers (not a clone)
    public int subtract(int a, int b) {
        return a - b;
    }
}`
                }
            ]
        },
        "2": {
            name: "Input Validation Clone",
            files: [
                {
                    path: "dummy_project/src/Calculator.java",
                    startLine: 12,
                    endLine: 19,
                    code: `public class Calculator {
    // Clone pattern 1: Basic arithmetic operation
    public int add(int a, int b) {
        System.out.println("Performing addition");
        int result = a + b;
        System.out.println("Result: " + result);
        return result;
    }

    // Clone pattern 2: Input validation
    private void validateInput(int value) {
        if (value < 0) {
            throw new IllegalArgumentException("Value cannot be negative");
        }
        if (value > 1000) {
            throw new IllegalArgumentException("Value too large");
        }
        System.out.println("Input validated: " + value);
    }
}`
                },
                {
                    path: "dummy_project/src/MathUtils.java",
                    startLine: 11,
                    endLine: 18,
                    code: `public class MathUtils {
    // Clone pattern 1: Similar arithmetic operation
    public int multiply(int a, int b) {
        System.out.println("Performing multiplication");
        int result = a * b;
        System.out.println("Result: " + result);
        return result;
    }

    // Clone pattern 2: Similar input validation
    private void checkNumber(int value) {
        if (value < 0) {
            throw new IllegalArgumentException("Value cannot be negative");
        }
        if (value > 1000) {
            throw new IllegalArgumentException("Value too large");
        }
        System.out.println("Input validated: " + value);
    }
}`
                }
            ]
        },
        "3": {
            name: "Operation Logging Clone",
            files: [
                {
                    path: "dummy_project/src/Calculator.java",
                    startLine: 3,
                    endLine: 9,
                    code: `public class Calculator {
    // Clone pattern 1: Basic arithmetic operation
    public int add(int a, int b) {
        System.out.println("Performing addition");
        int result = a + b;
        System.out.println("Result: " + result);
        return result;
    }

    // Clone pattern 2: Input validation
    private void validateInput(int value) {
        if (value < 0) {
            throw new IllegalArgumentException("Value cannot be negative");
        }
        if (value > 1000) {
            throw new IllegalArgumentException("Value too large");
        }
        System.out.println("Input validated: " + value);
    }
}`
                },
                {
                    path: "dummy_project/src/MathUtils.java",
                    startLine: 3,
                    endLine: 9,
                    code: `public class MathUtils {
    // Clone pattern 1: Similar arithmetic operation
    public int multiply(int a, int b) {
        System.out.println("Performing multiplication");
        int result = a * b;
        System.out.println("Result: " + result);
        return result;
    }

    // Clone pattern 2: Similar input validation
    private void checkNumber(int value) {
        if (value < 0) {
            throw new IllegalArgumentException("Value cannot be negative");
        }
        if (value > 1000) {
            throw new IllegalArgumentException("Value too large");
        }
        System.out.println("Input validated: " + value);
    }
}`
                }
            ]
        }
    };
}

function initializeCloneDropdown() {
    const select = document.querySelector('#cloneDropdown');
    console.log('Found dropdown element:', select);
    const fileList = document.getElementById('fileList');
    
    if (!select) {
        console.error('Clone dropdown not found');
        return;
    }
    
    // Clear existing options
    select.innerHTML = '<option value="">Select a clone group...</option>';
    
    // Use actual clone data
    const cloneGroups = generateCloneGroups();
    
    Object.entries(cloneGroups).forEach(([cloneId, group]) => {
        const option = document.createElement('option');
        option.value = cloneId;
        option.textContent = `Clone Group ${cloneId}: ${group.name}`;
        select.appendChild(option);
    });
    
    // Handle clone selection
    select.addEventListener('change', async (e) => {
        const selectedClone = e.target.value;
        if (selectedClone) {
            await showFileList(selectedClone, cloneGroups[selectedClone]);
        } else {
            fileList.style.display = 'none';
        }
    });
}

async function showFileList(cloneId, cloneGroup) {
    const fileList = document.getElementById('fileList');
    fileList.innerHTML = ''; // Clear existing content
    
    for (const fileInfo of cloneGroup.files) {
        // Create button for each file
        const button = document.createElement('button');
        button.className = 'file-button';
        button.textContent = fileInfo.path;
        
        // Create container for code viewer (initially hidden)
        const codeContainer = document.createElement('div');
        codeContainer.className = `code-viewer-${cloneId}-${fileInfo.path.replace(/[\/\.]/g, '-')}`;
        codeContainer.style.display = 'none';
        
        button.addEventListener('click', async () => {
            // Toggle code visibility
            const isVisible = codeContainer.style.display !== 'none';
            if (isVisible) {
                codeContainer.style.display = 'none';
                button.classList.remove('active');
            } else {
                if (codeContainer.children.length === 0) {
                    // Load code if not already loaded
                    showCode(fileInfo, codeContainer);
                }
                codeContainer.style.display = 'block';
                button.classList.add('active');
            }
        });
        
        fileList.appendChild(button);
        fileList.appendChild(codeContainer);
    }
    
    fileList.style.display = 'block';
}

function showCode(fileData, container) {
    const codeViewer = document.createElement('div');
    codeViewer.className = 'code-viewer';
    
    const codeContainer = document.createElement('div');
    codeContainer.className = 'code-container';
    
    const codeTable = document.createElement('table');
    codeTable.className = 'code-table';
    
    const lines = fileData.code.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const row = document.createElement('tr');
        
        const lineNum = document.createElement('td');
        lineNum.className = 'line-number';
        lineNum.textContent = i + 1;
        
        const code = document.createElement('td');
        code.className = 'code-content';
        code.textContent = lines[i] || '';
        
        if (i + 1 >= fileData.startLine && i + 1 <= fileData.endLine) {
            row.className = 'highlighted';
        }
        
        row.appendChild(lineNum);
        row.appendChild(code);
        codeTable.appendChild(row);
    }
    
    codeContainer.appendChild(codeTable);
    codeViewer.appendChild(codeContainer);
    container.appendChild(codeViewer);
    
    // Scroll to the highlighted section
    setTimeout(() => {
        const highlightedRow = codeContainer.querySelector('.highlighted');
        if (highlightedRow) {
            highlightedRow.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }, 100);
}

// Initialize when the page loads
document.addEventListener('DOMContentLoaded', async () => {
    console.log('DOM Content Loaded');
    try {
        // Check if fileCloneData exists
        if (typeof fileCloneData === 'undefined') {
            console.error('fileCloneData is not defined');
            // Add some dummy data for testing
            window.fileCloneData = {
                "src/Calculator.java": { clonedLines: 50, totalLines: 200 },
                "src/MathUtils.java": { clonedLines: 30, totalLines: 150 },
                "src/Utils.java": { clonedLines: 20, totalLines: 100 }
            };
        }
        
        console.log('Creating treemap...');
        await createTreemap(fileCloneData);
        console.log('Treemap created');
        
        console.log('Initializing clone dropdown...');
        initializeCloneDropdown();
        console.log('Clone dropdown initialized');
    } catch (error) {
        console.error('Error during initialization:', error);
    }
});
  