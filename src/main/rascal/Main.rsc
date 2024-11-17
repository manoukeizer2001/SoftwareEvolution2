module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;
import BasicMetricsCalculation;
import MaintainabilityAspectsScores;

int main(int testArgument=0) {
    // smallsql0.21_src
    // hsqldb-2.3.1
    loc projectLocation = |home:///Documents/UVA_SE/SE/series0/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    // Calculate volume
    int volume = calculateVolumeWithoutComments(asts);

    println("Volume without comments: <volume>");

     // Calculate unit sizes
    map[str, int] unitSizes = calculateUnitSize(asts);
    
    // Get distribution of units and lines for unit sizes
    tuple[int count_low, int count_moderate, int count_high, int count_veryHigh,
          int lines_low, int lines_moderate, int lines_high, int lines_veryHigh] unitSizeDistribution = 
        calculateUnitSizeDistribution(unitSizes);
    
    // Calculate percentages for risk categories of unit sizes
    tuple[real, real, real, real] unitSizePercentages = calculateUnitSizePercentages(unitSizeDistribution, volume);
    
    println("\nUnit Size Analysis:");
    println("Unit counts [low, moderate, high, very high]: " + 
        "\<<unitSizeDistribution[0]>, <unitSizeDistribution[1]>, " +
        "<unitSizeDistribution[2]>, <unitSizeDistribution[3]>\>");
    println("Lines per category [low, moderate, high, very high]: " + 
        "\<<unitSizeDistribution[4]>, <unitSizeDistribution[5]>, " +
        "<unitSizeDistribution[6]>, <unitSizeDistribution[7]>\>");
    println("Unit size distribution [low%, moderate%, high%, very high%]: " + 
        "\<<unitSizePercentages[0]>, <unitSizePercentages[1]>, <unitSizePercentages[2]>, <unitSizePercentages[3]>\>");
    
    // Calculate duplication
    tuple[real percentage, int totalLines, int duplicateLines] duplicationResult = calculateDuplication(asts);
    println("Duplication percentage: <precision(duplicationResult.percentage, 2)>%");
    println("Total lines analyzed: <duplicationResult.totalLines>");
    println("Duplicate lines found: <duplicationResult.duplicateLines>");

    // Calculate complexity distribution
    tuple[int, int, int, int, int, int, int, int] complexityDistribution = calculateComplexityDistribution(asts);
    
    // Calculate percentages for risk categories of complexity
    tuple[real, real, real, real] complexityPercentages = calculateComplexityPercentages(complexityDistribution, volume);
    
    println("Unit counts [low, moderate, high, very high]: \<<complexityDistribution[0]>, <complexityDistribution[1]>, <complexityDistribution[2]>, <complexityDistribution[3]>\>");
    println("Lines per category [low, moderate, high, very high]: \<<complexityDistribution[4]>, <complexityDistribution[5]>, <complexityDistribution[6]>, <complexityDistribution[7]>\>");
    println("Complexity distribution [low%, moderate%, high%, very high%]: \<<complexityPercentages[0]>, <complexityPercentages[1]>, <complexityPercentages[2]>, <complexityPercentages[3]>\>");
    
    return testArgument;
}

