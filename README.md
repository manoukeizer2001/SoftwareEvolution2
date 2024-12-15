# Initilization

The projet is set to perform clone detection in Java projects. To specify the project path, adjust the ```projectLocation``` argument in ```main()```.
The ```main()``` method also provides an option to calculate volume (which can take a while) or use a placeholder value for it instead. Toggling this option requires adjusting the ```projectName``` and ```calculateVolume``` arguments in ```main()```.

# How to run the Clone Detection

Make sure you have Rascal installed

Open your Rascal Terminal and run the following commands:
```
import Main;
main();
```
After a successful analysis, four JSON files containing the results will be generated in the *visualization* directory.

# How to run the Visualization

Make sure you have Node.js installed. If you don't have it, you can install it from https://nodejs.org/.

Open your powershellterminal and run the following commands:
```
npm install express
npm init -y
node server.js
```
If everything is set up correctly, you should see a message in the terminal saying that the server is running on port 3000.
Open your browser and go to http://localhost:3000

Additionally you may change the port in *config.json*.

## File Structure

- `Main.rsc` - Entry point for the clone detection process. Modify this to set the project path and toggle options for volume calculation.
- `JSONExport.rsc` - JSON file exporter. Gathers analysis data and stores them into JSON files.
- `CloneDetection.rsc` - Algorithm for identifying and analyzing clones in the project.
- `BarChartData.rsc`, `CloneClassData.rsc`, `TreeMapData.rsc`, `Statistics.rsc` - Helper modules for processing and extracting data for visualizations.
- `Util.rsc`, `DataTypes.rsc` - General helper modules
- `server.js` - The backend server for the visualization tool.
- `script.js` - Handles user interactions in the visualization.

## Directories
- `visualization/` - Where JSON results are saved for visualization.
- `src/` - Contains files for clone detection analysis and exporting JSON data.


# Extra note
Do it in this order. If Clone Detection has not been run, the visualization will not work as it has no data to display.
