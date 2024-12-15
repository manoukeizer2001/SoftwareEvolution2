module DataTypes

import Location;

// Clone classes
alias CloneClass = tuple[str pattern, list[loc] locations];

// Same as CloneClass, but with IDs
alias CloneClassWithId = tuple[str id, str pattern, list[loc] locations];

// Clone classess with more information about exact locations within files
alias CloneClassInfo = tuple[str cloneID, list[tuple[str path, int startLine, int endLine]] files];

// Clone information per file
alias FileCloneData = tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds];

