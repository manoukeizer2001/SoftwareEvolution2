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
    console.log('Creating treemap data from:', fileCloneData);
    const values = [
        {
            "id": "root",
            "name": "",
            "parent": null
        }
    ];

    fileCloneData.forEach(file => {
        const shortPath = file.name; // Already the short name
        
        values.push({
            "id": file.fullPath,
            "name": file.name,
            "fullPath": file.fullPath,
            "parent": "root",
            "size": file.size,              // Use size from JSON
            "clonedLines": file.clonedLines,  // Use clonedLines from JSON
            "totalLines": file.totalLines,    // Use totalLines from JSON
            "clonePercentage": file.clonePercentage, // Use clonePercentage from JSON
            "cloneGroups": file.cloneClasses  // Use cloneClasses from JSON
        });
    });

    console.log('Generated treemap data:', values);
    return { values };
}

async function createTreemap() {
    try {
        // Add title and explanation div before the treemap
        const treemapContainer = document.getElementById('treemap');
        const titleDiv = document.createElement('div');
        titleDiv.className = 'viz-title';
        titleDiv.innerHTML = '<h3>Code Clone Treemap</h3>' +
                           '<p>Rectangles sized by clone lines, colored by % of cloned code (green=0%, red=100%)</p>';
        treemapContainer.parentNode.insertBefore(titleDiv, treemapContainer);

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
            
            "signals": [
                {"name": "selectedLineCount", "value": null}
            ],

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
                            "padding": 0,
                            "as": ["x0", "y0", "x1", "y1"]
                        }
                    ]
                }
            ],

            "scales": [
                {
                    "name": "color",
                    "type": "threshold",
                    "domain": [0.001, 1, 5, 10, 20, 30, 40, 50, 75, 100],
                    "range": [
                        "#2ecc71",  // green (0%)
                        "#fff68f",  // light yellow
                        "#ffd700",  // yellow
                        "#ffa500",  // orange
                        "#ff8c00",  // dark orange
                        "#ff4500",  // red-orange
                        "#ff0000",  // red
                        "#dc143c",  // crimson
                        "#b22222",  // fire brick
                        "#8b0000",  // dark red
                        "#4a0000"   // very dark red
                    ]
                }
            ],

            "marks": [
                {
                    "type": "rect",
                    "from": {"data": "tree"},
                    "encode": {
                        "enter": {
                            "stroke": {"value": "#ffffff"},
                            "strokeWidth": {"value": 0.5}
                        },
                        "update": {
                            "x": {"field": "x0"},
                            "y": {"field": "y0"},
                            "x2": {"field": "x1"},
                            "y2": {"field": "y1"},
                            "fill": {"scale": "color", "field": "clonePercentage"},
                            "tooltip": {
                                "signal": "{" +
                                    "'File': datum.fullPath, " +
                                    "'Clone Lines': datum.clonedLines, " +
                                    "'Total Lines': datum.totalLines, " +
                                    "'Clone Percentage': datum.clonePercentage + '%', " +
                                    "'Clone Groups': datum.cloneGroups" +
                                "}"
                            },
                            "opacity": [
                                {
                                    "test": "selectedLineCount === null || datum.size === selectedLineCount",
                                    "value": 1
                                },
                                {"value": 0.3}
                            ]
                        },
                        "hover": {
                            "strokeWidth": {"value": 3}
                        }
                    }
                }
            ]
        };

        // Add debug logging for the data
        console.log('Tree data values:', treeData.values);
        treeData.values.forEach(item => {
            if (item.clonePercentage !== undefined) {
                console.log(`File: ${item.name}, Clone %: ${item.clonePercentage}`);
            }
        });

        const result = await vegaEmbed('#treemap', spec, {
            actions: false,
            renderer: 'svg'
        });

        // Store the view reference on the DOM element
        document.querySelector('#treemap').__vega_view = result.view;

        console.log('Treemap created successfully');
    } catch (error) {
        console.error('Error loading treemap data:', error);
        console.error('Error details:', error.message);
    }
}

async function initializeCloneDropdown() {
    try {
        console.log('Fetching clone groups...');
        const response = await fetch('/api/cloneClassData');
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

        // Add options for each clone class
        data.cloneClasses.forEach((cloneClass, index) => {
            const option = document.createElement('option');
            option.value = cloneClass.cloneID;
            option.textContent = `Clone Group ${cloneClass.cloneID}`;
            dropdown.appendChild(option);
        });

        // Add event listener for selection changes
        dropdown.addEventListener('change', async function() {
            const selectedGroup = this.value;
            if (selectedGroup) {
                const groupData = data.cloneClasses.find(c => c.cloneID === selectedGroup);
                await displayCloneClass(groupData);
            }
        });

        console.log('Clone dropdown initialized successfully');
    } catch (error) {
        console.error('Error initializing clone dropdown:', error);
        console.error('Error details:', error.message);
    }
}

