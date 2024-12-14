module DataTypes

import Location;

// Clone detection types
alias CloneClass = tuple[str pattern, list[loc] locations];

// Clone class with id
alias CloneClassWithId = tuple[str id, str pattern, list[loc] locations];

// Clone class info for JSON
alias CloneClassInfo = tuple[str cloneID, list[tuple[str path, int startLine, int endLine]] files];

// Type alias for file clone data
alias FileCloneData = tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds];

