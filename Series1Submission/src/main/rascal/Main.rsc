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
import MetricScores;

// Define project location based on the project path
int main(loc projectLocation = |home:///Documents/UVA_SE/SE/series0/hsqldb-2.3.1|) {
    // smallsql0.21_src
    // hsqldb-2.3.1

    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    list[Declaration] asts = getASTs(projectLocation);

    // All code lines without comments and blank lines
    list[str] allLines = getAllLines(asts);
    
    // Calculate volume
    int volume = calculateVolumeWithoutComments(allLines);

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
    println("Unit size counts [low, moderate, high, very high]: " + 
        "\<<unitSizeDistribution[0]>, <unitSizeDistribution[1]>, " +
        "<unitSizeDistribution[2]>, <unitSizeDistribution[3]>\>");
    println("Lines per category [low, moderate, high, very high]: " + 
        "\<<unitSizeDistribution[4]>, <unitSizeDistribution[5]>, " +
        "<unitSizeDistribution[6]>, <unitSizeDistribution[7]>\>");
    println("Unit size distribution [low%, moderate%, high%, very high%]: " + 
        "\<<unitSizePercentages[0]>, <unitSizePercentages[1]>, <unitSizePercentages[2]>, <unitSizePercentages[3]>\>");

    // Calculate complexity distribution
    tuple[int, int, int, int, int, int, int, int] complexityDistribution = calculateComplexityDistribution(asts);
    
    // Calculate percentages for risk categories of complexity
    tuple[real, real, real, real] complexityPercentages = calculateComplexityPercentages(complexityDistribution, volume);
    
    println("Unit complexity counts [low, moderate, high, very high]: \<<complexityDistribution[0]>, <complexityDistribution[1]>, <complexityDistribution[2]>, <complexityDistribution[3]>\>");
    println("Lines per category [low, moderate, high, very high]: \<<complexityDistribution[4]>, <complexityDistribution[5]>, <complexityDistribution[6]>, <complexityDistribution[7]>\>");
    println("Complexity distribution [low%, moderate%, high%, very high%]: \<<complexityPercentages[0]>, <complexityPercentages[1]>, <complexityPercentages[2]>, <complexityPercentages[3]>\>");
    
    // Calculate duplication
    tuple[real percentage, int totalLines, int duplicateLines] duplicationResult = calculateDuplication(allLines);
    println("Duplication percentage: <duplicationResult.percentage>");
    println("Duplicate lines found: <duplicationResult.duplicateLines>");

    // Individual metric scores

    // Volume
    println("\nIndividual Metric Scores:");
    println("Volume: <rateVolume(volume)>");
    
    // Unit Size
    println("Unit Size: <rateUnitSize(unitSizePercentages)>");
    
    // Complexity
    println("Unit Complexity: <rateComplexity(complexityPercentages)>");
    
    // Duplication
    println("Duplication: <rateDuplication(duplicationResult[0])>");
    
    // Maintainability scores
    str analysabilityScore = calculateAnalysabilityScore(volume, duplicationResult, unitSizePercentages);
    str changeabilityScore = calculateChangeabilityScore(complexityPercentages, duplicationResult);
    str testabilityScore = calculateTestabilityScore(complexityPercentages, unitSizePercentages);
    str maintainabilityScore = calculateMaintainabilityScore(analysabilityScore, changeabilityScore, testabilityScore);
    
    println("Analysability score:  <analysabilityScore>");
    println("Changeability score:  <changeabilityScore>");
    println("Testability score:    <testabilityScore>");
    println("Maintainability score: <maintainabilityScore>");
    return 0;
}
