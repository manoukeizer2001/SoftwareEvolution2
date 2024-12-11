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
            "clonePercentage": data.clonePercentage,
            "cloneIds": data.cloneIds,
            "cloneGroups": data.cloneIds.join(", ")
        });
    });

    return { values };
}
async function createTreemap() {
    try {
        console.log('Fetching treemap data...');
        const response = await fetch('/api/treemapData');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const fileCloneData = await response.json();
        console.log('Received treemap data:', fileCloneData);

        const treeData = createTreemapData(fileCloneData.files);
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
                                "signal": "{'File': datum.name, 'Clone Lines': datum.size, 'Total Lines': datum.totalLines, 'Clone Percentage': datum.clonePercentage + '%', 'Clone Groups': datum.cloneGroups}"
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
    } catch (error) {
        console.error('Error loading treemap data:', error);
        console.error('Error details:', error.message);
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

async function initializeCloneDropdown() {
    try {
        console.log('Fetching clone groups...');
        const response = await fetch('/api/cloneGroups');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        console.log('Received clone groups:', data);

        const dropdown = document.getElementById('cloneDropdown');
        if (!dropdown) {
            console.error('Clone dropdown element not found');
            return;
        }

        // Clear existing options
        dropdown.innerHTML = '';

        // Add default option
        const defaultOption = document.createElement('option');
        defaultOption.value = '';
        defaultOption.textContent = 'Select a clone group...';
        dropdown.appendChild(defaultOption);

        // Add options for each clone group
        Object.entries(data.cloneGroups).forEach(([id, group]) => {
            const option = document.createElement('option');
            option.value = id;
            option.textContent = `Clone Group ${id}`;
            dropdown.appendChild(option);
        });

        // Add event listener for selection changes
        dropdown.addEventListener('change', async function() {
            const selectedGroup = this.value;
            if (selectedGroup) {
                const groupData = data.cloneGroups[selectedGroup];
                await displayCloneGroup(groupData);
            }
        });

        console.log('Clone dropdown initialized successfully');
    } catch (error) {
        console.error('Error initializing clone dropdown:', error);
        console.error('Error details:', error.message);
    }
}

async function displayCloneGroup(groupData) {
    try {
        console.log('Displaying clone group:', groupData);
        const fileList = document.getElementById('fileList');
        if (!fileList) {
            console.error('File list element not found');
            return;
        }
        
        fileList.innerHTML = '';

        for (const file of groupData.files) {
            console.log('Processing file:', file);
            try {
                const fileContent = await fetchFileContent(file.path);
                console.log('File content received:', fileContent ? 'Content length: ' + fileContent.length : 'no content');
                
                if (!fileContent) {
                    console.error('No content received for file:', file.path);
                    continue;
                }

                // Create file button
                const fileButton = document.createElement('button');
                fileButton.className = 'file-button';
                fileButton.textContent = file.path;

                // Create code container
                const codeContainer = document.createElement('div');
                codeContainer.className = 'code-container';
                codeContainer.style.display = 'none';
                codeContainer.style.height = '300px'; // Fixed height for scrolling
                codeContainer.style.overflowY = 'auto'; // Enable vertical scrolling

                const table = document.createElement('table');
                table.className = 'code-table';
                
                const lines = fileContent.split('\n');
                
                // Add all lines to enable full scrolling
                lines.forEach((line, index) => {
                    const lineNumber = index + 1;
                    const isHighlighted = lineNumber >= file.startLine && lineNumber <= file.endLine;
                    const row = document.createElement('tr');
                    row.className = isHighlighted ? 'highlighted' : '';
                    
                    // Line number cell
                    const lineNumberCell = document.createElement('td');
                    lineNumberCell.className = 'line-number';
                    lineNumberCell.textContent = lineNumber;
                    
                    // Code content cell
                    const codeCell = document.createElement('td');
                    codeCell.className = 'code-content';
                    codeCell.textContent = line;
                    
                    row.appendChild(lineNumberCell);
                    row.appendChild(codeCell);
                    table.appendChild(row);
                });
                
                codeContainer.appendChild(table);

                // Add click handler to toggle code visibility
                fileButton.addEventListener('click', () => {
                    const isHidden = codeContainer.style.display === 'none';
                    codeContainer.style.display = isHidden ? 'block' : 'none';
                    fileButton.classList.toggle('active');

                    if (isHidden) {
                        // Calculate scroll position to show context
                        const contextLines = 4;
                        const targetLine = file.startLine - contextLines;
                        const rows = table.getElementsByTagName('tr');
                        if (rows[targetLine - 1]) {
                            rows[targetLine - 1].scrollIntoView({ behavior: 'smooth' });
                        }
                    }
                });

                // Add both elements to the file list
                fileList.appendChild(fileButton);
                fileList.appendChild(codeContainer);
                
                console.log('File display created for:', file.path);
            } catch (error) {
                console.error('Error processing file:', file.path, error);
            }
        }
    } catch (error) {
        console.error('Error displaying clone group:', error);
    }
}

async function fetchFileContent(filePath) {
    try {
        console.log('Fetching content for:', filePath);
        const response = await fetch(`/api/file?path=${filePath}`);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const content = await response.text();
        console.log('Content received for:', filePath, 'Length:', content.length);
        return content;
    } catch (error) {
        console.error('Error fetching file content:', error);
        return null;
    }
}

async function createBarChart() {
    try {
        console.log('Fetching bar chart data...');
        const response = await fetch('/api/barChartData');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        console.log('Received bar chart data:', data);

        const spec = {
            "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
            "width": "container",
            "height": 250,
            "padding": 20,
            "data": {
                "values": data.cloneSizes
            },
            "mark": {
                "type": "bar",
                "cornerRadius": 4,
                "color": "#10436c"
            },
            "encoding": {
                "x": {
                    "field": "lineCount",
                    "type": "ordinal",
                    "title": "Number of Lines in Clone",
                    "axis": {
                        "labelAngle": 0
                    }
                },
                "y": {
                    "field": "frequency",
                    "type": "quantitative",
                    "title": "Frequency",
                    "axis": {
                        "grid": false,
                        "tickMinStep": 1
                    }
                },
                "tooltip": [
                    {"field": "lineCount", "title": "Number of Lines"},
                    {"field": "frequency", "title": "Frequency"}
                ]
            }
        };

        try {
            await vegaEmbed('#barchart', spec, {
                actions: false,
                renderer: 'svg'
            });
            console.log('Bar chart created successfully');
        } catch (error) {
            console.error('Error creating bar chart:', error);
        }
    } catch (error) {
        console.error('Error loading bar chart data:', error);
        console.error('Error details:', error.message);
    }
}

async function loadAndDisplayStats() {
    try {
        console.log('Fetching stats...');
        const response = await fetch('/api/stats');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const stats = await response.json();
        console.log('Received stats:', stats);
        
        const statsBanner = document.querySelector('.stats-banner');
        if (!statsBanner) {
            console.error('Stats banner element not found');
            return;
        }
        
        statsBanner.innerHTML = ''; // Clear existing content
        
        Object.values(stats.projectStats).forEach(stat => {
            const statItem = document.createElement('div');
            statItem.className = 'stat-item';
            
            const label = document.createElement('span');
            label.className = 'stat-label';
            label.style.color = '#1e4d6b';  // Match banner blue color
            label.textContent = stat.label + ':';
            
            const value = document.createElement('span');
            value.className = 'stat-value';
            value.style.color = '#1e4d6b';  // Match banner blue color
            value.textContent = stat.value;
            
            statItem.appendChild(label);
            statItem.appendChild(value);
            statsBanner.appendChild(statItem);
        });
        
        console.log('Stats banner HTML after update:', statsBanner.innerHTML);
    } catch (error) {
        console.error('Error loading stats:', error);
        console.error('Error details:', error.message);
    }
}

// Initialize when the page loads
document.addEventListener('DOMContentLoaded', async () => {
    console.log('DOM loaded, initializing stats...');
    await loadAndDisplayStats();
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
        await initializeCloneDropdown();
        console.log('Clone dropdown initialized');
        
        const cloneGroups = generateCloneGroups();
        await createBarChart(cloneGroups);
    } catch (error) {
        console.error('Error during initialization:', error);
    }
});
  
