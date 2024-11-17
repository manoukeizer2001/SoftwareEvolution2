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

private str rateUnitSize(map[str, int] unitSizes) {
    // Calculate total lines
    int totalLines = sum(range(unitSizes));
    if (totalLines == 0) return "++";  // Handle empty case
    
    // Calculate percentages for each risk category
    real veryHighRisk = 0.0;
    real highRisk = 0.0;
    real moderateRisk = 0.0;
    
    // Iterate over values directly
    for (int size <- range(unitSizes)) {
        if (size > 100) {
            veryHighRisk += (toReal(size) / totalLines) * 100;
        }
        else if (size > 50) {
            highRisk += (toReal(size) / totalLines) * 100;
        }
        else if (size > 20) {
            moderateRisk += (toReal(size) / totalLines) * 100;
        }
    }
    
    // Apply Heitlager's thresholds
    if (moderateRisk <= 25 && highRisk == 0 && veryHighRisk == 0) return "++";
    if (moderateRisk <= 30 && highRisk <= 5 && veryHighRisk == 0) return "+";
    if (moderateRisk <= 40 && highRisk <= 10 && veryHighRisk == 0) return "o";
    if (moderateRisk <= 50 && highRisk <= 15 && veryHighRisk <= 5) return "-";
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

str calculateAnalysabilityScore(int volume,  
    tuple[real percentage, int totalLines, int duplicateLines] duplication, map[str, int] unitSizes) {
    
    // Volume rating
    str volumeRating = rateVolume(volume);
    
    // Duplication rating
    str duplicationRating = rateDuplication(duplication.percentage);
    
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizes);
    
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

tr calculateChangeabilityScore(tuple[real, real, real, real] complexity_dist,
    tuple[real percentage, int totalLines, int duplicateLines] duplication) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexity_dist);
    
    // Duplication rating
    str duplicationRating = rateDuplication(duplication.percentage);
    
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

str calculateTestabilityScore(tuple[real, real, real, real] complexity_dist,
    map[str, int] unitSizes) {
    
    // Complexity rating
    str complexityRating = rateComplexity(complexity_dist);
    
    // Unit size rating
    str unitSizeRating = rateUnitSize(unitSizes);
    
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
