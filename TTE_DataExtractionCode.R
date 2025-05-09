library(readxl)
library(stringr)
library(tidyverse)
library(openxlsx)

# Specify the file path
excel_file_path <- '/Users/Nischal/TTE_DataExtraction/echo_deidentified.xlsx'

# Read the Excel file into a DataFrame
df <- read_excel(excel_file_path)

# Initialize an empty list
output_list <- list()

# Initialize file_counter
file_counter <- 0

# Loop through rows of the data frame
for (index in seq(nrow(df))) {
  file_counter <- file_counter + 1  # Increment the counter for each file processed
  
  # Assuming your CSV column name containing text is "EchoReportText"
  echo_report_text <- as.character(df$PROCEDURE_REPORT[index])
  
  # Check if the text is a float and convert to string if necessary
  if (is.na(echo_report_text) || is.null(echo_report_text)) {
    echo_report_text <- ""
  }
  
  # Remove line breaks from the text within the cell
  cleaned_echo_report_text <- gsub('\n', ' ', echo_report_text)
  document_text <- cleaned_echo_report_text
  #Echo Report Number
  cat(sprintf("Echo report %d\n", file_counter))
  
  # Date of Echo
  pattern_date <- "(?:Date.*?)(\\d+\\/\\d+\\/\\d+)"
  match_date <- str_match(document_text, pattern_date)
  
  if (!is.na(match_date[1, 2])) {
    date_of_echo <- match_date[1, 2]
    cat(sprintf("Date: %s\n", date_of_echo))
    output_date <- date_of_echo
  } else {
    cat("Date not found in document.\n")
    output_date <- ""
  }
  
  # AGE
  pattern_age <- "(?:Age:\\s+?)(\\d+)"
  match_age <- str_match(document_text, pattern_age)
  
  if (!is.na(match_age [1, 2])) {
    age <- match_age [1, 2]
    cat(sprintf("Age: %s\n", age))
    output_age <- age
  } else {
    cat("Age not found in the document.\n")
    output_age <- ""
  }
  
  # Blood Pressure
  pattern_bp <- "(?<=BP \\(S\\/D\\):)\\s*(\\d+)(?:\\s*\\/\\s*)(\\d+)"
  matches <- str_match(document_text, pattern_bp)
  
  if (length(matches[1, 2]) > 0) {
    systolic_pressure <- matches[1, 2]
    diastolic_pressure <- matches[1, 3]
    cat(sprintf("BP: %s, %s\n", systolic_pressure, diastolic_pressure))
    output_systolicbp <- systolic_pressure
    output_diastolicbp <- diastolic_pressure
  } else {
    cat("Blood pressure not found in the document.\n")
    output_systolicbp <- ""
    output_diastolicbp <- ""
  }

  # Heart Rate
  pattern_hr <- "(?<=Heart Rate:)(?:\\s+)?(\\d+)"
  match_hr <- str_match(document_text, pattern_hr)
  
  if (!is.na(match_hr[1, 2])) {
    heart_rate <- match_hr[1, 2]
    cat(sprintf("HR: %s\n", heart_rate))
    output_hr <- heart_rate
  } else {
    cat("Heart rate not found in document.\n")
    output_hr <- ""
  }
  
  #BSA 
  pattern_bsa <- "BSA\\D*(\\d+\\.\\d+)"
  match_bsa <- str_match(document_text, pattern_bsa)   
  
  if (!is.na(match_bsa[1, 2])) {
    bsa <- match_bsa[1, 2]
    cat(sprintf("BSA: %s\n", bsa))
    output_bsa <- bsa
  } else {
    cat("BSA not found in document.\n")
    output_bsa <- ""
  }
  
  #LA Size
  
  # Pattern 1
  pattern_LAsize_1 <- "(?:left atrium|left atrial size)(?:\\sis)?(?:\\sindexed)?(?:\\sto)?\\s([Nn]ot well seen|[Ll]ikely normal|[Nn]ormal|mildly to moderately|Mildly to moderately|mildly - moderately|mildly-moderately|mildly|Mildly|moderately to severely|moderately - severely|moderately-severely|moderately|Moderately|severely|very severely|elongated)(?:\\sdilated)?"
  matches_LAsize_1 <- str_match_all(document_text, pattern_LAsize_1)
  num_matches_LAsize_1 <- length(matches_LAsize_1[[1]])
  
  # Pattern 2
  pattern_LAsize_2 <- "(?:CONCLUSIONS.*?)(Mildly to moderately|Mildly - moderately|Mildly-moderately|Mildly|Moderately to severely|Moderately - severely|Moderately-severely|Moderately|Severely|Elongated)(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s&)?(?:\\sleft)(?:\\sand)?(?:\\s&)?(?:\\sright)?(?:\\satrium)"
  matches_LAsize_2 <- regmatches(document_text, regexec(pattern_LAsize_2, document_text, ignore.case = TRUE))
  num_matches_LAsize_2 <- length(matches_LAsize_2[[1]])
  
  # Pattern 3
  pattern_LAsize_3 <- "(mild to moderate|mild - moderate|mild-moderate|mild|moderate to severe|moderate - severe|moderate-severe|moderate|severe|elongated)(?:\\s\\w+)?(?:\\s\\w+)?\\s(?:atrial|diatrial|biatrial|di-atrial|bi-atrial)(?:\\senlargement)"
  matches_LAsize_3 <- regmatches(document_text, regexec(pattern_LAsize_3, document_text, ignore.case = TRUE))
  num_matches_LAsize_3 <- length(matches_LAsize_3[[1]])
  
  output_LAsizeError <- ""
  
  # Check for no matches
  if (num_matches_LAsize_1 == 0 && num_matches_LAsize_2 == 0 && num_matches_LAsize_3 == 0) {
    cat("LA Size: No matches found for any pattern.\n")
    output_LAsize <- "No matches found for any pattern"
  } else if (num_matches_LAsize_3 > 1 && num_matches_LAsize_1 == 0 && num_matches_LAsize_2 == 0) {
    matches_lower_LAsize_3 <- sapply(matches_LAsize_3[[1]], function(match) tolower(match[1]))
    if (all(matches_lower_LAsize_3 == matches_lower_LAsize_3[1])) {
      cat(sprintf("LA Size: %s\n", matches_LAsize_3[[1]][1]))
      output_LAsize <- sprintf("%s", matches_LAsize_3[[1]][1])
    } else {
      non_identical_matches <- sapply(matches_LAsize_3[[1]], function(match) tolower(match[1]))
      cat("LA Size: Error, multiple non-identical matches found.\n")
      cat("Non-identical matches:\n")
      output_LAsize <- sprintf("%s", tolower(non_identical_matches[1]))
      for (non_identical_match in non_identical_matches) {
        cat(sprintf("%s\n", non_identical_match))
        output_LAsizeError <- sprintf("%s%s", output_LAsizeError, non_identical_match)
      }
    }
  } else {
    match_LAsize_1 <- tolower(matches_LAsize_1[[1]][, 2])
    
    # Case when match for pattern 1 is "mildly" or "normal"
    if (any(match_LAsize_1 %in% c("mildly", "normal", "not well seen", "likely normal"))) {
      cat(sprintf("LA Size: %s\n", paste(match_LAsize_1, collapse = ", ")))
      output_LAsize <- paste(match_LAsize_1, collapse = ", ")
    } else {
      # Case when match for pattern 1 is not "mildly" or "normal"
      if (num_matches_LAsize_1 > 1 && num_matches_LAsize_2 == 0 && num_matches_LAsize_3 == 0) {
        if (all(match_LAsize_1 == match_LAsize_1[1])) {
          cat(sprintf("LA Size: %s\n", match_LAsize_1[1]))
          output_LAsize <- match_LAsize_1[1]
        } else {
          cat("Error: non-identical matches found for Pattern 1\n")
          output_LAsize <- sprintf("LA Size: %s", match_LAsize_1)
          output_LAsizeError <- "Error: non-identical matches found for Pattern 1"
        }
      } else if (num_matches_LAsize_1 == 1 && num_matches_LAsize_2 == 0 && num_matches_LAsize_3 == 0) {
        cat("Pattern 2: No match found.\n")
        output_LAsize <- sprintf("LA Size: %s", match_LAsize_1)
        output_LAsizeError <- "Pattern 2: No match found"
      } else if (num_matches_LAsize_1 == 1 && num_matches_LAsize_2 == 0 && num_matches_LAsize_3 == 1) {
        match_LAsize_3 <- tolower(matches_LAsize_3[[1]][, 2])
        if (match_LAsize_1 == match_LAsize_3) {
          cat(sprintf("LA Size: %s\n", match_LAsize_1))
          output_LAsize <- sprintf("%s", match_LAsize_1)
        } else {
          cat(sprintf("Error, non-identical matches. Pattern 1: %s, Pattern 3: %s\n", match_LAsize_1, match_LAsize_3))
          output_LAsize <- sprintf("LA Size: %s", match_LAsize_1)
          output_LAsizeError <- sprintf("Error, non-identical matches. Pattern 1: %s, Pattern 3: %s", match_LAsize_1, match_LAsize_3)
        }
      } else if (num_matches_LAsize_1 == 1 && num_matches_LAsize_2 == 1 && num_matches_LAsize_3 == 0) {
        match_LAsize_2 <- tolower(matches_LAsize_2[[1]][, 1])
        if (match_LAsize_1 == match_LAsize_2) {
          cat(sprintf("LA Size: %s\n", match_LAsize_1))
          output_LAsize <- sprintf("%s", match_LAsize_1)
        } else {
          cat(sprintf("Error, non-identical matches. Pattern 1: %s, Pattern 2: %s\n", match_LAsize_1, match_LAsize_2))
          output_LAsize <- sprintf("LA Size: %s", match_LAsize_1)
          output_LAsizeError <- sprintf("Error, non-identical matches. Pattern 1: %s, Pattern 2: %s", match_LAsize_1, match_LAsize_2)
        }
      }
    }
  }
 
  # Qualitative LV Size
  pattern_LVSize <- "left ventricular cavity size is (normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|very severely|severely|decreased|not well seen|not visualized)(?:\\s+)?(?:dilated|increased)?"
  match_LVSize <- regmatches(document_text, regexec(pattern_LVSize, document_text, ignore.case = TRUE))
  pattern_LVSize2 <- "left ventricle is (not well seen)"
  
  output_LVSize <- ""
  
  if (length(match_LVSize[[1]]) > 0) {
    cat(sprintf("LV Size: %s\n", match_LVSize[[1]][2]))
    output_LVSize <- match_LVSize[[1]][2]
  } else {
    # Check for the second pattern if no matches found for the first pattern
    match_LVSize2 <- regmatches(document_text, regexec(pattern_LVSize2, document_text, ignore.case = TRUE))
    if (length(match_LVSize2[[1]]) > 0) {
      cat(sprintf("LV Size: %s\n", match_LVSize2[[1]][2]))
      output_LVSize <- match_LVSize2[[1]][2]
    } else {
      cat("LV Size: No LV Size match found\n")
      output_LVSize <- ""
    }
  }
  
  # LV Hypertrophy
  LVH_sentence_1 <- "Left Ventricle:.*?([^.]*(?:[hH]ypertrophy)[^.]*).*?(?:Tricuspid Valve:|Pulmonic Valve:|CONCLUSIONS)"
  LVH_match_1 <- str_match(document_text, LVH_sentence_1)
  
  # Initialize outputs
  output_LVHtype <- ""
  output_LVH_Severity <- ""
  output_LVHError <- ""
  
  # Check if a match exists in LVH_match_1
  if (!is.na(LVH_match_1[1, 2])) {
    # Extract LVH type
    LVH_type_pattern <- "([cC]oncentric|[aA]symmetric|[eE]ccentric)"
    LVH_type_match <- str_match(LVH_match_1[1, 2], LVH_type_pattern)
    
    if (!is.na(LVH_type_match[1, 2])) {
      output_LVHtype <- LVH_type_match[1, 2]
    } else {
      output_LVHError <- "Error: No LVH type found"
    }
    
    # Extract LVH severity
    LVH_severity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
    LVH_severity_match <- str_match(LVH_match_1[1, 2], LVH_severity_pattern)
    
    if (!is.na(LVH_severity_match[1, 2])) {
      output_LVH_Severity <- LVH_severity_match[1, 2]
    } else if (output_LVHtype == "") {
      # Add an error only if no LVH type and severity are found
      output_LVHError <- "Error: No LVH type or severity found"
    }
    
  } else {
    # Error if no match at all for hypertrophy
    output_LVHError <- "Error: No mention of hypertrophy"
  }
  
  # Print results for debugging
  cat("LVH Type:", output_LVHtype, "\n")
  cat("LVH Severity:", output_LVH_Severity, "\n")
  cat("LVH Error:", output_LVHError, "\n")
  
  
  # LV Thickness (wall thickness)
  
  # Define a dictionary of equivalent values
  equivalent_values_dict <- c(
    "moderately" = "moderate",
    "moderately - severely" = "moderate - severe",
    "moderately-severely" = "moderate-severe",
    "moderately to severely" = "moderate to severe",
    "severely" = "severe"
  )
  
  pattern_LVThickness <- "Ventricular wall thickness is (normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|severely)(?:\\s+)?(?:dilated|increased)?"
  match_LVThickness <- regmatches(document_text, regexec(pattern_LVThickness, document_text, ignore.case = TRUE))
  
  output_LVThickness <- ""
  output_LVThicknessError <- ""
  
  if (length(match_LVThickness[[1]]) > 0) {
    match_value <- match_LVThickness[[1]][2]
    
    if (match_value %in% c("normal", "mildly", "mildly to moderately", "mildly - moderately", "mildly-moderately")) {
      cat(sprintf("LV Thickness: %s\n", match_value))
      output_LVThickness <- match_value
    } else if (match_value %in% c("moderately - severely", "moderately-severely", "moderately to severely", "moderately", "severely")) {
      pattern_LVThickness2 <- "(moderate - severe|moderate-severe|moderate to severe|moderate|severe) \\w+? left ventricular Thickness"
      match_LVThickness2 <- regmatches(document_text, regexec(pattern_LVThickness2, document_text, ignore.case = TRUE))
      
      if (length(match_LVThickness2[[1]]) > 0) {
        equivalent_value <- equivalent_values_dict[tolower(match_value)]
        
        if (equivalent_value == tolower(match_LVThickness2[[1]][2])) {
          cat(sprintf("LV Thickness: %s\n", match_value))
          output_LVThickness <- match_value
        } else {
          cat(sprintf("LV Thickness: Non-identical LV Thickness matches found, pattern 1 = %s, pattern 2 = %s\n", match_value, match_LVThickness2[[1]][1]))
          output_LVThickness <- match_value
          output_LVThicknessError <- sprintf("Non-identical LV Thickness matches found, pattern 1 = %s, pattern 2 = %s", match_value, match_LVThickness2[[1]][1])
        }
      } else {
        pattern_LVThickness3 <- "(?:CONCLUSIONS:.*?)Ventricular wall thickness is (moderately - severely|moderately-severely|moderately to severely|moderately|severely)(?:\\s+)?(?:dilated|increased)?"
        match_LVThickness3 <- regmatches(document_text, regexec(pattern_LVThickness3, document_text, ignore.case = TRUE))
        
        if (length(match_LVThickness3[[1]]) > 0) {
          equivalent_value <- equivalent_values_dict[tolower(match_value)]
          
          if (equivalent_value == tolower(match_LVThickness3[[1]][1])) {
            cat(sprintf("LV Thickness: %s\n", match_value))
            output_LVThickness <- match_value
          } else {
            cat(sprintf("LV Thickness: Non-identical LV Thickness matches found, pattern 1 = %s, pattern 3 = %s\n", match_value, match_LVThickness3[[1]][1]))
            output_LVThickness <- match_value
            output_LVThicknessError <- sprintf("Non-identical LV Thickness matches found, pattern 1 = %s, pattern 3 = %s", match_value, match_LVThickness3[[1]][1])
          }
        } else {
          cat("LV Thickness: No match found for pattern 2 & 3\n")
          output_LVThickness <- match_value
          output_LVThicknessError <- "No match found for pattern 2 & 3"
        }
      }
    }
  } else {
    pattern_LVThickness4 <- "(?:There is )?([Nn]o|[Mm]ild to moderate|[Mm]ild - moderate|[Mm]ild-moderate|[Mm]ild|[Mm]oderate - severe|[Mm]oderate-severe|[Mm]oderate to severe|[Mm]oderate|[Ss]evere|[Ee]ccentric)(?:\\s+)?(?:\\w+)?(?:\\s+)?(?:LV|left ventricular)(?:\\sThickness)"
    match_LVThickness4 <- str_match(document_text, pattern_LVThickness4)
    if (!is.na(match_LVThickness4[1, 2])) {
      match_LVT4 <- tolower(match_LVThickness4[1, 2])
      output_LVThickness <- tolower(match_LVT4)
      cat(sprintf("LV Thickness: %s\n", match_LVT4))
    } else {
      cat("LV Thickness: No match found for LV Thickness\n")
      output_LVThicknessError <- "LV Thickness: Error, No match found for LV Thickness"
    }
    
  }
  
  # LVDiD
  pattern_LVDiD <- "LV Diameter in Diastole\\s+?((\\d+\\.\\d?\\d?)|\\d+)"
  match_LVDiD <- regmatches(document_text, regexec(pattern_LVDiD, document_text, perl = TRUE))
  
  output_LVDiDError <- ""
  
  if (length(match_LVDiD[[1]]) > 0) {
    LVDiD <- as.numeric(match_LVDiD[[1]][2])  # Convert the matched string to a numeric
    
    cat(sprintf("LVDiD: %.2f\n", LVDiD))
    
    if (LVDiD > 25) {
      cat("LVDiD: Error, value too high\n")
      output_LVDiD <- sprintf("%.2f", LVDiD)
      output_LVDiDError <- "Error: Value too high"
    } else {
      if (length(match_LVSize[[1]]) > 0) {
        if (LVDiD > 5.7 && tolower(match_LVSize[[1]][1]) == "normal") {
          cat("LVDiD: LVDiD does not match LVSize\n")
          output_LVDiD <- sprintf("%.2f", LVDiD)
          output_LVDiDError <- "LVDiD does not match LVSize"
        } else {
          output_LVDiD <- sprintf("%.2f", LVDiD)
        }
      }
    }
  } else {
    cat("LVDiD: LVDiD not found in the document.\n")
    output_LVDiD <- ""
  }
  
  #LV Function
  
  LVFunctionsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*[Ll]eft ventricular function[^.]*).*CONCLUSIONS"
  LVFunctionsentence_matches_1 <- str_match(document_text, LVFunctionsentence_pattern_1)
  LVFunctionsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*left ventricular function[^.]*)"
  LVFunctionsentence_matches_2 <- str_match(document_text, LVFunctionsentence_pattern_2)
  
  output_LVFunction <- ""
  output_LVFunctionError <- ""
  
  if (!is.na(LVFunctionsentence_matches_1[1, 2]) && !is.na(LVFunctionsentence_matches_2[1, 2])) {
    LVFunctionsentence_1 <- LVFunctionsentence_matches_1 [1, 2]
    LVFunctionsentence_2 <- LVFunctionsentence_matches_2 [1, 2]
    cat(sprintf("LVFunction Sentence 1: %s\n", LVFunctionsentence_1))
    cat(sprintf("LVFunction Sentence 2: %s\n", LVFunctionsentence_2))
    LVFunction_1_pattern <- "(low (?:\\s+)?normal|normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|severely|hyperdynamic|preserved|reduced)"
    LVFunction_1_match <- str_match(LVFunctionsentence_1, LVFunction_1_pattern)
    LVFunction_2_pattern <- "(Low (?:\\s+)?normal|low (?:\\s+)?normal|Normal|normal|Mildly to moderately|mildly to moderately|Mildly - moderately|mildly - moderately|Mildly-moderately|mildly-moderately|Mildly|mildly|Moderately - severely|moderately - severely|Moderately-severely|moderately-severely|Moderately to severely|moderately to severely|Moderately|moderately|Severely|severely|Hyperdynamic|hyperdynamic|Preserved|preserved|Reduced|reduced)"
    LVFunction_2_match <- str_match(LVFunctionsentence_2, LVFunction_2_pattern)
    if (!is.na(LVFunction_1_match [1, 2]) && !is.na(LVFunction_2_match [1, 2])){
      LVFunction_1 <- LVFunction_1_match [1, 2]
      LVFunction_2 <- tolower(LVFunction_2_match [1, 2])
      if (LVFunction_1 == LVFunction_2) {
        output_LVFunction <- LVFunction_1_match [1, 2]
        cat(sprintf("LV Function: %s\n", LVFunction_1))
      } else {
        output_LVFunction <- LVFunction_1
        cat(sprintf("LV Function: %s\n", LVFunction_1))
        output_LVFunctionError <- "LV Function: Error, non-matching findings"
      }
    } else {
      cat("LV Function: Error, no LV Function categorization found within either of LV function sentences")
      output_LVFunction <- ""
      output_LVFunctionError <- "LV Function: Error, no LV Function categorization found within either LV function sentence"
    }
  } else if (!is.na(LVFunctionsentence_matches_1[1, 2]) && is.na(LVFunctionsentence_matches_2[1, 2])){
    LVFunctionsentence_1 <- LVFunctionsentence_matches_1 [1, 2]
    cat(sprintf("LVFunction Sentence 1: %s\n", LVFunctionsentence_1))
    LVFunction_1_pattern <- "(low (?:\\s+)?normal|normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|severely|hyperdynamic|preserved|reduced)"
    LVFunction_1_match <- str_match(LVFunctionsentence_1, LVFunction_1_pattern)
    if (!is.na(LVFunction_1_match [1, 2])){
      output_LVFunction <- LVFunction_1_match [1, 2]
      output_LVFunctionError <- "LV Function in conlusions not found"
    } 
  } else {
    pattern_LVdysfunction <- "(LV dysfunction is diffuse|diffuse LV dysfunction)"
    matches_LVdysfunction <- str_match(document_text, pattern_LVdysfunction)
    if (!is.na(matches_LVdysfunction [1, 2])) {
      output_LVFunction <- matches_LVdysfunction [1, 2]
      cat(sprintf("LVFunction: %s\n", matches_LVdysfunction [1, 2]))
    } else {
      cat("LV Function Sentence: not found in the document.\n")
      output_LVFunction <- ""
      output_LVFunctionError <- "LV Function sentence not found in the document."
    }
  }
  
  #Simpson's LVEF
  
  simpson_pattern <- "([^.]*Simpson's[^.]*)"
  simpson_matches <- str_match(document_text, simpson_pattern)
  
  output_simpsonLVEF <- ""
  output_simpsonError <- ""
  
  if (!is.na(simpson_matches [1, 2])) {
    simpson <- simpson_matches [1, 2]
    cat(sprintf("Simpson's Sentence: %s\n", simpson))
    PercentLVEFpattern <- "(\\d+)(?:\\s+)?%"
    PercentLVEF <- str_match(simpson, PercentLVEFpattern)
    if (!is.na(PercentLVEF [1, 2])) {
      cat(sprintf("Simpson's LVEF: %s\n", PercentLVEF [1, 2]))
      output_simpsonLVEF <- PercentLVEF [1, 2]
    } else {
      cat("Simpson's LVEF: Error, no LVEF found")
      output_simpsonLVEF <- ""
      output_simpsonError <- "Simpson's LVEF: Error, no LVEF found"
    }
  } else {
    cat("Simpson Sentence: not found in the document.\n")
    output_simpsonLVEF <- ""
    output_simpsonError <- "Simpson sentence not found in the document."
  }
  
  # LVEF Extraction Script
  
  # Define patterns for LVEF extraction
  pattern_LVEF_1 <- "(?:Visual Est LVEF\\D*)(\\d+)(?:\\s+)?%"
  pattern_LVEF_2 <- "CONCLUSIONS:.*?([^.]*(?:\\bLV|left\\sventricular|Left\\sventricular)[^.]*(?:EF|ejection\\sfraction)[^.]*).*?"
  
  # Extract matches for both patterns
  matches_LVEF_1 <- str_match(document_text, pattern_LVEF_1)
  sentence_LVEF_2 <- str_match(document_text, pattern_LVEF_2)[, 2]
  
  # Initialize output variables
  output_LVEF <- ""
  output_LVEFError <- ""
  
  # Define patterns to extract range of digits and greater/less than values
  pattern_range <- "(\\d+)(?:\\s*-\\s*|\\s*to\\s*)(\\d+)"
  pattern_greater <- "(greater than\\s|>)(?:\\s*)(\\d+)"
  pattern_less <- "(less than\\s|<)(?:\\s*)(\\d+)"
  
  # Extract range or greater/less than values from the sentence
  if (!is.na(sentence_LVEF_2)) {
    matches_range <- str_match(sentence_LVEF_2, pattern_range)
    matches_greater <- str_match(sentence_LVEF_2, pattern_greater)
    matches_less <- str_match(sentence_LVEF_2, pattern_less)
    
    if (!is.na(matches_range[1, 2])) {
      lvef_range <- paste(matches_range[1, 2], "-", matches_range[1, 3])
      first_digit <- matches_range[1, 2]
    } else if (!is.na(matches_greater[1, 3])) {
      lvef_range <- paste0(matches_greater[1, 2], matches_greater[1, 3])
      first_digit <- matches_greater[1, 3]
    } else if (!is.na(matches_less[1, 3])) {
      lvef_range <- paste0(matches_less[1, 2], matches_less[1, 3])
      first_digit <- matches_less[1, 3]
    } else {
      lvef_range <- NA
      first_digit <- NA
    }
  } else {
    lvef_range <- NA
    first_digit <- NA
  }
  
  # Logic to check and compare LVEF values
  if (!is.na(matches_LVEF_1[1, 2])) {
    if (!is.na(first_digit)) {
      if (matches_LVEF_1[1, 2] == first_digit) {
        cat(sprintf("LVEF: %s\n", lvef_range))
        output_LVEF <- lvef_range
      } else {
        cat(sprintf("LVEF: Different 2D Echo measurement value and conclusions value found. Visually Est LVEF%%: %s, Conclusions: %s\n", matches_LVEF_1[1, 2], lvef_range))
        output_LVEF <- lvef_range
        output_LVEFError <- sprintf("Different 2D Echo measurement value and conclusions found. Visually Est LVEF%%: %s, Conclusions: %s", matches_LVEF_1[1, 2], lvef_range)
      }
    } else {
      cat(sprintf("LVEF: Error, no LVEF range found in conclusions %s\n", matches_LVEF_1[1, 2]))
      output_LVEF <- matches_LVEF_1[1, 2]
      output_LVEFError <- "Error, no LVEF range found in conclusions"
    }
  } else {
    if (!is.na(lvef_range)) {
      cat(sprintf("LVEF: %s\n", lvef_range))
      output_LVEF <- lvef_range
    } else {
      cat("LVEF: Error, no LVEF% matches found for pattern_LVEF_1 and no range found in conclusions\n")
      output_LVEF <- ""
      output_LVEFError <- "Error, no LVEF found for pattern 1 and no range found in conclusions"
    }
  }
  
  # Output variables can be used as needed
  print(output_LVEF)
  print(output_LVEFError)
  
  #RA Size
  pattern_RAsize_1_test <- "(?:right atrium|Right atrium|right atrial size|Right atrial size) is.*?(not well seen|severely|normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately to severely|moderately - severely|moderately-severely|moderately|severely|elongated).*?(?:dilated)?"
  matches_RAsize_1_test <- str_match(document_text, pattern_RAsize_1_test)
  
  output_RASizeError <- ""
  
  if (!is.na(matches_RAsize_1_test [1, 2])) {
    RASize <- tolower(matches_RAsize_1_test [1, 2])
    if (RASize %in% c("mildly", "normal", "not well seen", "likely normal")) {
      cat(sprintf("RA Size: %s\n", RASize))
      output_RAsize <- sprintf("%s", RASize)
    } 
    else {
      pattern_RAsize_2_test <- "CONCLUSIONS.*?([^.]*(?:Right atrium|right atrium|Right atrial size|right atrial size|diatrial|Diatrial|biatrial|Biatrial|di-atrial|Di-atrial|bi-atrial|Bi-atrial|Atria|atria\\b)[^.]*?)"
      RAConclusions_Sentence <- str_match(document_text, pattern_RAsize_2_test)
      if (!is.na(RAConclusions_Sentence [1, 2])) {
        cat(sprintf("RA Conclusions Sentence: %s\n", RAConclusions_Sentence [1, 2]))
        patternConclusions_RA <- "(not well seen|normal|Normal|mildly to moderately|Mildly to moderately|mildly - moderately|Mildly - moderately|mildly-moderately|Mildly-moderately|mildly|Mildly|moderately to severely|Moderately to severely|moderately - severely|Moderately - severely|moderately-severely|Moderately-severely|moderately|Moderately|Severely|severely|Elongated|elongated)"
        matchesConclusions_RA <- str_match(RAConclusions_Sentence [1, 2], patternConclusions_RA)
        if (!is.na(matchesConclusions_RA [1, 2])) {
          cat(sprintf("RA Size Conclusions: %s\n", matchesConclusions_RA [1, 2]))
          RAConclusions_lower <- tolower(matchesConclusions_RA [1, 2])
          RASize_lower <- tolower(RASize)
          if (RAConclusions_lower == RASize_lower) {
            cat(sprintf("RA Size: %s\n", RASize_lower))
            output_RAsize <- sprintf("%s", RASize_lower)
          } else {
            cat(sprintf("RA Size: %s\n", RASize_lower ))
            output_RAsize <- sprintf("%s", RASize_lower)
            output_RASizeError <- sprintf("RA Size Error - non-identical matches found. Doppler: %s, Conclusions: %s", RASize_lower, RAConclusions_lower)
          }
        }
      } else {
        cat("RA Conclusions Sentence not found\n")
        output_RAsize <- sprintf("%s", RASize)
        output_RASizeError <- sprintf("No conclusions RA size sentence found\n")
      }
    }
  } else {
    cat("RA Size in Doppler not found\n")
    output_RAsize <- "No RA Size found in Doppler section"
    output_RASizeError <- "No RA Size found in Doppler section"
  }
  
  #IVC Size
  pattern_IVCSize <- "Venous:.*?([^.]*(?:IVC)[^.]*).*?(CONCLUSIONS)"
  match_IVCSize <- str_match(document_text, pattern_IVCSize)
  
  output_IVCSize <- ""
  output_IVCSizeError <- ""
  
  if (!is.na(match_IVCSize [1, 2])) {
    pattern_IVCSizeCategory <- "(?i)([Nn]ot well seen|[Nn]ot clearly seen|[Nn]ot well seen|[Nn]ot clearly seen|[Nn]ot visualized|[Nn]ot clearly visualized|[Nn]ot well visualized|could [Nn]ot be determined|could [Nn]ot be assessed|could [Nn]ot be ascertained|[Nn]ot acquired|[Nn]ot assessed|[Nn]ot determined|upper normal to mildly dilated|normal|upper normal|mild(?:ly)?-moderate(?:ly)? dilated|mild(?:ly)? - moderate(?:ly)? dilated|mild(?:ly)? to moderate(?:ly)? dilated|mild(?:ly)? dilated|moderate(?:ly)?-severe(?:ly)? dilated|moderate(?:ly)? - severe(?:ly)? dilated|moderate(?:ly)? to severe(?:ly)? dilated|moderate(?:ly)? dilated|severe(?:ly)? dilated|dilated|small|no\\b|not dilated)"
    match_IVCSize_1 <- str_match(match_IVCSize [1, 2], pattern_IVCSizeCategory)
    
    if (!is.na(match_IVCSize_1 [1, 2])) {
      output_IVCSize <- match_IVCSize_1 [1, 2]
    } else {
      output_IVCSize <- ""
      output_IVCSizeError <- "Error: No categorization of IVC Size found in the IVC sentence"
    }
  } else {
    output_IVCSize <- ""
    output_IVCSizeError <- "Error: No IVC sentence found"
  }
    
    cat("IVC Size:", output_IVCSize, "\n")
    cat("IVC Size Error:", output_IVCSizeError, "\n")
    
  #IVC Collapsibility
    pattern_IVCCollapsibility_sentence <- "Venous:.*?([^.]*(?:IVC)[^.]*).*?(CONCLUSIONS)"
    match_IVCCollapsibility <- str_match(document_text, pattern_IVCCollapsibility_sentence)
    
    # Initialize output variables
    output_IVCCollapsibility <- ""
    output_IVCCollapsibilityError <- ""
    
    # Check if the main pattern was matched
    if (!is.na(match_IVCCollapsibility[1, 2])) {
      pattern_IVCCollapsibility <- "(?i)(without collapse|50)"
      match_IVCCollapsibility_1 <- str_match(match_IVCCollapsibility[1, 2], pattern_IVCCollapsibility)
      
      if (!is.na(match_IVCCollapsibility_1[1, 2])) {
        if (tolower(match_IVCCollapsibility_1[1, 2]) == "without collapse") {
          # Directly assign "without collapse"
          output_IVCCollapsibility <- "without collapse"
        } else if (match_IVCCollapsibility_1[1, 2] == "50") {
          # If "50" is found, look for "<" or ">"
          pattern_CollapsibilityComparison <- "(<|>)\\s*50"
          match_CollapsibilityComparison <- str_match(match_IVCCollapsibility[1, 2], pattern_CollapsibilityComparison)
          
          if (!is.na(match_CollapsibilityComparison[1, 2])) {
            # Include the comparison (e.g., "< 50" or "> 50") in the output
            output_IVCCollapsibility <- paste0(match_CollapsibilityComparison[1, 2], "50")
          } else {
            # If no "<" or ">" is found, return an error
            output_IVCCollapsibilityError <- "Error: No comparison (< or >) found with 50"
          }
        }
      } else {
        # If no match for collapsibility pattern
        output_IVCCollapsibility <- ""
        output_IVCCollapsibilityError <- "Error: No collapsibility found"
      }
    } else {
      # If no match for the main sentence pattern
      output_IVCCollapsibilityError <- "Error: IVC sentence not found"
    }
    
    # Print the outputs
    cat("Output IVC Collapsibility:", output_IVCCollapsibility, "\n")
    cat("Output IVC Collapsibility Error:", output_IVCCollapsibilityError, "\n")
    
  
  #IVC RA Pressure   
  # Define the main pattern for extracting the relevant sentence
  pattern_IVC_RAPressure <- "Venous:.*?([^.]*(?:IVC)[^.]*).*?(CONCLUSIONS)"
  match_IVC_RAPressure <- str_match(document_text, pattern_IVC_RAPressure)
  
  # Initialize output variables
  output_IVC_RAPressure <- ""
  output_IVC_RAPressureError <- ""
  
  # Check if the main pattern was matched
  if (!is.na(match_IVC_RAPressure[1, 2])) {
    # Step 1: Look for "low normal" or "normal"
    pattern_IVC_RAP <- "(low normal|normal|low|elevated|increased)"
    match_IVC_RAP <- str_match(match_IVC_RAPressure[1, 2], pattern_IVC_RAP)
    
    if (!is.na(match_IVC_RAP[1, 2])) {
      # If "low normal" or "normal" is found, assign it to the output
      output_IVC_RAPressure <- match_IVC_RAP[1, 2]
    } else {
      # Step 2: Look for a pressure range like "10-15"
      pattern_IVC_PressureRange <- "(\\d+\\s?-\\s?\\d+)"
      match_IVC_PressureRange <- str_match(match_IVC_RAPressure[1, 2], pattern_IVC_PressureRange)
      
      if (!is.na(match_IVC_PressureRange[1, 2])) {
        # If a pressure range is found, assign it to the output
        output_IVC_RAPressure <- match_IVC_PressureRange[1, 2]
      } else {
        # Step 3: Look for "RAP of" or "RA pressure of" followed by anything until the period
        pattern_IVC_RAP_Fallback <- "(?:RAP|RA pressure)(?:\\sof)?\\s*([^.]*)"
        match_IVC_RAP_Fallback <- str_match(match_IVC_RAPressure[1, 2], pattern_IVC_RAP_Fallback)
        
        if (!is.na(match_IVC_RAP_Fallback[1, 2])) {
          # Extract the part after "RAP of" or "RA pressure of"
          output_IVC_RAPressure <- match_IVC_RAP_Fallback[1, 2]
        } else {
          # If no fallback pattern matches, assign an error message
          output_IVC_RAPressureError <- "Error: No valid IVC RA Pressure information found"
        }
      }
    }
  } else {
    # If no match for the main sentence pattern
    output_IVC_RAPressure <- ""
    output_IVC_RAPressureError <- "Error: IVC sentence not found"
  }
  
  # Print the outputs
  cat("Output IVC RAPressure:", output_IVC_RAPressure, "\n")
  cat("Output IVC RAPressure Error:", output_IVC_RAPressureError, "\n")
  
  # Assumed right atrial pressure - add else statement for when PA systolic pressure is not assessed
  pattern_AssumedRAP <- "right atrial pressure of (\\d+(?:\\.\\d+)?) mmHg"
  match_AssumedRAP <- str_match(document_text, pattern_AssumedRAP)
  
  output_AssumedRAP <- ""
  
  
  if (!is.na(match_AssumedRAP[1, 2])) {
    AssumedRA_pressure <- match_AssumedRAP [1, 2]
    cat(sprintf("RAP: %s\n", AssumedRA_pressure))
    output_AssumedRAP <- AssumedRA_pressure
  } else {
    output_AssumedRAP <- ""
  } 
  
  #RV Function
  
  RVFunctionsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Global RV|Global right ventricular|RVSF)(?:\\ssystolic\\sfunction|\\sfunction)[^.]*).*CONCLUSIONS"
  RVFunctionsentence_matches_1 <- str_match(document_text, RVFunctionsentence_pattern_1)
  RVFunctionsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Right ventricular|right ventricular|RV)(?:\\ssystolic)?(?:\\sfunction)[^.]*)"
  RVFunctionsentence_matches_2 <- str_match(document_text, RVFunctionsentence_pattern_2)
  
  output_RVFunction <- ""
  output_RVFunctionError <- ""
  
  if (!is.na(RVFunctionsentence_matches_1 [1, 2])) {
    RVFunctionsentence_1 <- RVFunctionsentence_matches_1 [1, 2]
    cat(sprintf("RVFunction Sentence 1: %s\n", RVFunctionsentence_1))
    RVFunction_1_pattern <- "(low (?:\\s+)?normal|normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|severely|hyperdynamic|could not be assessed|could not be adequately assessed|could not be adequately assesed|reduced|not well seen|could not be performed)"
    RVFunction_1_match <- str_match(RVFunctionsentence_1, RVFunction_1_pattern)
    
    if (!is.na(RVFunction_1_match [1, 2])) {
      RVFunction_1 <- RVFunction_1_match [1, 2]
      if (RVFunction_1 == "low normal" | RVFunction_1 == "normal" | RVFunction_1 == "hyperdynamic") {
        output_RVFunction <- RVFunction_1
        cat(sprintf("RV Function: %s\n", RVFunction_1))
      } else {
        if (!is.na(RVFunctionsentence_matches_2 [1, 2])) {
          RVFunctionsentence_2 <- RVFunctionsentence_matches_2 [1, 2]
          RVFunction_2_pattern <- "(Low (?:\\s+)?normal|low (?:\\s+)?normal|Normal|normal|Mildly to moderately|mildly to moderately|Mildly - moderately|mildly - moderately|Mildly-moderately|mildly-moderately|Mildly|mildly|Moderately - severely|moderately - severely|Moderately-severely|moderately-severely|Moderately to severely|moderately to severely|Moderately|moderately|Severely|severely|Hyperdynamic|hyperdynamic)"
          RVFunction_2_match <- str_match(RVFunctionsentence_2, RVFunction_2_pattern)
          if (!is.na(RVFunction_2_match [1, 2])) {
            RVFunction_2 <- tolower(RVFunction_2_match [1, 2])
            if (RVFunction_1 == RVFunction_2) {
              cat(sprintf("RV Function: %s\n", RVFunction_1))
              output_RVFunction <- RVFunction_1
            } else {
              cat("RV Function: Error, non-matching findings")
              output_RVFunction <- RVFunction_1 
              output_RVFunctionError <- "RV Function: Error, non-matching findings"
            }
          } else {
            cat("RV Function: Error, no RV function categorization found in conclusions RV function sentence")
            output_RVFunction <- RVFunction_1 
            output_RVFunctionError <- "RV Function: Error, no RV function categorization found in conclusions RV function sentence"
          }
          
        } else {
          cat("RV Function: Error, no RV Function conclusions sentence found")
          output_RVFunction <- RVFunction_1 
          output_RVFunctionError <- "RV Function: Error, no RV Function conclusions sentence found"
        }
      }
    } else {
      cat("RV Function: Error, no RV Function categorization found in doppler sentence")
      output_RVFunction <- ""
      output_RVFunctionError <- "RV Function: Error, no RV Function categorization found in doppler sentence"
    }
    
    
  } else {
    cat("RV Function: Error, no RV Function doppler sentence found")
    output_RVFunction <- ""
    output_RVFunctionError <- "RV Function: Error, no RV Function doppler sentence found"
  }
  
  
  # Mitral Regurgitation
  
  MRsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Mitral valve regurgitation|mitral valve regurgitation|[Mm]itral regurgitation)[^.]*).*CONCLUSIONS"
  MRsentence_matches_1 <- str_match(document_text, MRsentence_pattern_1)
  MRsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Mitral valve regurgitation|mitral valve regurgitation|Mitral regurgitation|mitral regurgitation)[^.]*)"
  MRsentence_matches_2 <- str_match(document_text, MRsentence_pattern_2)
  MRsentence_pattern_3 <- "Mitral Valve:.*?([^.]*(?i)(?:valvular regurgitation|regurgitation)[^.]*).*Tricuspid Valve:"
  
  output_MR <- ""
  output_MRError <- ""
  
  if (!is.na(MRsentence_matches_1[1, 2])) {
    MRsentence_1 <- MRsentence_matches_1[1, 2]
    cat(sprintf("MR Sentence 1: %s\n", MRsentence_1))
    MR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    MR_1_match <- str_match(MRsentence_1, MR_1_pattern)
    
    if (!is.na(MR_1_match[1, 2])) {
      MR_1 <- tolower(MR_1_match[1, 2])
      if (MR_1 == "no" | MR_1 == "trivial" | MR_1 == "mild" | MR_1 == "mild-moderate" | MR_1 == "mild - moderate" | MR_1 == "mild to moderate" | MR_1 == "not assessed" | MR_1 == "shadowing from the prosthesis") {
        output_MR <- MR_1
        cat(sprintf("MR: %s\n", MR_1))
      } else {
        if (!is.na(MRsentence_matches_2[1, 2])) {
          MRsentence_2 <- MRsentence_matches_2[1, 2]
          MR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          MR_2_match <- str_match(MRsentence_2, MR_2_pattern)
          if (!is.na(MR_2_match[1, 2])) {
            MR_2 <- tolower(MR_2_match[1, 2])
            if (MR_1 == MR_2) {
              cat(sprintf("MR: %s\n", MR_1))
              output_MR <- MR_1
            } else {
              cat("MR: Error, non-matching findings")
              output_MR <- MR_1 
              output_MRError <- "MR: Error, non-matching findings"
            }
          } else {
            cat("MR: Error, no MR categorization found in conclusions MR sentence")
            output_MR <- MR_1 
            output_MRError <- "MR: Error, no MR categorization found in conclusions MR sentence"
          }
          
        } else {
          cat("MR: Error, no MR conclusions sentence found")
          output_MR <- MR_1 
          output_MRError <- "MR: Error, no MR conclusions sentence found"
        }
      }
    } else {
      cat("MR: Error, no MR categorization found in doppler sentence")
      output_MR <- ""
      output_MRError <- "MR: Error, no MR categorization found in doppler sentence"
    }
    
    
  } else {
    # New pattern matching when no MR doppler sentence found
    MRsentence_matches_3 <- str_match(document_text, MRsentence_pattern_3)
    if (!is.na(MRsentence_matches_3[1, 2])) {
      MRsentence_3 <- MRsentence_matches_3[1, 2]
      cat(sprintf("MR Sentence 3: %s\n", MRsentence_3))
      MR_3_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
      MR_3_match <- str_match(MRsentence_3, MR_3_pattern)
      if (!is.na(MR_3_match[1, 2])) {
        output_MR <- tolower(MR_3_match[1, 2])
        cat(sprintf("MR: %s\n", output_MR))
      } else {
        cat("MR: Error, no MR categorization found in MR sentence 3")
        output_MRError <- "MR: Error, no MR categorization found in MR sentence 3"
      }
    } else {
      cat("MR: Error, no MR doppler sentence found")
      output_MR <- ""
      output_MRError <- "MR: Error, no MR doppler sentence found"
    }
  }
  
  # Mitral Valve Structure
  
  MVStructurePatterns <- list(
    "Mitral Valve:.*?([^.]*(?:Mitral valve|mitral valve)(?:\\sis|\\sappears|\\sValve|\\sgrossly|\\snot well seen|\\shas a|\\sabnormal|\\sthickened|\\sthickening)[^.]*).*?(?:Tricuspid Valve:)",
    "Mitral Valve:.*?([^.]*(?:mitral valve leaflets)[^.]*).*?(?:Tricuspid Valve:)"
  )
  
  output_MVStructure <- ""
  output_MVStructureError <- ""
  
  for (pattern in MVStructurePatterns) {
    MVStructureMatches <- str_match(document_text, pattern)
    if (!is.na(MVStructureMatches[1, 2])) {
      MVStructuresentence <- MVStructureMatches[1, 2]
      cat(sprintf("MV Structure Sentence: %s\n", MVStructuresentence))
      
      # Pattern 1: Check grossly normal and similar phrases
      MVStructure_1_pattern <- "(grossly normal|Grossly normal|normal|Normal|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|rheumatic)(?:\\sthickened|\\sthickening)?"
      MVStructure_1_match <- str_match(MVStructuresentence, MVStructure_1_pattern)
      
      if (!is.na(MVStructure_1_match[1, 2])) {
        output_MVStructure <- tolower(MVStructure_1_match[1, 2])
        cat(sprintf("MV Structure: %s\n", output_MVStructure))
      } else {
        # Pattern 3: Check "thickened" or "thickening"
        MVStructure_3_pattern <- "(thickened|thickening)"
        MVStructure_3_match <- str_match(MVStructuresentence, MVStructure_3_pattern)
        
        if (!is.na(MVStructure_3_match[1, 2])) {
          # Pattern 2: Check severity levels
          MVStructure_2_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
          MVStructure_2_match <- str_match(MVStructuresentence, MVStructure_2_pattern)
          
          if (!is.na(MVStructure_2_match[1, 2])) {
            output_MVStructure <- paste(MVStructure_2_match[1, 2], MVStructure_3_match[1, 2], sep = " ")
          } else {
            output_MVStructure <- MVStructure_3_match[1, 2]
          }
          cat(sprintf("MV Structure: %s\n", output_MVStructure))
        } else {
          cat("Error: No valid descriptors found in mitral valve sentence\n")
          output_MVStructureError <- "Error: No valid descriptors found in mitral valve sentence"
        }
      }
      
      break  # Stop processing further patterns once a match is found
    }
  }
  
  if (output_MVStructure == "" && output_MVStructureError == "") {
    cat("Error: No valid descriptors found in mitral valve sentence\n")
    output_MVStructureError <- "Error: No valid descriptors found in mitral valve sentence"
  }
  
  #MV Motion
  
  # Define a single comprehensive pattern for SAM and systolic anterior motion
  MVMotion_pattern <- "(?i)([^.]*?(?: SAM\\b|systolic anterior motion)[^.]*)(?:\\.\\s|$)"
  
  # Extract all matches for SAM or systolic anterior motion
  MVMotion_matches <- str_match_all(document_text, MVMotion_pattern)[[1]]
  
  # Initialize the output variable
  output_MVMotion <- ""
  
  # Process matches
  if (length(MVMotion_matches) > 0) {
    # Combine all matched sentences, ensuring no duplication
    output_MVMotion <- paste(unique(MVMotion_matches[, 2]), collapse = ". ")
  }
  
  # Output result
  cat("MV Motion:", output_MVMotion, "\n")
  
  #MV Implant
  MVimplant_pattern <- "Mitral Valve:.*?(Bioprosthetic|bioprosthetic|mechanical|Mechanical|Prosthesis|prosthesis|Prosthetic|prosthetic).*?(?:Tricuspid valve|tricuspid valve)"
  MVimplant_matches <- str_match(document_text, MVimplant_pattern)
  
  output_MVimplant <- ""
  
  if (!is.na(MVimplant_matches [1, 2])) {
    MVimplant <- MVimplant_matches [1, 2]
    output_MVimplant <- MVimplant
  } else {
    output_MVimplant <- ""
  }
  cat("MV Implant:", output_MVimplant, "\n")
  
  #MV Leaflet Number
  
  MVLeafletNumber_pattern <- "Mitral Valve:.*?(Trileaflet|trileaflet|Tricuspid|tricuspid|Bicuspid|bicuspid|Bileaflet|bileaflet).*?(?:Tricuspid Valve:)"
  MVLeafletNumber_matches <- str_match(document_text, MVLeafletNumber_pattern)
  
  output_MVLeafletNumber <- ""
  
  if (!is.na(MVLeafletNumber_matches [1, 2])) {
    MVLeafletNumber <- MVLeafletNumber_matches [1, 2]
    output_MVLeafletNumber <- MVLeafletNumber
  } else {
    output_MVLeafletNumber <- ""
  }
  
  cat("MV Leaflet Number:", output_MVLeafletNumber, "\n")
  
  #MV Sclerosis
  
  MVSclerosis_pattern <- "Mitral Valve:.*?(mild(?:ly)?-moderate(?:ly)?|Mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|Mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|Mild(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|moderate(?:ly)?-severe(?:ly)?|Moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|Moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|severe(?:ly)?|Severe(?:ly)?|no\\b|No\\b|not)\\s(?:sclerotic|Sclerotic|sclerosis|Sclerosis).*?(?:Tricuspid Valve:)"
  MVSclerosis_match <- str_match(document_text, MVSclerosis_pattern)
  
  output_MVSclerosis <- ""
  
  if (!is.na(MVSclerosis_match[1, 2])) {
    output_MVSclerosis <- MVSclerosis_match [1, 2]
  } else {
    output_MVSclerosis <- ""
  }
  cat("MV Sclerosis:", output_MVSclerosis, "\n")
  
  #MV Calcification
  
  # Define the pattern to extract all sentences containing "calcification" or "calcified" between "Mitral Valve:" and "Tricuspid Valve:"
  MVCalcificationsentence_pattern <- "Mitral Valve:(.*?)Tricuspid Valve:"
  MVCalcification_section <- str_match(document_text, MVCalcificationsentence_pattern)
  
  # Initialize output variables
  output_MVCalcification <- ""
  output_MVAnnularCalcification <- ""
  output_MVSubvalvularCalcification <- ""
  output_MVCalcificationError <- ""
  
  if (!is.na(MVCalcification_section[1, 2])) {
    # Extract individual sentences containing "calcification" or "calcified"
    calcification_sentences <- unlist(str_extract_all(MVCalcification_section[1, 2], "[^.!?]*\\b(?:calcification|calcified|Calcification|Calcified)\\b[^.!?]*[.!?]"))
    
    # Remove sentences mentioning anterior/posterior leaflet involvement
    leaflet_pattern <- "(anterior and posterior leaflet(?:s)?|posterior and anterior leaflet(?:s)?|anterior leaflet|posterior leaflet)"
    filtered_sentences <- calcification_sentences[!grepl(leaflet_pattern, calcification_sentences, ignore.case = TRUE)]
    
    if (length(filtered_sentences) > 1) {
      # More than one relevant sentence remains
      output_MVCalcificationError <- "More than one sentence found containing calcification."
    } else if (length(filtered_sentences) == 1) {
      # Only one sentence remains, analyze severity and type
      MVCalcificationpattern <- "([mM]ild to moderate|[mM]ild - moderate|[mM]ild-moderate|[mM]ild|[mM]oderate to severe|[mM]oderate - severe|[mM]oderate-severe|[mM]oderate|[sS]evere|[nN]o\\b)\\s(?:\\w+\\s)?(annular|subvalvular)?"
      MVCalcification_match <- str_match(filtered_sentences, MVCalcificationpattern)
      
      if (!is.na(MVCalcification_match[1, 2])) {
        if (!is.na(MVCalcification_match[1, 3])) {
          if (MVCalcification_match[1, 3] == "annular") {
            output_MVAnnularCalcification <- MVCalcification_match[1, 2]
          } else if (MVCalcification_match[1, 3] == "subvalvular") {
            output_MVSubvalvularCalcification <- MVCalcification_match[1, 2]
          }
        } else {
          output_MVCalcification <- MVCalcification_match[1, 2]
        }
      } else {
        output_MVCalcificationError <- "No categorization found in the remaining sentence."
      }
    } else {
      # No relevant sentences found
      output_MVCalcificationError <- "No valid calcification sentences found."
    }
  }
  
  cat("MV Annular Calcification:", output_MVAnnularCalcification, "\n")
  cat("MV Subvalvular Calcification:", output_MVSubvalvularCalcification, "\n")
  cat("MV Calcification:", output_MVCalcification, "\n")
  cat("MV Calcification Error:", output_MVCalcificationError, "\n")
  
  #MV Leaflet Mobility
  
  # Step 1: Find the sentence containing 'mitral leaflet mobility/motion/movement'
  # Bound the search to end at "Tricuspid Valve:"
  MVLeafletSentence_pattern <- "Mitral Valve:.*?([^.!?]*(?i)(?:mitral leaflet\\s)(?:mobility|motion|movement)[^.]*).*?(?:Tricuspid Valve:)"
  
  # Capture the full sentence
  MVLeafletSentence_match <- str_match(document_text, MVLeafletSentence_pattern)
  
  # Initialize the output variable
  output_MVLeafletMobility <- ""
  output_MVLeafletMobilityError <- ""
  
  # Step 2: If the sentence was found, search for descriptors and severity in that sentence
  if (!is.na(MVLeafletSentence_match[1, 2])) {
    
    # Define the pattern to find descriptors in the sentence
    MVLeafletDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
    
    # Search for a match for the descriptors in the sentence
    MVLeafletDescriptor_match <- str_match(MVLeafletSentence_match[1, 2], MVLeafletDescriptor_pattern)
    
    if (!is.na(MVLeafletDescriptor_match[1, 2])) {
      
      # Define the severity pattern that might appear before the descriptor
      Severity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
      
      # Search for a match for the severity before the descriptor
      Severity_match <- str_match(MVLeafletSentence_match[1, 2], Severity_pattern)
      
      if (!is.na(Severity_match[1, 2])) {
        # Concatenate the severity with the descriptor
        output_MVLeafletMobility <- paste(Severity_match[1, 2], MVLeafletDescriptor_match[1, 2])
      } else {
        # If no severity found, just use the descriptor
        output_MVLeafletMobility <- MVLeafletDescriptor_match[1, 2]
      }
      
      cat("Mitral Leaflet Mobility Descriptor:", output_MVLeafletMobility, "\n")
    } else {
      cat("No descriptor found in sentence.\n")
      output_MVLeafletMobility <- ""
      output_MVLeafletMobilityError <- "Error: no descriptor found in mitral leaflet mobility sentence"
    }
  } else {
    cat("Mitral Leaflet Mobility sentence not found.\n")
    output_MVLeafletMobility <- ""
  }
  
  cat("MV Leaflet Mobility:", output_MVLeafletMobility, "\n")
  cat("MV Leaflet Mobility Error:", output_MVLeafletMobilityError, "\n")
  
  # MV Anterior Leaflet Mobility
  
  # Step 1: Find the sentence containing 'anterior leaflet'
  # Bound the search to end at "Tricuspid Valve:"
  MVALMSentence_pattern <- "Mitral Valve:.*?([^.!?]*(?i)(?:anterior leaflet)[^.]*).*?(?:Tricuspid Valve:)"
  
  # Capture the full sentence
  MVALMSentence_match <- str_match(document_text, MVALMSentence_pattern)
  
  # Initialize the output variable
  output_MVALM <- ""
  output_MVALMError <- ""
  
  # Step 2: If the sentence was found, check for 'mobility', 'motion', or 'movement'
  if (!is.na(MVALMSentence_match[1, 2])) {
    
    # Define the pattern to find 'mobility', 'motion', or 'movement' in the sentence
    MVALM_pattern2 <- "(?i)(mobility|motion|movement)"
    
    # Search for a match for 'mobility', 'motion', or 'movement' in the sentence
    MVALM_match2 <- str_match(MVALMSentence_match[1, 2], MVALM_pattern2)
    
    if (!is.na(MVALM_match2[1, 2])) {
      
      # Define the pattern to find descriptors in the sentence
      MVALMDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
      
      # Search for a match for the descriptors in the sentence
      MVALMDescriptor_match <- str_match(MVALMSentence_match[1, 2], MVALMDescriptor_pattern)
      
      if (!is.na(MVALMDescriptor_match[1, 2])) {
        
        # Define the severity pattern that might appear before the descriptor
        MVALMSeverity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
        
        # Search for a match for the severity before the descriptor
        MVALMSeverity_match <- str_match(MVALMSentence_match[1, 2], MVALMSeverity_pattern)
        
        if (!is.na(MVALMSeverity_match[1, 2])) {
          # Concatenate the severity with the descriptor
          output_MVALM <- paste(MVALMSeverity_match[1, 2], MVALMDescriptor_match[1, 2])
        } else {
          # If no severity found, just use the descriptor
          output_MVALM <- MVALMDescriptor_match[1, 2]
        }
        
        cat("Mitral Anterior Leaflet Mobility Descriptor:", output_MVALM, "\n")
      } else {
        cat("No descriptor found in sentence.\n")
        output_MVALM <- ""
        output_MVALMError <- "Error: no descriptor found in mitral anterior leaflet mobility sentence"
      }
    } else {
      cat("Mobility/Motion/Movement not found in the sentence.\n")
      output_MVALM <- ""
    }
  } else {
    cat("Anterior Leaflet sentence not found.\n")
    output_MVALM <- ""
  }
  
  cat("MVALM:", output_MVALM, "\n")
  cat("MVALM Error:", output_MVALMError, "\n")
  
  # MV Posterior Leaflet Mobility
  
  # Step 1: Find the sentence containing 'posterior leaflet'
  # Bound the search to end at "Tricuspid Valve:"
  MVPLMSentence_pattern <- "Mitral Valve:.*?([^.!?]*(?i)(?:posterior leaflet)[^.]*).*?(?:Tricuspid Valve:)"
  
  # Capture the full sentence
  MVPLMSentence_match <- str_match(document_text, MVPLMSentence_pattern)
  
  # Initialize the output variable
  output_MVPLM <- ""
  output_MVPLMError <- ""
  
  # Step 2: If the sentence was found, check for 'mobility', 'motion', or 'movement'
  if (!is.na(MVPLMSentence_match[1, 2])) {
    
    # Define the pattern to find 'mobility', 'motion', or 'movement' in the sentence
    MVPLM_pattern2 <- "(?i)(mobility|motion|movement)"
    
    # Search for a match for 'mobility', 'motion', or 'movement' in the sentence
    MVPLM_match2 <- str_match(MVPLMSentence_match[1, 2], MVPLM_pattern2)
    
    if (!is.na(MVPLM_match2[1, 2])) {
      
      # Define the pattern to find descriptors in the sentence
      MVPLMDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
      
      # Search for a match for the descriptors in the sentence
      MVPLMDescriptor_match <- str_match(MVPLMSentence_match[1, 2], MVPLMDescriptor_pattern)
      
      if (!is.na(MVPLMDescriptor_match[1, 2])) {
        
        # Define the severity pattern that might appear before the descriptor
        MVPLMSeverity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
        
        # Search for a match for the severity before the descriptor
        MVPLMSeverity_match <- str_match(MVPLMSentence_match[1, 2], MVPLMSeverity_pattern)
        
        if (!is.na(MVPLMSeverity_match[1, 2])) {
          # Concatenate the severity with the descriptor
          output_MVPLM <- paste(MVPLMSeverity_match[1, 2], MVPLMDescriptor_match[1, 2])
        } else {
          # If no severity found, just use the descriptor
          output_MVPLM <- MVPLMDescriptor_match[1, 2]
        }
        
        cat("Mitral Posterior Leaflet Mobility Descriptor:", output_MVPLM, "\n")
      } else {
        cat("No descriptor found in sentence.\n")
        output_MVPLM <- ""
        output_MVPLMError <- "Error: no descriptor found in mitral posterior leaflet mobility sentence"
      }
    } else {
      cat("Mobility/Motion/Movement not found in the sentence.\n")
      output_MVPLM <- ""
    }
  } else {
    cat("Posterior Leaflet sentence not found.\n")
    output_MVPLM <- ""
  }
  
  cat("MVPLM:", output_MVPLM, "\n")
  cat("MVPLM Error:", output_MVPLMError, "\n")
  
  
  #MV Anterior and Posterior Leaflet Structures
  
  # Step 1: Search for the sentence containing "anterior leaflet" or "posterior leaflet" or "anterior and posterior leaflets"
  leaflet_sentence_pattern <- "Mitral Valve:.*?([^.!?]*(?i)(?:anterior and posterior leaflets|anterior leaflet|posterior leaflet)[^.]*).*?(?:Tricuspid Valve:|Pulmonic Valve:|CONCLUSIONS)"
  
  # Capture the full sentence
  leaflet_sentence_match <- str_match(document_text, leaflet_sentence_pattern)
  
  # Initialize output variables
  output_anteriorleafletstructure <- ""
  output_posteriorleafletstructure <- ""
  output_leafletstructure_error <- ""
  
  # Step 2: If the sentence with "anterior and posterior leaflets" or "anterior leaflet" or "posterior leaflet" is found
  if (!is.na(leaflet_sentence_match[1, 2])) {
    
    # Define the pattern to find severity descriptors (mild, moderate, severe, etc.)
    severity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|heav(?:il)?y|extensive(?:ly)?|dense(?:ly)?|nodular|no\\b|not\\b)\\s(?:thickened and\\/or calcified|thickened\\/calcified|thickening and\\/or calcification|thickening\\/calcification|thickened|calcified|thickening|calcification)"
    
    # Search for severity in the sentence
    severity_match <- str_match(leaflet_sentence_match[1, 2], severity_pattern)
    
    # Define the new structure pattern to capture phrases like 'thickened and/or calcified', etc.
    structure_pattern <- "(?i)(thickened and\\/or calcified|thickened\\/calcified|thickening and\\/or calcification|thickening\\/calcification|thickened|calcified|thickening|calcification)"
    
    # Search for structure descriptor in the sentence
    structure_match <- str_match(leaflet_sentence_match[1, 2], structure_pattern)
    
    # If a structure descriptor is found
    if (!is.na(structure_match[1, 2])) {
      
      # Convert the structure descriptor to lowercase
      structure_descriptor <- tolower(structure_match[1, 2])
      
      # If both severity and structure descriptor are found, concatenate them
      if (!is.na(severity_match[1, 2])) {
        concatenated_structure <- paste(severity_match[1, 2], structure_descriptor)
      } else {
        # If only structure descriptor is found, use it alone and set the error message
        concatenated_structure <- structure_descriptor
        output_leafletstructure_error <- "Severity descriptor missing."
      }
      
      # If "anterior and posterior leaflets" is found, assign to both
      if (grepl("anterior and posterior leaflets?", leaflet_sentence_match[1, 2])) {
        output_anteriorleafletstructure <- concatenated_structure
        output_posteriorleafletstructure <- concatenated_structure
      }
      # If only "anterior leaflet" is found, assign to output_anteriorleafletstructure
      else if (grepl("anterior leaflet", leaflet_sentence_match[1, 2])) {
        output_anteriorleafletstructure <- concatenated_structure
      }
      # If only "posterior leaflet" is found, assign to output_posteriorleafletstructure
      else if (grepl("posterior leaflet", leaflet_sentence_match[1, 2])) {
        output_posteriorleafletstructure <- concatenated_structure
      }
      
      cat("Anterior Leaflet Structure:", output_anteriorleafletstructure, "\n")
      cat("Posterior Leaflet Structure:", output_posteriorleafletstructure, "\n")
      
    } else {
      # If structure descriptor is not found
      output_leafletstructure_error <- "Error: Missing structure descriptor."
      cat(output_leafletstructure_error, "\n")
    }
  } else {
    # If the sentence with "anterior leaflet" or "posterior leaflet" is not found
    output_leafletstructure_error <- "Error: 'anterior leaflet' or 'posterior leaflet' not found."
    cat(output_leafletstructure_error, "\n")
  }
  
  cat("Output Anterior Leaflet Structure:", output_anteriorleafletstructure, "\n")
  cat("Output Posterior Leaflet Structure:", output_posteriorleafletstructure, "\n")
  cat("Leaflet Structure Error:", output_leafletstructure_error, "\n")
  
  #Mitral Valve Stenosis
  
  MVStenosissentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Mitral valve stenosis|mitral valve stenosis|Mitral stenosis|mitral stenosis)[^.]*).*CONCLUSIONS"
  MVStenosissentence_matches_1 <- str_match(document_text, MVStenosissentence_pattern_1)
  MVStenosissentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Mitral valve stenosis|mitral valve stenosis|Mitral stenosis|mitral stenosis)[^.]*)"
  MVStenosissentence_matches_2 <- str_match(document_text, MVStenosissentence_pattern_2)
  
  output_MVStenosis <- ""
  output_MVStenosisError <- ""
  
  if (!is.na(MVStenosissentence_matches_1 [1, 2])) {
    MVStenosissentence_1 <- MVStenosissentence_matches_1 [1, 2]
    cat(sprintf("MV Stenosis Sentence 1: %s\n", MVStenosissentence_1))
    MVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    MVStenosis_1_match <- str_match(MVStenosissentence_1, MVStenosis_1_pattern)
    
    if (!is.na(MVStenosis_1_match [1, 2])) {
      MVStenosis_1 <- tolower(MVStenosis_1_match [1, 2])
      if (MVStenosis_1 == "no" | MVStenosis_1 == "trivial"|MVStenosis_1 == "trace") {
        output_MVStenosis <- MVStenosis_1
        cat(sprintf("MV Stenosis: %s\n", MVStenosis_1))
      } else {
        if (!is.na(MVStenosissentence_matches_2 [1, 2])) {
          MVStenosissentence_2 <- MVStenosissentence_matches_2 [1, 2]
          MVStenosis_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          MVStenosis_2_match <- str_match(MVStenosissentence_2, MVStenosis_2_pattern)
          if (!is.na(MVStenosis_2_match [1, 2])) {
            MVStenosis_2 <- tolower(MVStenosis_2_match [1, 2])
            if (MVStenosis_1 == MVStenosis_2) {
              cat(sprintf("MV Stenosis: %s\n", MVStenosis_1))
              output_MVStenosis <- MVStenosis_1
            } else {
              cat("MV Stenosis: Error, non-matching findings")
              output_MVStenosis <- MVStenosis_1 
              output_MVStenosisError <- "MVStenosis: Error, non-matching findings"
            }
          } else {
            cat("MVStenosis: Error, no MV Stenosis categorization found in conclusions MV Stenosis sentence")
            output_MVStenosis <- MVStenosis_1 
            output_MVStenosisError <- "MV Stenosis: Error, no MV Stenosis categorization found in conclusions MV Stenosis sentence"
          }
          
        } else {
          cat("MV Stenosis: Error, no MV Stenosis conclusions sentence found")
          output_MVStenosis <- MVStenosis_1 
          output_MVStenosisError <- "MV Stenosis: Error, no MV Stenosis conclusions sentence found"
        }
      }
    } else {
      cat("MV Stenosis: Error, no MV Stenosis categorization found in doppler sentence")
      output_MVStenosis <- ""
      output_MVStenosisError <- "MV Stenosis: Error, no MV Stenosis categorization found in doppler sentence"
    }
    
    
  } else {
    cat("MV Stenosis: Error, no MV Stenosis doppler sentence found")
    output_MVStenosis <- ""
    output_MVStenosisError <- "MVStenosis: Error, no MVStenosis doppler sentence found"
  }
  
  #TR Velocity
  
  pattern_TRvelocity <- "(?:tricuspid regurgitant velocity is)\\s+(\\d+\\.\\d+)"
  match_TRvelocity <- str_match(document_text, pattern_TRvelocity)
  
  output_TRvelocity <- ""
  
  if (!is.na(match_TRvelocity[1, 1])) {
    TR_velocity <- match_TRvelocity[1, 2]
    cat(sprintf("TR Velocity: %s\n", TR_velocity))
    output_TRvelocity <- sprintf("%s", TR_velocity)
  } else {
    cat("TR Velocity: Tricuspid regurgitant velocity not found in the document.\n")
    output_TRvelocity <- ""
  }
  
  # Aortic Regurgitation
  
  ARsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Aortic valve regurgitation|aortic valve regurgitation|Aortic regurgitation|aortic regurgitation|Aortic insufficiency|aortic insufficiency|Aortic valve insufficiency|aortic valve insufficiency)[^.]*).*CONCLUSIONS"
  ARsentence_matches_1 <- str_match(document_text, ARsentence_pattern_1)
  ARsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Aortic valve regurgitation|aortic valve regurgitation|Aortic regurgitation|aortic regurgitation|Aortic insufficiency|aortic insufficiency|Aortic valve insufficiency|aortic valve insufficiency)[^.]*)"
  ARsentence_matches_2 <- str_match(document_text, ARsentence_pattern_2)
  ARsentence_pattern_3 <- "Aortic Valve:.*?([^.]*(?i)(?:valvular regurgitation|regurgitation)[^.]*).*Mitral Valve:"
  
  output_AR <- ""
  output_ARError <- ""
  
  if (!is.na(ARsentence_matches_1[1, 2])) {
    ARsentence_1 <- ARsentence_matches_1[1, 2]
    cat(sprintf("AR Sentence 1: %s\n", ARsentence_1))
    AR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    AR_1_match <- str_match(ARsentence_1, AR_1_pattern)
    
    if (!is.na(AR_1_match[1, 2])) {
      AR_1 <- tolower(AR_1_match[1, 2])
      if (AR_1 == "no" | AR_1 == "trivial" | AR_1 == "mild" | AR_1 == "mild-moderate" | AR_1 == "mild - moderate" | AR_1 == "mild to moderate" | AR_1 == "not assessed" | AR_1 == "shadowing from the prosthesis") {
        output_AR <- AR_1
        cat(sprintf("AR: %s\n", AR_1))
      } else {
        if (!is.na(ARsentence_matches_2[1, 2])) {
          ARsentence_2 <- ARsentence_matches_2[1, 2]
          AR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          AR_2_match <- str_match(ARsentence_2, AR_2_pattern)
          if (!is.na(AR_2_match[1, 2])) {
            AR_2 <- tolower(AR_2_match[1, 2])
            if (AR_1 == AR_2) {
              cat(sprintf("AR: %s\n", AR_1))
              output_AR <- AR_1
            } else if (AR_1 == "trace" && AR_2 == "trivial") {
              cat(sprintf("AR: %s\n", AR_2))
              output_AR <- AR_2
            } else {
              cat(sprintf("AR Error - non-identical matches found. Doppler: %s, Conclusions: %s\n", AR_1, AR_2))
              output_AR <- AR_1 
              output_ARError <- sprintf("AR Error - non-identical matches found. Doppler: %s, Conclusions: %s\n", AR_1, AR_2)
            }
          } else {
            cat("AR: Error, no AR categorization found in conclusions AR sentence\n")
            output_AR <- AR_1 
            output_ARError <- "AR: Error, no AR categorization found in conclusions AR sentence"
          }
          
        } else {
          if (AR_1 == "trace") {
            cat("AR: trace\n")
            output_AR <- AR_1
          } else {
            cat("AR: Error, no AR conclusions sentence found\n")
            output_AR <- AR_1 
            output_ARError <- "AR: Error, no AR conclusions sentence found"
          }
        }
      }
    } else {
      cat("AR: Error, no AR categorization found in doppler sentence\n")
      output_AR <- ""
      output_ARError <- "AR: Error, no AR categorization found in doppler sentence"
    }
    
    
  } else {
    # New pattern matching when no AR doppler sentence found
    ARsentence_matches_3 <- str_match(document_text, ARsentence_pattern_3)
    if (!is.na(ARsentence_matches_3[1, 2])) {
      ARsentence_3 <- ARsentence_matches_3[1, 2]
      cat(sprintf("AR Sentence 3: %s\n", ARsentence_3))
      AR_3_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
      AR_3_match <- str_match(ARsentence_3, AR_3_pattern)
      if (!is.na(AR_3_match[1, 2])) {
        output_AR <- tolower(AR_3_match[1, 2])
        cat(sprintf("AR: %s\n", output_AR))
      } else {
        cat("AR: Error, no AR categorization found in AR sentence 3")
        output_ARError <- "AR: Error, no AR categorization found in AR sentence 3"
      }
    } else {
      cat("AR: Error, no AR doppler sentence found\n")
      output_AR <- ""
      output_ARError <- "AR: Error, no AR doppler sentence found"
    }
  }
  
  # Aortic Valve Structure
  
  AVStructurePatterns <- list(
    "Aortic Valve:.*?([^.]*(?:Aortic valve|aortic valve)(?:\\sis|\\sappears|\\sValve|\\sgrossly|\\snot well seen|\\shas a|\\sabnormal|\\sthickened|\\sthickening)[^.]*).*?(?:Mitral Valve:|Tricuspid Valve:|Pulmonic Valve:|CONCLUSIONS)"
  )
  
  output_AVStructure <- ""
  output_AVStructureError <- ""
  
  for (pattern in AVStructurePatterns) {
    AVStructureMatches <- str_match(document_text, pattern)
    if (!is.na(AVStructureMatches[1, 2])) {
      AVStructuresentence <- AVStructureMatches[1, 2]
      cat(sprintf("AV Structure Sentence: %s\n", AVStructuresentence))
      
      # Pattern 1: Check grossly normal and similar phrases
      AVStructure_1_pattern <- "(grossly normal|Grossly normal|normal|Normal|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|rheumatic)(?:\\sthickened|\\sthickening)?"
      AVStructure_1_match <- str_match(AVStructuresentence, AVStructure_1_pattern)
      
      if (!is.na(AVStructure_1_match[1, 2])) {
        output_AVStructure <- tolower(AVStructure_1_match[1, 2])
        cat(sprintf("AV Structure: %s\n", output_AVStructure))
      } else {
        # Pattern 3: Check "thickened" or "thickening"
        AVStructure_3_pattern <- "(thickened|thickening)"
        AVStructure_3_match <- str_match(AVStructuresentence, AVStructure_3_pattern)
        
        if (!is.na(AVStructure_3_match[1, 2])) {
          # Pattern 2: Check severity levels
          AVStructure_2_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
          AVStructure_2_match <- str_match(AVStructuresentence, AVStructure_2_pattern)
          
          if (!is.na(AVStructure_2_match[1, 2])) {
            output_AVStructure <- paste(AVStructure_2_match[1, 2], AVStructure_3_match[1, 2], sep = " ")
          } else {
            output_AVStructure <- AVStructure_3_match[1, 2]
          }
          cat(sprintf("AV Structure: %s\n", output_AVStructure))
        } else {
          cat("Error: No valid descriptors found in aortic valve sentence\n")
          output_AVStructureError <- "Error: No valid descriptors found in aortic valve sentence"
        }
      }
      
      break  # Stop processing further patterns once a match is found
    }
  }
  
  if (output_AVStructure == "" && output_AVStructureError == "") {
    cat("AV Structure: Error, no AV Structure doppler sentence found\n")
    output_AVStructureError <- "Error, no AV Structure doppler sentence found"
  }
  
  # AV Implant
  AVimplant_pattern <- "Aortic Valve:.*?(Bioprosthetic|bioprosthetic|mechanical|Mechanical|Prosthesis|prosthesis|Prosthetic|prosthetic).*?(?:Mitral Valve:)"
  AVimplant_matches <- str_match(document_text, AVimplant_pattern)
  
  output_AVimplant <- ""
  
  if (!is.na(AVimplant_matches[1, 2])) {
    AVimplant <- AVimplant_matches[1, 2]
    output_AVimplant <- AVimplant
  } else {
    output_AVimplant <- ""
  }
  cat("AV Implant:", output_AVimplant, "\n")
  
  # AV Leaflet Number
  AVLeafletNumber_pattern <- "Aortic Valve:.*?(Trileaflet|trileaflet|tricuspid|Bicuspid|bicuspid|Bileaflet|bileaflet).*?(?:Mitral Valve:)"
  AVLeafletNumber_matches <- str_match(document_text, AVLeafletNumber_pattern)
  
  output_AVLeafletNumber <- ""
  
  if (!is.na(AVLeafletNumber_matches[1, 2])) {
    AVLeafletNumber <- AVLeafletNumber_matches[1, 2]
    output_AVLeafletNumber <- AVLeafletNumber
  } else {
    output_AVLeafletNumber <- ""
  }
  
  cat("AV Leaflet Number:", output_AVLeafletNumber, "\n")
  
  # AV Sclerosis
  
  AVSclerosis_pattern <- "Aortic Valve:.*?(mild(?:ly)?-moderate(?:ly)?|Mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|Mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|Mild(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|moderate(?:ly)?-severe(?:ly)?|Moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|Moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|severe(?:ly)?|Severe(?:ly)?|no\\b|No\\b|not)\\s(?:sclerotic|Sclerotic|sclerosis|Sclerosis).*?(?:Mitral Valve:)"
  AVSclerosis_match <- str_match(document_text, AVSclerosis_pattern)
  
  output_AVSclerosis <- ""
  
  if (!is.na(AVSclerosis_match[1, 2])) {
    output_AVSclerosis <- AVSclerosis_match[1, 2]
  } else {
    output_AVSclerosis <- ""
  }
  cat("AV Sclerosis:", output_AVSclerosis, "\n")
  
  # AV Calcification
  
  # Define the pattern to extract all text between "Aortic Valve:" and "Mitral Valve:"
  AVCalcificationsentence_pattern <- "Aortic Valve:(.*?)Mitral Valve:"
  AVCalcification_section <- str_match(document_text, AVCalcificationsentence_pattern)
  
  # Initialize output variables
  output_AVCalcification <- ""
  output_AVCalcificationError <- ""
  
  if (!is.na(AVCalcification_section[1, 2])) {
    # Extract sentences containing "calcification" or "calcified"
    calcification_sentences <- unlist(str_extract_all(AVCalcification_section[1, 2], "[^.!?]*\\b(?:calcification|calcified|Calcification|Calcified)\\b[^.!?]*[.!?]"))
    
    # Patterns for leaflet involvement
    leaflet_pattern_remove <- "(?:^|\\s)(?i)(NCC\\b|RCC\\b|LCC\\b|non-coronary cusp|noncoronary cusp|right coronary cusp|left coronary cusp)(?:\\s|$)"  # Remove these
    leaflet_pattern_keep <- "(?:^|\\s)(?i)(aortic valve leaflets|aortic valve|leaflets of the aortic valve)(?:\\s|$)"  # Keep these
    
    # Remove sentences that mention only specified terms
    filtered_sentences <- calcification_sentences[!grepl(leaflet_pattern_remove, calcification_sentences, ignore.case = TRUE) | 
                                                    grepl(leaflet_pattern_keep, calcification_sentences, ignore.case = TRUE)]
    
    if (length(filtered_sentences) > 1) {
      # More than one valid sentence remains
      output_AVCalcificationError <- "More than one sentence found containing calcification."
    } else if (length(filtered_sentences) == 1) {
      # Only one sentence remains, analyze severity
      AVCalcificationpattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|heav(?:il)?y|extensive(?:ly)?|dense(?:ly)?|nodular|no\\b|not\\b)"
      AVCalcification_match <- str_match(filtered_sentences, AVCalcificationpattern)
      
      if (!is.na(AVCalcification_match[1, 2])) {
        output_AVCalcification <- AVCalcification_match[1, 2]  # Store severity
      } else {
        output_AVCalcificationError <- "No categorization found in the remaining sentence."
      }
    } else {
      # No relevant sentences found
      output_AVCalcificationError <- "No valid calcification sentences found."
    }
  }
  
  cat("AV Calcification:", output_AVCalcification, "\n")
  cat("AV Calcification Error:", output_AVCalcificationError, "\n")
  
  # AV Non-Coronary Cusp Mobility
  
  # Step 1: Find the sentence containing 'non-coronary cusp'
  # Bound the search to end at "Mitral Valve:"
  AVNCCMSentence_pattern <- "Aortic Valve:.*?([^.!?]*(?i)(?:non-coronary cusp|non coronary cusp|NCC)[^.]*).*?(?:Mitral Valve:)"
  
  # Capture the full sentence
  AVNCCMSentence_match <- str_match(document_text, AVNCCMSentence_pattern)
  
  # Initialize the output variable
  output_AVNCCM <- ""
  output_AVNCCMError <- ""
  
  # Step 2: If the sentence was found, check for 'mobility', 'motion', or 'movement'
  if (!is.na(AVNCCMSentence_match[1, 2])) {
    
    # Define the pattern to find 'mobility', 'motion', or 'movement' in the sentence
    AVNCCM_pattern2 <- "(?i)(mobility|motion|movement)"
    
    # Search for a match for 'mobility', 'motion', or 'movement' in the sentence
    AVNCCM_match2 <- str_match(AVNCCMSentence_match[1, 2], AVNCCM_pattern2)
    
    if (!is.na(AVNCCM_match2[1, 2])) {
      
      # Define the pattern to find descriptors in the sentence
      AVNCCMDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
      
      # Search for a match for the descriptors in the sentence
      AVNCCMDescriptor_match <- str_match(AVNCCMSentence_match[1, 2], AVNCCMDescriptor_pattern)
      
      if (!is.na(AVNCCMDescriptor_match[1, 2])) {
        
        # Define the severity pattern that might appear before the descriptor
        AVNCCMSeverity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
        
        # Search for a match for the severity before the descriptor
        AVNCCMSeverity_match <- str_match(AVNCCMSentence_match[1, 2], AVNCCMSeverity_pattern)
        
        if (!is.na(AVNCCMSeverity_match[1, 2])) {
          # Concatenate the severity with the descriptor
          output_AVNCCM <- paste(AVNCCMSeverity_match[1, 2], AVNCCMDescriptor_match[1, 2])
        } else {
          # If no severity found, just use the descriptor
          output_AVNCCM <- AVNCCMDescriptor_match[1, 2]
        }
        
        cat("Aortic Non-Coronary Cusp Mobility Descriptor:", output_AVNCCM, "\n")
      } else {
        cat("No descriptor found in sentence.\n")
        output_AVNCCM <- ""
        output_AVNCCMError <- "Error: no descriptor found in aortic non-coronary cusp mobility sentence"
      }
    } else {
      cat("Mobility/Motion/Movement not found in the sentence.\n")
      output_AVNCCM <- ""
    }
  } else {
    cat("Non-Coronary Cusp sentence not found.\n")
    output_AVNCCM <- ""
  }
  
  cat("AVNCCM:", output_AVNCCM, "\n")
  cat("AVNCCM Error:", output_AVNCCMError, "\n")
  
  # AV Right Coronary Cusp Mobility
  
  # Step 1: Find the sentence containing 'right coronary cusp'
  # Bound the search to end at "Mitral Valve:"
  AVRCCMSentence_pattern <- "Aortic Valve:.*?([^.!?]*(?i)(?:right coronary cusp|RCC)[^.]*).*?(?:Mitral Valve:)"
  
  # Capture the full sentence
  AVRCCMSentence_match <- str_match(document_text, AVRCCMSentence_pattern)
  
  # Initialize the output variable
  output_AVRCCM <- ""
  output_AVRCCMError <- ""
  
  # Step 2: If the sentence was found, check for 'mobility', 'motion', or 'movement'
  if (!is.na(AVRCCMSentence_match[1, 2])) {
    
    # Define the pattern to find 'mobility', 'motion', or 'movement' in the sentence
    AVRCCM_pattern2 <- "(?i)(mobility|motion|movement)"
    
    # Search for a match for 'mobility', 'motion', or 'movement' in the sentence
    AVRCCM_match2 <- str_match(AVRCCMSentence_match[1, 2], AVRCCM_pattern2)
    
    if (!is.na(AVRCCM_match2[1, 2])) {
      
      # Define the pattern to find descriptors in the sentence
      AVRCCMDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
      
      # Search for a match for the descriptors in the sentence
      AVRCCMDescriptor_match <- str_match(AVRCCMSentence_match[1, 2], AVRCCMDescriptor_pattern)
      
      if (!is.na(AVRCCMDescriptor_match[1, 2])) {
        
        # Define the severity pattern that might appear before the descriptor
        AVRCCMSeverity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
        
        # Search for a match for the severity before the descriptor
        AVRCCMSeverity_match <- str_match(AVRCCMSentence_match[1, 2], AVRCCMSeverity_pattern)
        
        if (!is.na(AVRCCMSeverity_match[1, 2])) {
          # Concatenate the severity with the descriptor
          output_AVRCCM <- paste(AVRCCMSeverity_match[1, 2], AVRCCMDescriptor_match[1, 2])
        } else {
          # If no severity found, just use the descriptor
          output_AVRCCM <- AVRCCMDescriptor_match[1, 2]
        }
        
        cat("Aortic Right Coronary Cusp Mobility Descriptor:", output_AVRCCM, "\n")
      } else {
        cat("No descriptor found in sentence.\n")
        output_AVRCCM <- ""
        output_AVRCCMError <- "Error: no descriptor found in aortic right coronary cusp mobility sentence"
      }
    } else {
      cat("Mobility/Motion/Movement not found in the sentence.\n")
      output_AVRCCM <- ""
    }
  } else {
    cat("Right Coronary Cusp sentence not found.\n")
    output_AVRCCM <- ""
  }
  
  cat("AVRCCM:", output_AVRCCM, "\n")
  cat("AVRCCM Error:", output_AVRCCMError, "\n")
  
  # AV Left Coronary Cusp Mobility
  
  # Step 1: Find the sentence containing 'left coronary cusp'
  # Bound the search to end at "Mitral Valve:"
  AVLCCMSentence_pattern <- "Aortic Valve:.*?([^.!?]*(?i)(?:left coronary cusp|LCC)[^.]*).*?(?:Mitral Valve:)"
  
  # Capture the full sentence
  AVLCCMSentence_match <- str_match(document_text, AVLCCMSentence_pattern)
  
  # Initialize the output variable
  output_AVLCCM <- ""
  output_AVLCCMError <- ""
  
  # Step 2: If the sentence was found, check for 'mobility', 'motion', or 'movement'
  if (!is.na(AVLCCMSentence_match[1, 2])) {
    
    # Define the pattern to find 'mobility', 'motion', or 'movement' in the sentence
    AVLCCM_pattern2 <- "(?i)(mobility|motion|movement)"
    
    # Search for a match for 'mobility', 'motion', or 'movement' in the sentence
    AVLCCM_match2 <- str_match(AVLCCMSentence_match[1, 2], AVLCCM_pattern2)
    
    if (!is.na(AVLCCM_match2[1, 2])) {
      
      # Define the pattern to find descriptors in the sentence
      AVLCCMDescriptor_pattern <- "(normal|restricted|limited|immobile|reduced|increased|flail|tethered|adhesions|prolapse|deformed)"
      
      # Search for a match for the descriptors in the sentence
      AVLCCMDescriptor_match <- str_match(AVLCCMSentence_match[1, 2], AVLCCMDescriptor_pattern)
      
      if (!is.na(AVLCCMDescriptor_match[1, 2])) {
        
        # Define the severity pattern that might appear before the descriptor
        AVLCCMSeverity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
        
        # Search for a match for the severity before the descriptor
        AVLCCMSeverity_match <- str_match(AVLCCMSentence_match[1, 2], AVLCCMSeverity_pattern)
        
        if (!is.na(AVLCCMSeverity_match[1, 2])) {
          # Concatenate the severity with the descriptor
          output_AVLCCM <- paste(AVLCCMSeverity_match[1, 2], AVLCCMDescriptor_match[1, 2])
        } else {
          # If no severity found, just use the descriptor
          output_AVLCCM <- AVLCCMDescriptor_match[1, 2]
        }
        
        cat("Aortic Left Coronary Cusp Mobility Descriptor:", output_AVLCCM, "\n")
      } else {
        cat("No descriptor found in sentence.\n")
        output_AVLCCM <- ""
        output_AVLCCMError <- "Error: no descriptor found in aortic left coronary cusp mobility sentence"
      }
    } else {
      cat("Mobility/Motion/Movement not found in the sentence.\n")
      output_AVLCCM <- ""
    }
  } else {
    cat("Left Coronary Cusp sentence not found.\n")
    output_AVLCCM <- ""
  }
  
  cat("AVLCCM:", output_AVLCCM, "\n")
  cat("AVLCCM Error:", output_AVLCCMError, "\n")
  
  
  # AV Leaflet Structures (NCC, RCC, LCC)
  
  # Step 1: Extract all sentences containing "noncoronary cusp", "right coronary cusp", "left coronary cusp", or their abbreviations
  AVLS_leaflet_sentence_pattern <- "Aortic Valve:.*?([^.!?]*(?i)(?:noncoronary cusp|non-coronary cusp|NCC|right coronary cusp|RCC|left coronary cusp|LCC)[^.]*).*?(?:Mitral Valve:)"
  AVLS_leaflet_sentences <- unlist(str_extract_all(document_text, AVLS_leaflet_sentence_pattern))
  
  # Initialize output variables
  output_NCC_leafletstructure <- ""
  output_RCC_leafletstructure <- ""
  output_LCC_leafletstructure <- ""
  output_AVleafletstructure_error <- ""
  
  # Define the pattern to find severity descriptors (mild, moderate, severe, etc.)
  AVLS_severity_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|heav(?:il)?y|extensive(?:ly)?|dense(?:ly)?|nodular|no\\b|not\\b)\\s(?:thickened and\\/or calcified|thickened\\/calcified|thickening and\\/or calcification|thickening\\/calcification|thickened|calcified|thickening|calcification)"
  
  # Define the new structure pattern to capture phrases like 'thickened and/or calcified', etc.
  AVLS_structure_pattern <- "(?i)(thickened and\\/or calcified|thickened\\/calcified|thickening and\\/or calcification|thickening\\/calcification|thickened|calcified|thickening|calcification)"
  
  # Process each sentence individually
  for (sentence in AVLS_leaflet_sentences) {
    print(paste("Processing sentence:", sentence))  # Debug print
    
    # Search for severity in the sentence
    AVLS_severity_match <- str_match(sentence, AVLS_severity_pattern)
    print(paste("Severity Match:", AVLS_severity_match[1, 2]))  # Debug print
    
    # Search for structure descriptor in the sentence
    AVLS_structure_match <- str_match(sentence, AVLS_structure_pattern)
    print(paste("Structure Match:", AVLS_structure_match[1, 2]))  # Debug print
    
    # If a structure descriptor is found
    if (!is.na(AVLS_structure_match[1, 2])) {
      # Convert the structure descriptor to lowercase
      AVLS_structure_descriptor <- tolower(AVLS_structure_match[1, 2])
      
      # If both severity and structure descriptor are found, concatenate them
      if (!is.na(AVLS_severity_match[1, 2])) {
        AVLS_concatenated_structure <- paste(AVLS_severity_match[1, 2], AVLS_structure_descriptor)
      } else {
        # If only structure descriptor is found, use it alone and set the error message
        AVLS_concatenated_structure <- AVLS_structure_descriptor
        output_AVleafletstructure_error <- "Severity descriptor missing."
      }
      
      # Check for mentions of each leaflet and assign the concatenated structure
      if (grepl("noncoronary cusp|non-coronary cusp|NCC", sentence, ignore.case = TRUE)) {
        output_NCC_leafletstructure <- AVLS_concatenated_structure
      }
      if (grepl("right coronary cusp|RCC", sentence, ignore.case = TRUE)) {
        output_RCC_leafletstructure <- AVLS_concatenated_structure
      }
      if (grepl("left coronary cusp|LCC", sentence, ignore.case = TRUE)) {
        output_LCC_leafletstructure <- AVLS_concatenated_structure
      }
    } else {
      # If structure descriptor is not found
      output_AVleafletstructure_error <- "Error: Missing structure descriptor."
    }
  }
  
  cat("NCC Leaflet Structure:", output_NCC_leafletstructure, "\n")
  cat("RCC Leaflet Structure:", output_RCC_leafletstructure, "\n")
  cat("LCC Leaflet Structure:", output_LCC_leafletstructure, "\n")
  cat("AV Leaflet Structure Error:", output_AVleafletstructure_error, "\n")
  
  #Aortic Valve Stenosis
  
  AVStenosissentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Aortic valve stenosis|aortic valve stenosis|Aortic stenosis|aortic stenosis)[^.]*).*CONCLUSIONS"
  AVStenosissentence_matches_1 <- str_match(document_text, AVStenosissentence_pattern_1)
  AVStenosissentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Aortic valve stenosis|aortic valve stenosis|Aortic stenosis|aortic stenosis)[^.]*)"
  AVStenosissentence_matches_2 <- str_match(document_text, AVStenosissentence_pattern_2)
  
  output_AVStenosis <- ""
  output_AVStenosisError <- ""
  output_AVGradient <- ""
  output_AVPeakGradient <- ""
  output_AVArea <- ""
  output_LVOTDiameter <- ""
  output_AVPeakVelocity <- ""
  output_AVDimensionlessIndex <- ""
  output_AViSV <- ""
  
  if (!is.na(AVStenosissentence_matches_1 [1, 2])) {
    AVStenosissentence_1 <- AVStenosissentence_matches_1 [1, 2]
    cat(sprintf("AV Stenosis Sentence 1: %s\n", AVStenosissentence_1))
    AVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild\\b|Mild\\b|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate\\b|Moderate\\b|severe\\b|Severe\\b|\\bcritical\\b|no\\b|No\\b|trace\\b|Trace\\b|trivial\\b|Trivial\\b|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    AVStenosis_1_match <- str_match(AVStenosissentence_1, AVStenosis_1_pattern)
    
    if (!is.na(AVStenosis_1_match [1, 2])) {
      AVStenosis_1 <- tolower(AVStenosis_1_match [1, 2])
      if (AVStenosis_1 == "no" | AVStenosis_1 == "trivial"|AVStenosis_1 == "trace") {
        output_AVStenosis <- AVStenosis_1
        cat(sprintf("AV Stenosis: %s\n", AVStenosis_1))
      } else {
        if (!is.na(AVStenosissentence_matches_2 [1, 2])) {
          
          AVGradient_pattern <- "CONCLUSIONS.*?(?:M[a-z][a-z]n|m[a-z][a-z]n)(?:\\sAV)?(?:\\sPG|\\spressure\\sg\\w+t|\\sg\\w+t)(?:\\s[A-Za-z]+)?(?:\\s[A-Za-z]+)?(?:\\s[A-Za-z]+)?\\s?(\\d+(?:\\.\\d+)?)(?:\\s?m?m?\\s?Hg?)"
          AVGradient_match <- str_match(document_text, AVGradient_pattern)
          AVGradient_pattern_2 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?(?:M[a-z][a-z]n|m[a-z][a-z]n)(?:\\sAV)?(?:\\sPG|\\spressure\\sg\\w+t|\\sg\\w+t)(?:\\s[A-Za-z]+)?(?:\\s[A-Za-z]+)?(?:\\s[A-Za-z]+)?\\s?(\\d+(?:\\.\\d+)?)(?:\\s?m?m?\\s?Hg?)"
          AVGradient_match_2 <- str_match(document_text, AVGradient_pattern_2)
          AVPeakGradient_pattern <- "CONCLUSIONS.*?(?:P[a-z][a-z]k|p[a-z][a-z]k)(?:\\sAV)?(?:\\sPG|\\spressure\\sgradient|\\sgradient|\\sv\\w+ty)(?:\\s[A-Za-z]+)?\\s(\\d+(?:\\.\\d+)?)(?:\\s?m\\s?m\\s?[A-Za-z]{2}?)"
          AVPeakGradient_match <- str_match(document_text, AVPeakGradient_pattern)
          AVPeakGradient_pattern_2 <-"TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?(?:P[a-z][a-z]k|p[a-z][a-z]k)(?:\\sAV)?(?:\\sPG|\\spressure\\sgradient|\\sgradient|\\sv\\w+ty)(?:\\s[A-Za-z]+)?\\s(\\d+(?:\\.\\d+)?)(?:\\s?m\\s?m\\s?[A-Za-z]{2}?)"
          AVPeakGradient_match_2 <- str_match(document_text, AVPeakGradient_pattern_2) 
          AVArea_pattern <- "CONCLUSIONS.*?(?:Aortic\\s?(?:st\\w+)?|aortic\\s?(?:st\\w+)?|A).*?(?:Valve\\s?(?:a\\w+)?|valve\\s?(?:a\\w+)?|AVA)(?:\\s[A-Za-z]+){1,5}\\s?(?:\\sLVOT\\sd\\w+r\\sof\\s\\d+(?:\\.\\d+)?\\s?cm?\\s?is?\\s?.?\\s?\\s?)?(?:\\s[A-Za-z]+){1,5}\\s?(\\d+(?:\\.\\d+)?)"
          AVArea_match <- str_match(document_text, AVArea_pattern)
          AVArea_pattern_2 <- "CONCLUSIONS.*?AVA\\s+(\\d+(?:\\.\\d+)?)"
          AVArea_match_2 <- str_match(document_text, AVArea_pattern_2)
          AVArea_pattern_3 <- "CONCLUSIONS.*?AVA\\D+(?:\\d+(?:\\.\\d+)?)(?:\\s)?(?:cm)?\\s\\w+\\s(\\d+(?:\\.\\d+)?)"
          AVArea_match_3 <- str_match(document_text, AVArea_pattern_3)
          AVArea_pattern_4 <- "CONCLUSIONS.*?(?:Aortic|aortic)(?:\\svalve\\sarea)(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?\\s(\\d+(?:.)?\\d+)"
          AVArea_match_4 <- str_match(document_text, AVArea_pattern_4)
          
          LVOTDiameter_pattern <- "CONCLUSIONS.*?(?:AVA\\s)?\\s?(?:LVOT)(?:\\sd[A-Za-z]+r\\s?of?)?\\s(\\d+(?:\\.\\d+)?)(?:\\s?cm)?"
          LVOTDiameter_match <- str_match(document_text, LVOTDiameter_pattern)
          LVOTDiameter_pattern_2 <- "CONCLUSIONS.*?LVOT(?:\\sdiameter)?(?:\\sof)?\\s(\\d+(?:\\.\\d+)?)"
          LVOTDiameter_match_2 <- str_match(document_text, LVOTDiameter_pattern_2)
          AVPeakVelocity_pattern <- "CONCLUSIONS.*?(?:Peak|peak)(?:\\sAV)? (?:velocity|velocities)(?:\\s\\w+)?(?:\\s\\w+)?\\s?(\\d+(?:\\.\\d+)?\\s?(?:m\\/.?.?.?)?)"
          AVPeakVelocity_match <- str_match(document_text, AVPeakVelocity_pattern)
          AVPeakVelocity_pattern_2 <- "CONCLUSIONS.*?(?:Vmax|VMAX|VMax|vmax)(?:\\sAV)?\\s?(\\d+(?:\\.\\d+)?)\\s?(?:m\\/.?.?.?)?"
          AVPeakVelocity_match_2 <- str_match(document_text, AVPeakVelocity_pattern_2)
          AVDimensionlessIndex_pattern <- "CONCLUSIONS.*?(?i)(?:DI|D[A-Z][a-z]+s\\s?I[A-Z][a-z]+x)\\s?(?:using [Vv]\\w+|by [Vv]\\w+|via [Vv]\\w+)?(?:\\sof|\\sis)?\\s?(\\d+(?:\\.\\d+)?)"
          AVDimensionlessIndex_match <- str_match(document_text, AVDimensionlessIndex_pattern)
          AViSV_pattern <- "CONCLUSIONS.*?(?i)(?:iSV|SVi|i[a-z]+x\\s?s[a-z]+e\\s?v[a-z]+e|s[a-z]+e\\s?v[a-z]+e\\s?i[a-z]+x)\\s?(?:of|is)?\\s?(\\d+(?:\\.\\d+)?)"
          AViSV_match <- str_match(document_text, AViSV_pattern)
          
          if (!is.na(AVGradient_match [1, 2])) {
            output_AVGradient <- AVGradient_match [1, 2]
            cat(sprintf("AV Gradient: %s\n", AVGradient_match [1, 2]))
          } else if (!is.na(AVGradient_match_2 [1, 2])) {
            output_AVGradient <- AVGradient_match_2 [1, 2]
            cat(sprintf("AV Gradient: %s\n", AVGradient_match_2 [1, 2]))
          } else {
            output_AVGradient <- ""
            cat("AV Gradient: No match found\n")
          }
          if (!is.na(AVPeakGradient_match [1, 2])) {
            output_AVPeakGradient <- AVPeakGradient_match [1, 2]
            cat(sprintf("AV Peak Gradient: %s\n", AVPeakGradient_match [1, 2]))
          } else if (!is.na(AVPeakGradient_match_2 [1, 2])) {
            output_AVPeakGradient <- AVPeakGradient_match_2 [1, 2]
            cat(sprintf("AV Peak Gradient: %s\n", AVPeakGradient_match_2 [1, 2]))
          } else {
            output_AVPeakGradient <- ""
            cat("AV Peak Gradient: No match found\n")
          }
          if (!is.na(AVArea_match [1, 2])) {
            output_AVArea <- AVArea_match [1, 2]
            cat(sprintf("AV Area: %s\n", AVArea_match [1, 2]))
          } else if (!is.na(AVArea_match_2 [1, 2])) {
            output_AVArea <- AVArea_match_2 [1, 2]
            cat(sprintf("AV Area: %s\n", AVArea_match_2 [1, 2]))
          } else if (!is.na(AVArea_match_3 [1, 2])) {
            output_AVArea <- AVArea_match_3 [1, 2]
            cat(sprintf("AV Area: %s\n", AVArea_match_3 [1, 2]))
          } else if (!is.na(AVArea_match_4 [1, 2])) {
              output_AVArea <- AVArea_match_4 [1, 2]
              cat(sprintf("AV Area: %s\n", AVArea_match_4 [1, 2]))
          } else {
            output_AVArea <- ""
            cat("AV Area: No match found\n")
          }
          if (!is.na(LVOTDiameter_match [1, 2])) {
            output_LVOTDiameter <- LVOTDiameter_match [1, 2]
            cat(sprintf("LVOT Diameter: %s\n", LVOTDiameter_match [1, 2]))
          } else if (!is.na(LVOTDiameter_match_2 [1, 2])) {
            output_LVOTDiameter <- LVOTDiameter_match_2 [1, 2]
            cat(sprintf("LVOT Diameter: %s\n", LVOTDiameter_match_2 [1, 2]))
          } else {
            output_LVOTDiameter <- ""
            cat("LVOT Diameter: No match found\n")
          }
          if (!is.na(AVPeakVelocity_match [1, 2])) {
            output_AVPeakVelocity <- AVPeakVelocity_match [1, 2]
            cat(sprintf("AV Peak Velocity: %s\n", AVPeakVelocity_match [1, 2]))
          } else if (!is.na(AVPeakVelocity_match_2 [1, 2])) {
            output_AVPeakVelocity <- AVPeakVelocity_match_2 [1, 2]
            cat(sprintf("AV Peak Velocity: %s\n", AVPeakVelocity_match_2 [1, 2]))
          } else {
            output_AVPeakVelocity <- ""
            cat("AV Peak Velocity: No match found\n")
          }
          if (!is.na(AVDimensionlessIndex_match [1, 2])) {
            output_AVDimensionlessIndex <- AVDimensionlessIndex_match [1, 2]
            cat(sprintf("AV Dimensionless Index: %s\n", AVDimensionlessIndex_match [1, 2]))
          } else {
            output_AVDimensionlessIndex <- ""
            cat("AV Dimensionless Index: No match found\n")
          }
          if (!is.na(AViSV_match [1, 2])) {
            output_AViSV <- AViSV_match [1, 2]
            cat(sprintf("AV iSV: %s\n", AViSV_match [1, 2]))
          } else {
            output_AViSV <- ""
            cat("AV iSV: No match found\n")
          }
          
          AVStenosissentence_2 <- AVStenosissentence_matches_2 [1, 2]
          AVStenosis_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild\\b|Mild\\b|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate\\b|Moderate\\b|severe\\b|Severe\\b|\\bcritical\\b|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
          AVStenosis_2_match <- str_match(AVStenosissentence_2, AVStenosis_2_pattern)
          if (!is.na(AVStenosis_2_match [1, 2])) {
            AVStenosis_2 <- tolower(AVStenosis_2_match [1, 2])
            if (AVStenosis_1 == AVStenosis_2) {
              cat(sprintf("AV Stenosis: %s\n", AVStenosis_1))
              output_AVStenosis <- AVStenosis_1
            } else {
              cat("AV Stenosis: Error, non-matching findings\n")
              output_AVStenosis <- AVStenosis_2 
              output_AVStenosisError <- paste("AVStenosis: Error, non-matching findings:", AVStenosis_1, AVStenosis_2)
            }
          } else {
            cat("AVStenosis: Error, no AV Stenosis categorization found in conclusions AV Stenosis sentence\n")
            output_AVStenosis <- AVStenosis_1 
            output_AVStenosisError <- "AV Stenosis: Error, no AV Stenosis categorization found in conclusions AV Stenosis sentence"
          }
          
        } else {
          cat("AV Stenosis: Error, no AV Stenosis conclusions sentence found\n")
          output_AVStenosis <- AVStenosis_1 
          output_AVStenosisError <- "AV Stenosis: Error, no AV Stenosis conclusions sentence found"
        }
      }
    } else {
      cat("AV Stenosis: Error, no AV Stenosis categorization found in doppler sentence\n")
      output_AVStenosis <- ""
      output_AVStenosisError <- "AV Stenosis: Error, no AV Stenosis categorization found in doppler sentence"
    }
    
  } else {
    AVStenosissentence_pattern_3 <- "Aortic Valve:.*?([Dd]oppler did not suggest stenosis)"
    AVStenosissentence_matches_3 <- str_match(document_text, AVStenosissentence_pattern_3)
    if (!is.na(AVStenosissentence_matches_3 [1, 2])) {
      output_AVStenosis <- "no"
    } else {
        cat("AV Stenosis: Error, no AV Stenosis doppler sentence found\n")
        output_AVStenosisError <- "AVStenosis: Error, no AVStenosis doppler sentence found"
        if (!is.na(AVStenosissentence_matches_2 [1, 2])) {
          AVStenosissentence_3 <- AVStenosissentence_matches_2 [1, 2]
          AVStenosis_3_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild\\b|Mild\\b|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate\\b|Moderate\\b|severe\\b|Severe\\b|\\bcritical\\b|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
          AVStenosis_3_match <- str_match(AVStenosissentence_3, AVStenosis_3_pattern)
          if (!is.na(AVStenosis_3_match [1, 2])) {
            output_AVStenosis <- tolower(AVStenosis_3_match [1, 2])
          }else {
            output_AVStenosis <- ""
            output_AVStenosisError <- "AVStenosis: Error, no doppler sentence. Conclusions sentence found but no categorization"
          }
        }else {
          output_AVStenosis <- ""
          output_AVStenosisError <- "AV Stenosis: No doppler or conclusions sentence found"
        }
      }
  }
  
  #Tricuspid Regurgitation
  
  TRsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Tricuspid valve regurgitation|tricuspid valve regurgitation|Tricuspid regurgitation|tricuspid regurgitation)[^.]*).*CONCLUSIONS"
  TRsentence_matches_1 <- str_match(document_text, TRsentence_pattern_1)
  TRsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Tricuspid valve regurgitation|tricuspid valve regurgitation|Tricuspid regurgitation|tricuspid regurgitation)[^.]*)"
  TRsentence_matches_2 <- str_match(document_text, TRsentence_pattern_2)
  
  output_TR <- ""
  output_TRError <- ""
  
  if (!is.na(TRsentence_matches_1 [1, 2])) {
    TRsentence_1 <- TRsentence_matches_1 [1, 2]
    cat(sprintf("TR Sentence 1: %s\n", TRsentence_1))
    TR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    TR_1_match <- str_match(TRsentence_1, TR_1_pattern)
    
    if (!is.na(TR_1_match [1, 2])) {
      TR_1 <- tolower(TR_1_match [1, 2])
      if (TR_1 == "no" | TR_1 == "trivial" | TR_1 == "mild" | TR_1 == "mild-moderate" | TR_1 == "mild - moderate" | TR_1 == "mild to moderate" | TR_1 == "not assessed" | TR_1 == "shadowing from the prosthesis") {
        output_TR <- TR_1
        cat(sprintf("TR: %s\n", TR_1))
      } else {
        if (!is.na(TRsentence_matches_2 [1, 2])) {
          TRsentence_2 <- TRsentence_matches_2 [1, 2]
          TR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          TR_2_match <- str_match(TRsentence_2, TR_2_pattern)
          if (!is.na(TR_2_match [1, 2])) {
            TR_2 <- tolower(TR_2_match [1, 2])
            if (TR_1 == TR_2) {
              cat(sprintf("TR: %s\n", TR_1))
              output_TR <- TR_1
            } else {
              cat("TR: Error, non-matching findings")
              output_TR <- TR_1 
              output_TRError <- "TR: Error, non-matching findings"
            }
          } else {
            cat("TR: Error, no TR categorization found in conclusions TR sentence\n")
            output_TR <- TR_1 
            output_TRError <- "TR: Error, no TR categorization found in conclusions TR sentence"
          }
          
        } else {
          cat("TR: Error, no TR conclusions sentence found\n")
          output_TR <- TR_1 
          output_TRError <- "TR: Error, no TR conclusions sentence found"
        }
      }
    } else {
      cat("TR: Error, no TR categorization found in doppler sentence\n")
      output_TR <- ""
      output_TRError <- "TR: Error, no TR categorization found in doppler sentence"
    }
    
    
  } else {
    cat("TR: Error, no TR doppler sentence found\n")
    output_TR <- ""
    output_TRError <- "TR: Error, no TR doppler sentence found"
  }
  
  # Tricuspid Valve Structure
  
  TVStructurePatterns <- list(
    "Tricuspid Valve:.*?([^.]*(?:Tricuspid valve|tricuspid valve)(?:\\sis|\\sappears|\\sValve|\\sgrossly|\\snot well seen|\\shas a|\\sabnormal|\\sthickened|\\sthickening)[^.]*).*?(?:Pulmonic Valve:)",
    "Tricuspid Valve:.*?([^.]*(?:tricuspid valve leaflets)[^.]*).*?(?:Pulmonic Valve:)"
  )
  
  output_TVStructure <- ""
  output_TVStructureError <- ""
  
  for (pattern in TVStructurePatterns) {
    TVStructureMatches <- str_match(document_text, pattern)
    if (!is.na(TVStructureMatches[1, 2])) {
      TVStructuresentence <- TVStructureMatches[1, 2]
      cat(sprintf("TV Structure Sentence: %s\n", TVStructuresentence))
      
      # Pattern 1: Check grossly normal and similar phrases
      TVStructure_1_pattern <- "(grossly normal|Grossly normal|normal|Normal|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|rheumatic)(?:\\sthickened|\\sthickening)?"
      TVStructure_1_match <- str_match(TVStructuresentence, TVStructure_1_pattern)
      
      if (!is.na(TVStructure_1_match[1, 2])) {
        output_TVStructure <- tolower(TVStructure_1_match[1, 2])
        cat(sprintf("TV Structure: %s\n", output_TVStructure))
      } else {
        # Pattern 3: Check "thickened" or "thickening"
        TVStructure_3_pattern <- "(thickened|thickening)"
        TVStructure_3_match <- str_match(TVStructuresentence, TVStructure_3_pattern)
        
        if (!is.na(TVStructure_3_match[1, 2])) {
          # Pattern 2: Check severity levels
          TVStructure_2_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
          TVStructure_2_match <- str_match(TVStructuresentence, TVStructure_2_pattern)
          
          if (!is.na(TVStructure_2_match[1, 2])) {
            output_TVStructure <- paste(TVStructure_2_match[1, 2], TVStructure_3_match[1, 2], sep = " ")
          } else {
            output_TVStructure <- TVStructure_3_match[1, 2]
          }
          cat(sprintf("TV Structure: %s\n", output_TVStructure))
        } else {
          cat("Error: No valid descriptors found in tricuspid valve sentence\n")
          output_TVStructureError <- "Error: No valid descriptors found in tricuspid valve sentence"
        }
      }
      
      break  # Stop processing further patterns once a match is found
    }
  }
  
  if (output_TVStructure == "" && output_TVStructureError == "") {
    cat("Error: No valid descriptors found in tricuspid valve sentence\n")
    output_TVStructureError <- "Error: No valid descriptors found in tricuspid valve sentence"
  }
  
  # TV Implant
  TVimplant_pattern <- "Tricuspid Valve:.*?(Bioprosthetic|bioprosthetic|mechanical|Mechanical|Prosthesis|prosthesis|Prosthetic|prosthetic).*?(?:Pulmonic valve|pulmonic valve)"
  TVimplant_matches <- str_match(document_text, TVimplant_pattern)
  
  output_TVimplant <- ""
  
  if (!is.na(TVimplant_matches[1, 2])) {
    TVimplant <- TVimplant_matches[1, 2]
    output_TVimplant <- TVimplant
  } else {
    output_TVimplant <- ""
  }
  cat("TV Implant:", output_TVimplant, "\n")
  
  # TV Leaflet Number
  
  TVLeafletNumber_pattern <- "Tricuspid Valve:.*?(Trileaflet|trileaflet|Tricuspid|tricuspid|Bicuspid|bicuspid|Bileaflet|bileaflet).*?(?:Pulmonic Valve:)"
  TVLeafletNumber_matches <- str_match(document_text, TVLeafletNumber_pattern)
  
  output_TVLeafletNumber <- ""
  
  if (!is.na(TVLeafletNumber_matches[1, 2])) {
    TVLeafletNumber <- TVLeafletNumber_matches[1, 2]
    output_TVLeafletNumber <- TVLeafletNumber
  } else {
    output_TVLeafletNumber <- ""
  }
  
  cat("TV Leaflet Number:", output_TVLeafletNumber, "\n")
  
  # TV Sclerosis
  
  TVSclerosis_pattern <- "Tricuspid Valve:.*?(mild(?:ly)?-moderate(?:ly)?|Mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|Mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|Mild(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|moderate(?:ly)?-severe(?:ly)?|Moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|Moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|severe(?:ly)?|Severe(?:ly)?|no\\b|No\\b|not)\\s(?:sclerotic|Sclerotic|sclerosis|Sclerosis).*?(?:Pulmonic Valve:)"
  TVSclerosis_match <- str_match(document_text, TVSclerosis_pattern)
  
  output_TVSclerosis <- ""
  
  if (!is.na(TVSclerosis_match[1, 2])) {
    output_TVSclerosis <- TVSclerosis_match[1, 2]
  } else {
    output_TVSclerosis <- ""
  }
  cat("TV Sclerosis:", output_TVSclerosis, "\n")
  
  # TV Calcification
  
  # Define the pattern to extract all text between "Tricuspid Valve:" and "Pulmonic Valve:"
  TVCalcificationsentence_pattern <- "Tricuspid Valve:(.*?)Pulmonic Valve:"
  TVCalcification_section <- str_match(document_text, TVCalcificationsentence_pattern)
  
  # Initialize output variables
  output_TVCalcification <- ""
  output_TVCalcificationError <- ""
  
  if (!is.na(TVCalcification_section[1, 2])) {
    # Extract sentences containing "calcification" or "calcified"
    TVCalcification_sentences <- unlist(str_extract_all(TVCalcification_section[1, 2], "[^.!?]*\\b(?:calcification|calcified|Calcification|Calcified)\\b[^.!?]*[.!?]"))
    
    # Patterns for leaflet involvement
    TVCalcification_leaflet_pattern_remove <- "(?:^|\\s)(?i)(leaflet\\b)(?:\\s|$)"  # Remove these
    TVCalcification_leaflet_pattern_keep <- "(?:^|\\s)(?i)(tricuspid valve leaflets|tricuspid valve|leaflets of the tricuspid valve)(?:\\s|$)"  # Keep these
    
    # Remove sentences that mention only specified terms
    TVCalcification_filtered_sentences <- TVCalcification_sentences[!grepl(TVCalcification_leaflet_pattern_remove, TVCalcification_sentences, ignore.case = TRUE) | 
                                                                      grepl(TVCalcification_leaflet_pattern_keep, TVCalcification_sentences, ignore.case = TRUE)]
    
    if (length(TVCalcification_filtered_sentences) > 1) {
      # More than one valid sentence remains
      output_TVCalcificationError <- "More than one sentence found containing calcification."
    } else if (length(TVCalcification_filtered_sentences) == 1) {
      # Only one sentence remains, analyze severity
      TVCalcificationpattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
      TVCalcification_match <- str_match(TVCalcification_filtered_sentences, TVCalcificationpattern)
      
      if (!is.na(TVCalcification_match[1, 2])) {
        output_TVCalcification <- TVCalcification_match[1, 2]  # Store severity
      } else {
        output_TVCalcificationError <- "No categorization found in the remaining sentence."
      }
    } else {
      # No relevant sentences found
      output_TVCalcificationError <- "No valid calcification sentences found."
    }
  }
  
  cat("TV Calcification:", output_TVCalcification, "\n")
  cat("TV Calcification Error:", output_TVCalcificationError, "\n")
  
  #Tricuspid Valve Stenosis
  
  TVStenosissentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Tricuspid valve stenosis|tricuspid valve stenosis|Tricuspid stenosis|tricuspid stenosis)[^.]*).*CONCLUSIONS"
  TVStenosissentence_matches_1 <- str_match(document_text, TVStenosissentence_pattern_1)
  TVStenosissentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Tricuspid valve stenosis|tricuspid valve stenosis|Tricuspid stenosis|tricuspid stenosis)[^.]*)"
  TVStenosissentence_matches_2 <- str_match(document_text, TVStenosissentence_pattern_2)
  
  output_TVStenosis <- ""
  output_TVStenosisError <- ""
  
  if (!is.na(TVStenosissentence_matches_1 [1, 2])) {
    TVStenosissentence_1 <- TVStenosissentence_matches_1 [1, 2]
    cat(sprintf("TV Stenosis Sentence 1: %s\n", TVStenosissentence_1))
    TVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    TVStenosis_1_match <- str_match(TVStenosissentence_1, TVStenosis_1_pattern)
    
    if (!is.na(TVStenosis_1_match [1, 2])) {
      TVStenosis_1 <- tolower(TVStenosis_1_match [1, 2])
      if (TVStenosis_1 == "no" | TVStenosis_1 == "trivial"|TVStenosis_1 == "trace") {
        output_TVStenosis <- TVStenosis_1
        cat(sprintf("TV Stenosis: %s\n", TVStenosis_1))
      } else {
        if (!is.na(TVStenosissentence_matches_2 [1, 2])) {
          TVStenosissentence_2 <- TVStenosissentence_matches_2 [1, 2]
          TVStenosis_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          TVStenosis_2_match <- str_match(TVStenosissentence_2, TVStenosis_2_pattern)
          if (!is.na(TVStenosis_2_match [1, 2])) {
            TVStenosis_2 <- tolower(TVStenosis_2_match [1, 2])
            if (TVStenosis_1 == TVStenosis_2) {
              cat(sprintf("TV Stenosis: %s\n", TVStenosis_1))
              output_TVStenosis <- TVStenosis_1
            } else {
              cat("TV Stenosis: Error, non-matching findings\n")
              output_TVStenosis <- TVStenosis_1 
              output_TVStenosisError <- "TVStenosis: Error, non-matching findings"
            }
          } else {
            cat("TVStenosis: Error, no TV Stenosis categorization found in conclusions TV Stenosis sentence\n")
            output_TVStenosis <- TVStenosis_1 
            output_TVStenosisError <- "TV Stenosis: Error, no TV Stenosis categorization found in conclusions TV Stenosis sentence"
          }
          
        } else {
          cat("TV Stenosis: Error, no TV Stenosis conclusions sentence found\n")
          output_TVStenosis <- TVStenosis_1 
          output_TVStenosisError <- "TV Stenosis: Error, no TV Stenosis conclusions sentence found"
        }
      }
    } else {
      cat("TV Stenosis: Error, no TV Stenosis categorization found in doppler sentence\n")
      output_TVStenosis <- ""
      output_TVStenosisError <- "TV Stenosis: Error, no TV Stenosis categorization found in doppler sentence"
    }
    
    
  } else {
    cat("TV Stenosis: Error, no TV Stenosis doppler sentence found\n")
    output_TVStenosis <- ""
    output_TVStenosisError <- "TV Stenosis: Error, no TV Stenosis doppler sentence found"
  }
  
  #Pulmonic Regurgitation
  
  PRsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Pulmonic valve regurgitation|pulmonic valve regurgitation|Pulmonic regurgitation|pulmonic regurgitation|[Pp]ulmonic insufficiency)[^.]*).*CONCLUSIONS"
  PRsentence_matches_1 <- str_match(document_text, PRsentence_pattern_1)
  PRsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Pulmonic valve regurgitation|pulmonic valve regurgitation|Pulmonic regurgitation|pulmonic regurgitation)[^.]*)"
  PRsentence_matches_2 <- str_match(document_text, PRsentence_pattern_2)
  
  output_PR <- ""
  output_PRError <- ""
  
  if (!is.na(PRsentence_matches_1 [1, 2])) {
    PRsentence_1 <- PRsentence_matches_1 [1, 2]
    cat(sprintf("PR Sentence 1: %s\n", PRsentence_1))
    PR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis|could not be assessed)"
    PR_1_match <- str_match(PRsentence_1, PR_1_pattern)
    
    if (!is.na(PR_1_match [1, 2])) {
      PR_1 <- tolower(PR_1_match [1, 2])
      if (PR_1 == "no" | PR_1 == "trivial" | PR_1 == "trace" | PR_1 == "mild" | PR_1 == "mild-moderate" | PR_1 == "mild - moderate" | PR_1 == "mild to moderate" | PR_1 == "not assessed" | PR_1 == "shadowing from the prosthesis") {
        output_PR <- PR_1
        cat(sprintf("PR: %s\n", PR_1))
      } else {
        if (!is.na(PRsentence_matches_2 [1, 2])) {
          PRsentence_2 <- PRsentence_matches_2 [1, 2]
          PR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          PR_2_match <- str_match(PRsentence_2, PR_2_pattern)
          if (!is.na(PR_2_match [1, 2])) {
            PR_2 <- tolower(PR_2_match [1, 2])
            if (PR_1 == PR_2) {
              cat(sprintf("PR: %s\n", PR_1))
              output_PR <- PR_1
            } else {
              cat("PR: Error, non-matching findings\n")
              output_PR <- PR_1 
              output_PRError <- "PR: Error, non-matching findings"
            }
          } else {
            cat("PR: Error, no PR categorization found in conclusions PR sentence\n")
            output_PR <- PR_1 
            output_PRError <- "PR: Error, no PR categorization found in conclusions PR sentence"
          }
          
        } else {
          cat("PR: Error, no PR conclusions sentence found\n")
          output_PR <- PR_1 
          output_PRError <- "PR: Error, no PR conclusions sentence found"
        }
      }
    } else {
      cat("PR: Error, no PR categorization found in doppler sentence\n")
      output_PR <- ""
      output_PRError <- "PR: Error, no PR categorization found in doppler sentence"
    }
    
    
  } else {
    cat("PR: Error, no PR doppler sentence found\n")
    output_PR <- ""
    output_PRError <- "PR: Error, no PR doppler sentence found"
  }
  
  # Pulmonic Valve Structure
  
  PVStructurePatterns <- list(
    "Pulmonic Valve:.*?([^.]*(?:Pulmonic valve|pulmonic valve)(?:\\sis|\\sappears|\\sValve|\\sgrossly|\\snot well seen|\\shas a|\\sabnormal|\\sthickened|\\sthickening)[^.]*).*?(?:CONCLUSIONS:)",
    "Pulmonic Valve:.*?([^.]*(?:pulmonic valve leaflets)[^.]*).*?(?:CONCLUSIONS:)"
  )
  
  output_PVStructure <- ""
  output_PVStructureError <- ""
  
  for (pattern in PVStructurePatterns) {
    PVStructureMatches <- str_match(document_text, pattern)
    if (!is.na(PVStructureMatches[1, 2])) {
      PVStructuresentence <- PVStructureMatches[1, 2]
      cat(sprintf("PV Structure Sentence: %s\n", PVStructuresentence))
      
      # Pattern 1: Check grossly normal and similar phrases
      PVStructure_1_pattern <- "(grossly normal|Grossly normal|normal|Normal|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|rheumatic)(?:\\sthickened|\\sthickening)?"
      PVStructure_1_match <- str_match(PVStructuresentence, PVStructure_1_pattern)
      
      if (!is.na(PVStructure_1_match[1, 2])) {
        output_PVStructure <- tolower(PVStructure_1_match[1, 2])
        cat(sprintf("PV Structure: %s\n", output_PVStructure))
      } else {
        # Pattern 3: Check "thickened" or "thickening"
        PVStructure_3_pattern <- "(thickened|thickening)"
        PVStructure_3_match <- str_match(PVStructuresentence, PVStructure_3_pattern)
        
        if (!is.na(PVStructure_3_match[1, 2])) {
          # Pattern 2: Check severity levels
          PVStructure_2_pattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
          PVStructure_2_match <- str_match(PVStructuresentence, PVStructure_2_pattern)
          
          if (!is.na(PVStructure_2_match[1, 2])) {
            output_PVStructure <- paste(PVStructure_2_match[1, 2], PVStructure_3_match[1, 2], sep = " ")
          } else {
            output_PVStructure <- PVStructure_3_match[1, 2]
          }
          cat(sprintf("PV Structure: %s\n", output_PVStructure))
        } else {
          cat("Error: No valid descriptors found in pulmonic valve sentence\n")
          output_PVStructureError <- "Error: No valid descriptors found in pulmonic valve sentence"
        }
      }
      
      break  # Stop processing further patterns once a match is found
    }
  }
  
  if (output_PVStructure == "" && output_PVStructureError == "") {
    cat("Error: No valid descriptors found in pulmonic valve sentence\n")
    output_PVStructureError <- "Error: No valid descriptors found in pulmonic valve sentence"
  }
  
  # PV Implant
  PVimplant_pattern <- "Pulmonic Valve:.*?(Bioprosthetic|bioprosthetic|mechanical|Mechanical|Prosthesis|prosthesis|Prosthetic|prosthetic).*?(?:CONCLUSIONS:)"
  PVimplant_matches <- str_match(document_text, PVimplant_pattern)
  
  output_PVimplant <- ""
  
  if (!is.na(PVimplant_matches[1, 2])) {
    PVimplant <- PVimplant_matches[1, 2]
    output_PVimplant <- PVimplant
  } else {
    output_PVimplant <- ""
  }
  cat("PV Implant:", output_PVimplant, "\n")
  
  # PV Leaflet Number
  
  PVLeafletNumber_pattern <- "Pulmonic Valve:.*?(Trileaflet|trileaflet|Pulmonic|pulmonic|Bicuspid|bicuspid|Bileaflet|bileaflet).*?(?:CONCLUSIONS:)"
  PVLeafletNumber_matches <- str_match(document_text, PVLeafletNumber_pattern)
  
  output_PVLeafletNumber <- ""
  
  if (!is.na(PVLeafletNumber_matches[1, 2])) {
    PVLeafletNumber <- PVLeafletNumber_matches[1, 2]
    output_PVLeafletNumber <- PVLeafletNumber
  } else {
    output_PVLeafletNumber <- ""
  }
  
  cat("PV Leaflet Number:", output_PVLeafletNumber, "\n")
  
  # PV Sclerosis
  
  PVSclerosis_pattern <- "Pulmonic Valve:.*?(mild(?:ly)?-moderate(?:ly)?|Mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|Mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|Mild(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|moderate(?:ly)?-severe(?:ly)?|Moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|Moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|Moderate(?:ly)?|severe(?:ly)?|Severe(?:ly)?|no\\b|No\\b|not)\\s(?:sclerotic|Sclerotic|sclerosis|Sclerosis).*?(?:CONCLUSIONS:)"
  PVSclerosis_match <- str_match(document_text, PVSclerosis_pattern)
  
  output_PVSclerosis <- ""
  
  if (!is.na(PVSclerosis_match[1, 2])) {
    output_PVSclerosis <- PVSclerosis_match[1, 2]
  } else {
    output_PVSclerosis <- ""
  }
  cat("PV Sclerosis:", output_PVSclerosis, "\n")
  
  # PV Calcification
  
  # Define the pattern to extract all text between "Pulmonic Valve:" and "CONCLUSIONS:"
  PVCalcificationsentence_pattern <- "Pulmonic Valve:(.*?)CONCLUSIONS:"
  PVCalcification_section <- str_match(document_text, PVCalcificationsentence_pattern)
  
  # Initialize output variables
  output_PVCalcification <- ""
  output_PVCalcificationError <- ""
  
  if (!is.na(PVCalcification_section[1, 2])) {
    # Extract sentences containing "calcification" or "calcified"
    PVCalcification_sentences <- unlist(str_extract_all(PVCalcification_section[1, 2], "[^.!?]*\\b(?:calcification|calcified|Calcification|Calcified)\\b[^.!?]*[.!?]"))
    
    # Patterns for leaflet involvement
    PVCalcification_leaflet_pattern_remove <- "(?:^|\\s)(?i)(leaflet\\b)(?:\\s|$)"  # Remove these
    PVCalcification_leaflet_pattern_keep <- "(?:^|\\s)(?i)(pulmonic valve leaflets|pulmonic valve|leaflets of the pulmonic valve)(?:\\s|$)"  # Keep these
    
    # Remove sentences that mention only specified terms
    PVCalcification_filtered_sentences <- PVCalcification_sentences[!grepl(PVCalcification_leaflet_pattern_remove, PVCalcification_sentences, ignore.case = TRUE) | 
                                                                      grepl(PVCalcification_leaflet_pattern_keep, PVCalcification_sentences, ignore.case = TRUE)]
    
    if (length(PVCalcification_filtered_sentences) > 1) {
      # More than one valid sentence remains
      output_PVCalcificationError <- "More than one sentence found containing calcification."
    } else if (length(PVCalcification_filtered_sentences) == 1) {
      # Only one sentence remains, analyze severity
      PVCalcificationpattern <- "(?i)(mild(?:ly)?-moderate(?:ly)?|mild(?:ly)? - moderate(?:ly)?|mild(?:ly)? to moderate(?:ly)?|mild(?:ly)?|moderate(?:ly)?-severe(?:ly)?|moderate(?:ly)? - severe(?:ly)?|moderate(?:ly)? to severe(?:ly)?|moderate(?:ly)?|severe(?:ly)?|no\\b|not\\b)"
      PVCalcification_match <- str_match(PVCalcification_filtered_sentences, PVCalcificationpattern)
      
      if (!is.na(PVCalcification_match[1, 2])) {
        output_PVCalcification <- PVCalcification_match[1, 2]  # Store severity
      } else {
        output_PVCalcificationError <- "No categorization found in the remaining sentence."
      }
    } else {
      # No relevant sentences found
      output_PVCalcificationError <- "No valid calcification sentences found."
    }
  }
  
  cat("PV Calcification:", output_PVCalcification, "\n")
  cat("PV Calcification Error:", output_PVCalcificationError, "\n")
  
  #Pulmonic Valve Stenosis
  
  PVStenosissentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Pulmonic valve stenosis|pulmonic valve stenosis|Pulmonic stenosis|pulmonic stenosis)[^.]*).*CONCLUSIONS"
  PVStenosissentence_matches_1 <- str_match(document_text, PVStenosissentence_pattern_1)
  PVStenosissentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Pulmonic valve stenosis|pulmonic valve stenosis|Pulmonic stenosis|pulmonic stenosis)[^.]*)"
  PVStenosissentence_matches_2 <- str_match(document_text, PVStenosissentence_pattern_2)
  
  output_PVStenosis <- ""
  output_PVStenosisError <- ""
  
  if (!is.na(PVStenosissentence_matches_1 [1, 2])) {
    PVStenosissentence_1 <- PVStenosissentence_matches_1 [1, 2]
    cat(sprintf("PV Stenosis Sentence 1: %s\n", PVStenosissentence_1))
    PVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    PVStenosis_1_match <- str_match(PVStenosissentence_1, PVStenosis_1_pattern)
    
    if (!is.na(PVStenosis_1_match [1, 2])) {
      PVStenosis_1 <- tolower(PVStenosis_1_match [1, 2])
      if (PVStenosis_1 == "no" | PVStenosis_1 == "trivial"|PVStenosis_1 == "trace") {
        output_PVStenosis <- PVStenosis_1
        cat(sprintf("PV Stenosis: %s\n", PVStenosis_1))
      } else {
        if (!is.na(PVStenosissentence_matches_2 [1, 2])) {
          PVStenosissentence_2 <- PVStenosissentence_matches_2 [1, 2]
          PVStenosis_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          PVStenosis_2_match <- str_match(PVStenosissentence_2, PVStenosis_2_pattern)
          if (!is.na(PVStenosis_2_match [1, 2])) {
            PVStenosis_2 <- tolower(PVStenosis_2_match [1, 2])
            if (PVStenosis_1 == PVStenosis_2) {
              cat(sprintf("PV Stenosis: %s\n", PVStenosis_1))
              output_PVStenosis <- PVStenosis_1
            } else {
              cat("PV Stenosis: Error, non-matching findings\n")
              output_PVStenosis <- PVStenosis_1 
              output_PVStenosisError <- "PVStenosis: Error, non-matching findings"
            }
          } else {
            cat("PVStenosis: Error, no PV Stenosis categorization found in conclusions PV Stenosis sentence\n")
            output_PVStenosis <- PVStenosis_1 
            output_PVStenosisError <- "PV Stenosis: Error, no PV Stenosis categorization found in conclusions PV Stenosis sentence"
          }
          
        } else {
          cat("PV Stenosis: Error, no PV Stenosis conclusions sentence found\n")
          output_PVStenosis <- PVStenosis_1 
          output_PVStenosisError <- "PV Stenosis: Error, no PV Stenosis conclusions sentence found"
        }
      }
    } else {
      cat("PV Stenosis: Error, no PV Stenosis categorization found in doppler sentence\n")
      output_PVStenosis <- ""
      output_PVStenosisError <- "PV Stenosis: Error, no PV Stenosis categorization found in doppler sentence"
    }
    
    
  } else {
    cat("PV Stenosis: Error, no PV Stenosis doppler sentence found\n")
    output_PVStenosis <- ""
    output_PVStenosisError <- "PV Stenosis: Error, no PV Stenosis doppler sentence found"
  }
  
  # PASP estimate - PASP only found in conclusions, when normal not noted in the report
  pattern_pasp <- "(mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately to severely|moderately - severely|moderately-severely|moderately|severely|could not assess|could not determine)(?:\\selevated)?\\s+(?:pulmonary artery systolic pressure|pulmonary hypertension|pulmonary systolic pressure|right ventricular systolic pressure)"
  match_pasp <- regexec(pattern_pasp, document_text, perl = TRUE, ignore.case = TRUE)
  
  output_pasp <- ""
  
  if (!is.na(match_pasp[[1]][1])) {
    PASP <- tolower(regmatches(document_text, match_pasp)[[1]][2])
    cat(sprintf("%s\n", PASP))
    output_pasp <- sprintf("%s", PASP)
  } else {
    pattern_pasp_rvsp <- "(?:right ventricular systolic pressure|pulmonary artery systolic pressure|pulmonary systolic pressure)\\sis\\s(low normal|normal)"
    match_pasp_rvsp <- regexec(pattern_pasp_rvsp, document_text, perl = TRUE, ignore.case = TRUE)
    
    if (!is.na(match_pasp_rvsp[[1]][1])) {
      PASP_rvsp <- tolower(regmatches(document_text, match_pasp_rvsp)[[1]][2])
      cat(sprintf("%s\n", PASP_rvsp))
      output_pasp <- sprintf("%s", PASP_rvsp)
    } else {
      pattern_pasp_TR <- "(?:PA systolic pressure|PASP).*?unable to be assessed.*?(tricuspid insufficiency)"
      match_pasp_TR <- regexec(pattern_pasp_TR, document_text, perl = TRUE, ignore.case = TRUE)
      
      if (!is.na(match_pasp_TR[[1]][1])) {
        PASP_TR <- tolower(regmatches(document_text, match_pasp_TR)[[1]][2])
        cat(sprintf("%s\n", PASP_TR))
        output_pasp <- sprintf("%s", PASP_TR)
      } else {
        cat("PASP estimate not found in the document.\n")
        output_pasp <- ""
      }
    }
  }
  
  #PASP Value
  
  # The initial pattern to look for PASP information
  PASP_initial_pattern <- "(?i)((?:right ventricular systolic pressure|pulmonary artery systolic pressure|pulmonary systolic pressure)(?:.(?!Pulmonic Valve|Venous|CONCLUSIONS))*?mmHg)"
  
  # Extract the portion of the text that matches the initial pattern
  PASP_initial_match <- str_match(document_text, PASP_initial_pattern)
  
  # Initialize output variable
  output_PASP_value <- ""
  
  # If the initial pattern is found
  if (!is.na(PASP_initial_match[1, 2])) {
    # Extract the matched portion (first capturing group)
    PASP_matched_portion <- PASP_initial_match[1, 2]
    
    # Pattern to find the PASP value within the matched portion
    PASP_value_pattern <- "(\\d+(?:\\.\\d+)?)"
    
    # Extract the PASP value
    PASP_value_match <- str_match(PASP_matched_portion, PASP_value_pattern)
    
    # If the PASP value is found, assign it to the output variable
    if (!is.na(PASP_value_match[1, 2])) {
      output_PASP_value <- PASP_value_match[1, 2]
    }
  }
  
  cat("PASP Value:", output_PASP_value, "\n")
  
  # Append data to the output list
  
    output_df <- data.frame(
      `Echo` = sprintf("Echo report %d", file_counter),
      `Procedure Name` = df$PROCEDURE_NAME[index],  # Add other columns as needed
      `Date of Echo` = output_date,
      `Age` = output_age,
      `Systolic Blood Pressure` = output_systolicbp,
      `Diastolic Blood Pressure` = output_diastolicbp,
      `Heart Rate` = output_hr,
      `BSA` = output_bsa,
      `LA Size` = output_LAsize,
      `LA Size Error` = output_LAsizeError,
      `LV Size` = output_LVSize,
      `LV Hypertrophy` = output_LVH_Severity,
      `LV Hypertrophy Type` = output_LVHtype,
      `LV Hypertrophy Error` = output_LVHError,
      `LV Thickness` = output_LVThickness,
      `LV Thickness Error` = output_LVThicknessError,
      `LVDiD` = output_LVDiD,
      `LVDiD Error` = output_LVDiDError,
      `LV Function` = output_LVFunction,
      `LV Function Error` = output_LVFunctionError,
      `Simpsons LVEF` = output_simpsonLVEF,
      `Simpsons LVEF Error` = output_simpsonError,
      `LVEF %` = output_LVEF,
      `LVEF % Error` = output_LVEFError,
      `RA Size` = output_RAsize,
      `RA Size Error` = output_RASizeError,
      `IVC Size` = output_IVCSize,
      `IVC Size Error` = output_IVCSizeError,
      `IVC Collapsibility` = output_IVCCollapsibility,
      `IVC Collapsibility Error` = output_IVCCollapsibilityError,
      `IVC RA Pressure` = output_IVC_RAPressure,
      `IVC RA Pressure Error` = output_IVC_RAPressureError,
      `Assumed RA Pressure` = output_AssumedRAP,
      `RV Function` = output_RVFunction,
      `RV Function Error` = output_RVFunctionError,
      `MV Regurgitation` = output_MR,
      `MV Regurgitation Error` = output_MRError,
      `MV Structure` = output_MVStructure,
      `MV Structure Error` = output_MVStructureError,
      `MV Motion` = output_MVMotion,
      `MV Implant` = output_MVimplant,
      `MV Leaflet #` = output_MVLeafletNumber,
      `MV Sclerosis` = output_MVSclerosis,
      `MV Annular Calcification` = output_MVAnnularCalcification,
      `MV Subvalvular Calcification` = output_MVSubvalvularCalcification,
      `MV Calcification` = output_MVCalcification,
      `MV Calcification Error` = output_MVCalcificationError,
      `MV Leaflet Mobility` = output_MVLeafletMobility,
      `MV Leaflet Mobility Error` = output_MVLeafletMobilityError,
      `MV Anterior Leaflet Structure` = output_anteriorleafletstructure,
      `MV Anterior Leaflet Mobility` = output_MVALM,
      `MV Posterior Leaflet Structure` = output_posteriorleafletstructure,
      `MV Posterior Leaflet Mobility` = output_MVPLM,
      `MV Posterior Leaflet Mobility Error` = output_MVPLMError,
      `MV Leaflet Structure Error` = output_leafletstructure_error,
      `MV Stenosis` = output_MVStenosis,
      `MV Stenosis Error` = output_MVStenosisError,
      `AV Regurgitation` = output_AR,
      `AV Regurgitation Error` = output_ARError,
      `AV Structure` = output_AVStructure,
      `AV Structure Error` = output_AVStructureError,
      `AV Implant` = output_AVimplant,
      `AV Leaflet #` = output_AVLeafletNumber,
      `AV Sclerosis` = output_AVSclerosis,
      `AV Calcification` = output_AVCalcification,
      `AV Calcification Error` = output_AVCalcificationError,
      `AV NCC Structure` = output_NCC_leafletstructure,
      `AV NCC Mobility` = output_AVNCCM,
      `AV NCC Mobility Error` = output_AVNCCMError,
      `AV RCC Structure` = output_RCC_leafletstructure,
      `AV RCC Mobility` = output_AVRCCM,
      `AV RCC Mobility Error` = output_AVRCCMError,
      `AV LCC Structure` = output_LCC_leafletstructure,
      `AV LCC Mobility` = output_AVLCCM,
      `AV LCC Mobility Error` = output_AVLCCMError,
      `AV Leaflets Structure Error` = output_AVleafletstructure_error,
      `AV Stenosis` = output_AVStenosis,
      `AV Stenosis Error` = output_AVStenosisError,
      `AV Gradient` = output_AVGradient,
      `AV Peak Gradient` = output_AVPeakGradient,
      `AV Area` = output_AVArea,
      `LVOT Diameter` = output_LVOTDiameter,
      `AV Peak Velocity` = output_AVPeakVelocity,
      `AV Dimensionless Index` = output_AVDimensionlessIndex,
      `AV iSV` = output_AViSV,
      `TV Regurgitation` = output_TR,
      `TV Regurgitation Error` = output_TRError,
      `TV Structure` = output_TVStructure,
      `TV Structure Error` = output_TVStructureError,
      `TV Implant` = output_TVStenosis,
      `TV Leaflet #` = output_TVLeafletNumber,
      `TV Sclerosis` = output_TVSclerosis,
      `TV Calcification` = output_TVCalcification,
      `TV Calcification Error` = output_TVCalcificationError,
      `TV Stenosis` = output_TVStenosis,
      `TV Stenosis Error` = output_TVStenosisError,
      `PV Regurgitation` = output_PR,
      `PV Regurgitation Error` = output_PRError,
      `PV Structure` = output_PVStructure,
      `PV Structure Error` = output_PVStructureError,
      `PV Implant` = output_PVimplant,
      `PV Leaflet #` = output_PVLeafletNumber,
      `PV Sclerosis` = output_PVSclerosis,
      `PV Calcification` = output_PVCalcification,
      `PC Calcification Error` = output_PVCalcificationError,
      `PV Stenosis` = output_PVStenosis,
      `PV Stenosis Error` = output_PVStenosisError,
      `TR Velocity` = output_TRvelocity,
      `PASP` = output_pasp,
      `PASP_Value` = output_PASP_value
    )
    output_list <- c(output_list, list(output_df))
}

# Create a data frame from the output list
output_data <- do.call(rbind, output_list)

# Rename the columns to ensure uniqueness
colnames(output_data) <- make.unique(as.character(colnames(output_data)))

# Write the data frame to an Excel file
write.xlsx(output_data, '/Users/Nischal/TTE_DataExtraction/CSV_Echo Variables Output_R.xlsx', rowNames = FALSE)
