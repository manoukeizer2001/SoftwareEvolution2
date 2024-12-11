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
    return res.status(400).json({ error: 'No file path provided' });
  }

  const fullPath = path.join(__dirname, config.sourceDirectory, filePath.replace(config.sourceDirectory + '/', ''));
  console.log('Reading file:', fullPath);

  try {
    const content = await fs.readFile(fullPath, 'utf8');
    res.send(content);
  } catch (error) {
    console.error('Error reading file:', error);
    res.status(500).json({ error: 'Failed to read file' });
  }
});

// Add this new endpoint after your existing endpoints
app.get('/api/config', (req, res) => {
  res.json(config);
});

const PORT = process.env.PORT || config.port;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Current directory: ${__dirname}`);
});
