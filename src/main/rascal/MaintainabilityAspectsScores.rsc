module MaintainabilityAspectsScores

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;



private str rateVolume(int volume) {
    if (volume < 66000) return "++";
    if (volume < 246000) return "+";
    if (volume < 665000) return "o";
    if (volume < 1310000) return "-";
    return "--";
}

private str rateDuplication(real percentage) {
    if (percentage <= 3) return "++";
    if (percentage <= 5) return "+";
    if (percentage <= 10) return "o";
    if (percentage <= 20) return "-";
    return "--";
}

private str rateUnitSize(tuple[real, real, real, real] unit_size_dist) {
    // Extract percentages [low, moderate, high, very high]
    real moderate = unit_size_dist[1];
    real high = unit_size_dist[2];
    real veryHigh = unit_size_dist[3];
    
    // Apply Heitlager's thresholds (same as complexity)
    if (moderate <= 25 && high == 0 && veryHigh == 0) return "++";
    if (moderate <= 30 && high <= 5 && veryHigh == 0) return "+";
    if (moderate <= 40 && high <= 10 && veryHigh == 0) return "o";
    if (moderate <= 50 && high <= 15 && veryHigh <= 5) return "-";
    return "--";
}

private str rateComplexity(tuple[real, real, real, real] complexity_dist) {
    // Extract percentages [low, moderate, high, very high]
    real moderate = complexity_dist[1];
    real high = complexity_dist[2];
    real veryHigh = complexity_dist[3];
    
    // Apply Heitlager's thresholds
    if (moderate <= 25 && high == 0 && veryHigh == 0) return "++";
    if (moderate <= 30 && high <= 5 && veryHigh == 0) return "+";
    if (moderate <= 40 && high <= 10 && veryHigh == 0) return "o";
    if (moderate <= 50 && high <= 15 && veryHigh <= 5) return "-";
    return "--";
}

str calculateAnalysabilityScore(
    int volume,                                    // total volume
    tuple[real, int, int] duplicationResult,       // percentage, total, duplicate
    tuple[real, real, real, real] unitSizePerc     // percentages [low, moderate, high, very high]
) {
    
    // Volume rating
    str volumeRating = rateVolume(volume);
    // Duplication rating
    str duplicationRating = rateDuplication(duplicationResult[0]);
   
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizePerc);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[volumeRating] + 
                    ratingToNum[duplicationRating] + 
                    ratingToNum[unitSizeRating]) / 3;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}

str calculateChangeabilityScore(
    tuple[real, real, real, real] complexityPerc,     // percentages [low, moderate, high, very high]
    tuple[real, int, int] duplicationResult           // percentage, total, duplicate
) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexityPerc);
    
    // Duplication rating
    str duplicationRating = rateDuplication(duplicationResult[0]);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[complexityRating] + 
                    ratingToNum[duplicationRating]) / 2;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}

str calculateTestabilityScore(
    tuple[real, real, real, real] complexityPerc,    // percentages [low, moderate, high, very high]
    tuple[real, real, real, real] unitSizePerc       // percentages [low, moderate, high, very high]
) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexityPerc);
    
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizePerc);
    
    // Convert ratings to numbers for averaging
    map[str, int] ratingToNum = (
        "++" : 5,
        "+" : 4,
        "o" : 3,
        "-" : 2,
        "--" : 1
    );
    
    // Calculate average (rounded down as per Heitlager)
    int avgScore = (ratingToNum[complexityRating] + 
                    ratingToNum[unitSizeRating]) / 2;
    
    // Convert back to rating
    map[int, str] numToRating = (
        5 : "++",
        4 : "+",
        3 : "o",
        2 : "-",
        1 : "--"
    );
    
    return numToRating[avgScore];
}
