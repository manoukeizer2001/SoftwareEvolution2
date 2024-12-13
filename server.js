const express = require('express');
const fs = require('fs').promises;
const path = require('path');
const app = express();
const config = require('./config.json');

app.use(express.static('visualization'));

// Helper function to recursively get all Java files
async function getAllJavaFiles(dirPath, baseDir) {
  console.log('Scanning directory:', dirPath);
  const files = await fs.readdir(dirPath);
  const javaFiles = [];

  for (const file of files) {
    const fullPath = path.join(dirPath, file);
    const stat = await fs.stat(fullPath);

    if (stat.isDirectory()) {
      // Recursively search subdirectories
      const subDirFiles = await getAllJavaFiles(fullPath, baseDir);
      javaFiles.push(...subDirFiles);
    } else if (file.endsWith('.java')) {
      // Get path relative to the base directory
      const relativePath = path.relative(baseDir, fullPath);
      console.log('Found Java file:', relativePath);
      javaFiles.push(relativePath);
    }
  }

  return javaFiles;
}

// Endpoint to get all Java files in a directory
app.get('/api/files', async (req, res) => {
  const baseDir = path.join(__dirname, config.sourceDirectory);
  
  console.log('Base directory:', baseDir);
  
  try {
    const javaFiles = await getAllJavaFiles(baseDir, baseDir);
    console.log('All Java files found:', javaFiles);
    res.json(javaFiles);
  } catch (error) {
    console.error('Error reading directory:', error);
    res.status(500).json({ error: 'Failed to read directory' });
  }
});

// Endpoint to get file content
app.get('/api/file', async (req, res) => {
  const filePath = req.query.path;
  
  if (!filePath) {
    console.error('No file path provided');
    return res.status(400).json({ error: 'No file path provided' });
  }

  // Get the full path
  const fullPath = path.join(__dirname, filePath);
  console.log('Attempting to read file:', fullPath);

  try {
    const content = await fs.readFile(fullPath, 'utf8');
    console.log('File content loaded successfully for:', filePath);
    res.send(content);
  } catch (error) {
    console.error('Error reading file:', filePath, error);
    res.status(500).json({ error: `Failed to read file: ${error.message}` });
  }
});

// Add this new endpoint after your existing endpoints
app.get('/api/config', (req, res) => {
  res.json(config);
});

app.get('/api/stats', (req, res) => {
    // Clear require cache for stats.json
    delete require.cache[require.resolve('./visualization/stats.json')];
    const stats = require('./visualization/stats.json');
    
    // Set headers to prevent caching
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    res.set('Expires', '-1');
    res.set('Pragma', 'no-cache');
    
    res.json(stats);
});

// Add this with your other endpoints
app.get('/api/barChartData', (req, res) => {
    // Clear require cache
    delete require.cache[require.resolve('./visualization/barChartData.json')];
    const barChartData = require('./visualization/barChartData.json');
    
    // Set headers to prevent caching
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    res.set('Expires', '-1');
    res.set('Pragma', 'no-cache');
    
    res.json(barChartData);
});

app.get('/api/treemapData', (req, res) => {
    // Clear require cache
    delete require.cache[require.resolve('./visualization/treemapData.json')];
    const treemapData = require('./visualization/treemapData.json');
    
    // Set headers to prevent caching
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    res.set('Expires', '-1');
    res.set('Pragma', 'no-cache');
    
    res.json(treemapData);
});

app.get('/api/cloneClassData', async (req, res) => {
    try {
        // Get the source directory from config
        const config = require('./config.json');
        const sourceDir = config.sourceDirectory;
        
        // Clear require cache
        delete require.cache[require.resolve('./visualization/cloneClassData.json')];
        const cloneClassData = require('./visualization/cloneClassData.json');
        
        // Set headers to prevent caching
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
        res.set('Expires', '-1');
        res.set('Pragma', 'no-cache');
        
        res.json(cloneClassData);
    } catch (error) {
        console.error('Error loading clone class data:', error);
        res.status(500).json({ error: 'Failed to load clone class data' });
    }
});

const PORT = process.env.PORT || config.port;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Current directory: ${__dirname}`);
});