async function displayCloneClass(groupData) {
    try {
        console.log('Displaying clone class:', groupData);
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

                // Create code container (initially hidden)
                const codeContainer = document.createElement('div');
                codeContainer.className = 'code-container';
                codeContainer.style.display = 'none';

                const pre = document.createElement('pre');
                const code = document.createElement('code');
                code.className = 'language-java';
                
                const lines = fileContent.split('\n');
                let html = '';
                
                // Show all lines with line numbers, highlight clone region
                for (let i = 0; i < lines.length; i++) {
                    const lineNumber = i + 1;
                    const isHighlighted = lineNumber >= file.startLine && lineNumber <= file.endLine;
                    const lineClass = isHighlighted ? 'line highlighted' : 'line';
                    html += `<div class="${lineClass}"><span class="line-number">${lineNumber}</span>${lines[i]}</div>`;
                }
                
                code.innerHTML = html;
                pre.appendChild(code);
                codeContainer.appendChild(pre);

                // Add click handler to toggle code visibility
                fileButton.addEventListener('click', () => {
                    const isHidden = codeContainer.style.display === 'none';
                    codeContainer.style.display = isHidden ? 'block' : 'none';
                    fileButton.classList.toggle('active');

                    if (isHidden) {
                        // Scroll to the first highlighted line when showing code
                        setTimeout(() => {
                            const highlightedLine = code.querySelector('.highlighted');
                            if (highlightedLine) {
                                highlightedLine.scrollIntoView({ 
                                    behavior: 'smooth', 
                                    block: 'center'
                                });
                            }
                        }, 100);
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

// Bar Chart
async function createBarChart() {
    try {
        // Add title and explanation div before the barchart
        const barchartContainer = document.getElementById('barchart');
        const titleDiv = document.createElement('div');
        titleDiv.className = 'viz-title';
        titleDiv.innerHTML = '<h3>Clone Size Distribution</h3>' +
                           '<p>Frequency of clones by line count. Click bars to highlight matching clones in treemap.</p>';
        barchartContainer.parentNode.insertBefore(titleDiv, barchartContainer);

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
                "cursor": "pointer",
                "color": "#10436c"
            },
            "selection": {
                "clicked": {
                    "type": "single",
                    "empty": "all",
                    "toggle": true
                }
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
                "opacity": {
                    "condition": {"selection": "clicked", "value": 1},
                    "value": 0.3
                },
                "tooltip": [
                    {"field": "lineCount", "title": "Number of Lines"},
                    {"field": "frequency", "title": "Frequency"}
                ]
            }
        };

        const result = await vegaEmbed('#barchart', spec, {
            actions: false,
            renderer: 'svg'
        });

        let currentSelection = null;

        // Add click handler
        result.view.addEventListener('click', function(event, item) {
            if (item && item.datum) {
                const lineCount = item.datum.lineCount;
                console.log('Selected line count:', lineCount);
                
                // Toggle selection
                if (currentSelection === lineCount) {
                    // Deselect
                    currentSelection = null;
                    result.view.signal('clicked_tuple', null);
                    result.view.run();
                    highlightTreemapFiles(null);
                } else {
                    // Select new bar
                    currentSelection = lineCount;
                    highlightTreemapFiles(lineCount);
                }
            }
        });

        console.log('Bar chart created successfully');
    } catch (error) {
        console.error('Error creating bar chart:', error);
        console.error('Error details:', error.message);
    }
}

// Interaction between bar chart and treemap
function highlightTreemapFiles(lineCount) {
    console.log('Highlighting files with line count:', lineCount);
    
    // Get the treemap view and its Vega view instance
    const treemapContainer = document.querySelector('#treemap');
    const vegaView = treemapContainer.__vega_view;
    if (!vegaView) {
        console.error('Treemap Vega view not found');
        return;
    }

    // Update the treemap marks
    vegaView.signal('selectedLineCount', lineCount);
    
    // Get the scenegraph nodes for the rectangles
    const rects = vegaView.scenegraph().root.items[0].items[0].items;
    
    rects.forEach(rect => {
        // Store the original opacity if we haven't yet
        if (rect.originalOpacity === undefined) {
            rect.originalOpacity = rect.opacity || 1;
        }

        if (lineCount === null) {
            // Reset opacity for all rectangles
            rect.opacity = rect.originalOpacity;
        } else {
            // Check if this rectangle's size matches the selected line count
            rect.opacity = (rect.datum.size === lineCount) ? rect.originalOpacity : 0.3;
        }
    });

    // Update the view to reflect the changes
    vegaView.run();
}

// Stats Banner
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
        
        statsBanner.innerHTML = `
            <div class="stat-item">
                <span class="stat-label">Duplicated Lines:</span>
                <span class="stat-value">${stats.duplicatedLinesPercentage.toFixed(1)}%</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Number of Clones:</span>
                <span class="stat-value">${stats.numberOfClones.toLocaleString()}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Clone Classes:</span>
                <span class="stat-value">${stats.numberOfCloneClasses.toLocaleString()}</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Biggest Clone:</span>
                <span class="stat-value">${stats.biggestClone.size} lines (ID: ${stats.biggestClone.id})</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Largest Clone Class:</span>
                <span class="stat-value">${stats.biggestCloneClass.size} instances (ID: ${stats.biggestCloneClass.id})</span>
            </div>
        `;
        
        console.log('Stats banner updated successfully');
    } catch (error) {
        console.error('Error loading stats:', error);
        console.error('Error details:', error.message);
    }
}

// Initialize when the page loads
document.addEventListener('DOMContentLoaded', async () => {
    console.log('DOM loaded, initializing...');
    try {
        await loadAndDisplayStats();
        await createTreemap();
        await initializeCloneDropdown();
        console.log('Clone dropdown initialized');
        
        await createBarChart();
    } catch (error) {
        console.error('Error during initialization:', error);
    }
});
  
