# Initilization

The current project is set to run the smallsql0.21_src file. If you want to run a different file, you can change the file name in the config.json file. Don't alter the port number.


# How to run the Clone Detection

Make sure you have Rascal installed

Open your Rascal Terminal and run the following commands:
```
import Main;
main();
```
This will add 4 json files to the visualization folder.


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

# Extra note
Do it in this order. If Clone Detection has not been run, the visualization will not work as it has no data to display.
