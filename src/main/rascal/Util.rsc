module Util

import String;
import Location;

// Get the relative path of the file
public str getRelativePath(loc location, loc projectLocation) {
    str fullPath = location.path;
    str projectName = substring(projectLocation.path, findLast(projectLocation.path, "/") + 1);
    int projectIndex = findLast(fullPath, projectName);

    return projectName + substring(fullPath, projectIndex + size(projectName));
}

// Get the full path of the file
public loc getFullPath(loc location, loc projectLocation) {
    str projectName = substring(projectLocation.path, findLast(projectLocation.path, "/") + 1);
    str relativePath = getRelativePath(location, projectLocation);
    str relativePathWithoutProjectName = substring(relativePath, size(projectName) + 1);
    
    return projectLocation + relativePathWithoutProjectName;
}