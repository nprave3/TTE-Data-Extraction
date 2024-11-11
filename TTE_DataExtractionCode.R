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
    output_date <- "Date not found in document"
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
    output_age <- "Age not found in the document"
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
    output_systolicbp <- "Blood pressure not found in the document"
    output_diastolicbp <- "Blood pressure not found in the document"
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
    output_hr <- "Heart rate not found in document"
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
    output_bsa <- "BSA not found in document"
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
    if (match_LAsize_1[1] %in% c("mildly", "normal", "not well seen", "likely normal")) {
      cat(sprintf("LA Size: %s\n", match_LAsize_1[1]))
      output_LAsize <- sprintf("%s", match_LAsize_1[1])
    }
    
    # Case when match for pattern 1 is not "mildly" or "normal"
    else if (!(match_LAsize_1 %in% c("mildly", "normal", "not well seen", "likely normal"))) {
      if (num_matches_LAsize_1 > 1 && num_matches_LAsize_2 == 0 && num_matches_LAsize_3 == 0) {
        if (all(match_LAsize_1 == matches_LAsize_1[[1]][, 2])) {
          cat(sprintf("LA Size: %s\n", match_LAsize_1))
          output_LAsize <- sprintf("%s", match_LAsize_1)
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
  
  if (length(match_LVSize[[1]]) > 0) {
    cat(sprintf("LV Size: %s\n", match_LVSize[[1]][2]))
    output_LVSize <- match_LVSize[[1]][2]
  } else {
    cat("LV Size: No LV Size match found\n")
    output_LVSize <- "No LV Size match found"
  }
  
  
  # LV Hypertrophy (wall thickness)
  
  # Define a dictionary of equivalent values
  equivalent_values_dict <- c(
    "moderately" = "moderate",
    "moderately - severely" = "moderate - severe",
    "moderately-severely" = "moderate-severe",
    "moderately to severely" = "moderate to severe",
    "severely" = "severe"
  )
  
  pattern_LVHypertrophy <- "Ventricular wall thickness is (normal|mildly to moderately|mildly - moderately|mildly-moderately|mildly|moderately - severely|moderately-severely|moderately to severely|moderately|severely)(?:\\s+)?(?:dilated|increased)?"
  match_LVHypertrophy <- regmatches(document_text, regexec(pattern_LVHypertrophy, document_text, ignore.case = TRUE))
  
  output_LVHypertrophy <- ""
  output_LVHypertrophyError <- ""
  
  if (length(match_LVHypertrophy[[1]]) > 0) {
    match_value <- match_LVHypertrophy[[1]][2]
    
    if (match_value %in% c("normal", "mildly", "mildly to moderately", "mildly - moderately", "mildly-moderately")) {
      cat(sprintf("LV Hypertrophy: %s\n", match_value))
      output_LVHypertrophy <- match_value
    } else if (match_value %in% c("moderately - severely", "moderately-severely", "moderately to severely", "moderately", "severely")) {
      pattern_LVHypertrophy2 <- "(moderate - severe|moderate-severe|moderate to severe|moderate|severe) \\w+? left ventricular hypertrophy"
      match_LVHypertrophy2 <- regmatches(document_text, regexec(pattern_LVHypertrophy2, document_text, ignore.case = TRUE))
      
      if (length(match_LVHypertrophy2[[1]]) > 0) {
        equivalent_value <- equivalent_values_dict[tolower(match_value)]
        
        if (equivalent_value == tolower(match_LVHypertrophy2[[1]][2])) {
          cat(sprintf("LV Hypertrophy: %s\n", match_value))
          output_LVHypertrophy <- match_value
        } else {
          cat(sprintf("LV Hypertrophy: Non-identical LV Hypertrophy matches found, pattern 1 = %s, pattern 2 = %s\n", match_value, match_LVHypertrophy2[[1]][1]))
          output_LVHypertrophy <- match_value
          output_LVHypertrophyError <- sprintf("Non-identical LV Hypertrophy matches found, pattern 1 = %s, pattern 2 = %s", match_value, match_LVHypertrophy2[[1]][1])
        }
      } else {
        pattern_LVHypertrophy3 <- "(?:CONCLUSIONS:.*?)Ventricular wall thickness is (moderately - severely|moderately-severely|moderately to severely|moderately|severely)(?:\\s+)?(?:dilated|increased)?"
        match_LVHypertrophy3 <- regmatches(document_text, regexec(pattern_LVHypertrophy3, document_text, ignore.case = TRUE))
        
        if (length(match_LVHypertrophy3[[1]]) > 0) {
          equivalent_value <- equivalent_values_dict[tolower(match_value)]
          
          if (equivalent_value == tolower(match_LVHypertrophy3[[1]][1])) {
            cat(sprintf("LV Hypertrophy: %s\n", match_value))
            output_LVHypertrophy <- match_value
          } else {
            cat(sprintf("LV Hypertrophy: Non-identical LV Hypertrophy matches found, pattern 1 = %s, pattern 3 = %s\n", match_value, match_LVHypertrophy3[[1]][1]))
            output_LVHypertrophy <- match_value
            output_LVHypertrophyError <- sprintf("Non-identical LV Hypertrophy matches found, pattern 1 = %s, pattern 3 = %s", match_value, match_LVHypertrophy3[[1]][1])
          }
        } else {
          cat("LV Hypertrophy: No match found for pattern 2 & 3\n")
          output_LVHypertrophy <- match_value
          output_LVHypertrophyError <- "No match found for pattern 2 & 3"
        }
      }
    }
  } else {
    pattern_LVHypertophy4 <- "(?:There is )?([Nn]o|[Mm]ild to moderate|[Mm]ild - moderate|[Mm]ild-moderate|[Mm]ild|[Mm]oderate - severe|[Mm]oderate-severe|[Mm]oderate to severe|[Mm]oderate|[Ss]evere|[Ee]ccentric)(?:\\s+)?(?:\\w+)?(?:\\s+)?(?:LV|left ventricular)(?:\\shypertrophy)"
    match_LVHypertrophy4 <- str_match(document_text, pattern_LVHypertophy4)
    if (!is.na(match_LVHypertrophy4[1, 2])) {
      match_LVH4 <- tolower(match_LVHypertrophy4[1, 2])
      output_LVHypertrophy <- tolower(match_LVH4)
      cat(sprintf("LV Hypertrophy: %s\n", match_LVH4))
    } else {
      cat("LV Hypertrophy: No match found for LV Hypertrophy\n")
      output_LVHypertrophyError <- "LV Hypertrophy: Error, No match found for LV Hypertrophy"
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
    output_LVDiD <- "LVDiD not found in the document"
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
  
  # WORD DOCUMENT LVEF%
  
  pattern_LVEF_1 <- "(?:Visual Est LVEF\\D*)(\\d+)(?:\\s+)?%"
  matches_LVEF_1 <- str_match(document_text, pattern_LVEF_1)
  
  pattern_LVEF_2 <- "(?<=CONCLUSIONS).*?(?:LV|lv|left\\sventricular|Left\\sventricular)(?:\\s\\w+\\s\\w+\\s\\w+)?(?:EF|ef|\\sejection\\sfraction)(?:\\D+)(\\d+)"
  matches_LVEF_2 <- str_match(document_text, pattern_LVEF_2)
  
  output_LVEF <- ""
  output_LVEFError <- ""
  if (!is.na(matches_LVEF_1 [1, 2])) {
    if (!is.na(matches_LVEF_2 [1, 2])) {
      if (identical(matches_LVEF_1 [1, 2], matches_LVEF_2 [1, 2])) {
        cat(sprintf("LVEF: %s\n", matches_LVEF_1 [1, 2]))
        output_LVEF <- matches_LVEF_1 [1, 2]
      } else {
        cat(sprintf("LVEF: Different 2D Echo measurement value and conclusions value found. Visually Est LVEF%%: %s, Conclusions: %s\n", matches_LVEF_1 [1, 2], matches_LVEF_2 [1, 2]))
        output_LVEF <- matches_LVEF_1 [1, 2]
        output_LVEFError <- sprintf("Different 2D Echo measurement value and conclusions for pattern 2 found. Visually Est LVEF%%: %s, Conclusions: %s", matches_LVEF_1 [1, 2], matches_LVEF_2 [1, 2])
      }
    } else {
      cat(sprintf("LVEF: Error, no LVEF in conclusions %s\n", matches_LVEF_1 [1, 2]))
      output_LVEF <- matches_LVEF_1 [1, 2]
      output_LVEFError <- "Error, no LVEF in conclusions"
    }
  } else {
    cat("LVEF: Error, no LVEF% matches found for pattern_LVEF_1\n")
    output_LVEF <- ""
    output_LVEFError <- "Error, no LVEF found for pattern 1"
  }
  
  #Test
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
  
  # Right atrial pressure - add else statement for when PA systolic pressure is not assessed
  pattern_RAP <- "right atrial pressure of (\\d+(?:\\.\\d+)?) mmHg"
  match_RAP <- str_match(document_text, pattern_RAP)
  
  if (!is.na(match_RAP[1, 2])) {
    RA_pressure <- match_RAP [1, 2]
    cat(sprintf("RAP: %s\n", RA_pressure))
    output_RAP <- sprintf("%s", RA_pressure)
  } else {
    pattern_RAP_No_IVC <- "(IVC is [Nn]ot well seen|IVC is [Nn]ot clearly seen|IVC size is [Nn]ot well seen|IVC size is [Nn]ot clearly seen|IVC size is [Nn]ot visualized|IVC size is [Nn]ot clearly visualized|IVC size is [Nn]ot well visualized|IVC size could [Nn]ot be determined|IVC size could [Nn]ot be assessed|IVC size could [Nn]ot be ascertained|IVC size was [Nn]ot acquired|IVC size was [Nn]ot assessed|IVC size was [Nn]ot determined)"
    match_RAP_IVC <- str_match(document_text, pattern_RAP_No_IVC)
    
    if (!is.na(match_RAP_IVC [1, 2])) {
      IVC_1 <- match_RAP_IVC [1, 2]
      cat(sprintf("RAP: IVC - %s\n", IVC_1))
      output_RAP <- sprintf("%s", IVC_1)
    } else {
      pattern_RAP_IVC_Pressure_Type <- "IVC(?:\\ssize)?.*?(normal RA pressure|normal right atrial pressure|normal right atrium pressure|low RA pressure|low right atrial pressure|low right atrium pressure)"
      match_RAP_IVC_Pressure_Type <- str_match(document_text, pattern_RAP_IVC_Pressure_Type)
      
      if (!is.na(match_RAP_IVC_Pressure_Type [1, 2])) {
        IVC_2 <- match_RAP_IVC_Pressure_Type [1, 2]
        cat(sprintf("RAP: IVC Pressure - %s\n", IVC_2))
        output_RAP <- sprintf("%s", IVC_2)
      } else {
        pattern_RAP_IVC_Pressure <- "IVC size is dilated.*?(?:RA|right atrial|right atrium) pressure.*?(\\d+ - \\d+|\\d+-\\d+|\\d+)\\s?mmHg"
        match_RAP_IVC_Pressure <- str_match(document_text, pattern_RAP_IVC_Pressure)
        
        if (!is.na(match_RAP_IVC_Pressure [1, 2])) {
          IVC_3 <- match_RAP_IVC_Pressure [1, 2]
          cat(sprintf("RAP: IVC size dilated, RA pressure - %s\n", IVC_3))
          output_RAP <- sprintf("%s", IVC_3)
        } else {
          cat("RAP: Right atrial pressure not found in the document.\n")
          output_RAP <- "Right atrial pressure not found in the document"
        }
      }
    }
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
  
  
  #Mitral Regurgitation
  
  MRsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Mitral valve regurgitation|mitral valve regurgitation|Mitral regurgitation|mitral regurgitation)[^.]*).*CONCLUSIONS"
  MRsentence_matches_1 <- str_match(document_text, MRsentence_pattern_1)
  MRsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Mitral valve regurgitation|mitral valve regurgitation|Mitral regurgitation|mitral regurgitation)[^.]*)"
  MRsentence_matches_2 <- str_match(document_text, MRsentence_pattern_2)
  
  output_MR <- ""
  output_MRError <- ""
  
  if (!is.na(MRsentence_matches_1 [1, 2])) {
    MRsentence_1 <- MRsentence_matches_1 [1, 2]
    cat(sprintf("MR Sentence 1: %s\n", MRsentence_1))
    MR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    MR_1_match <- str_match(MRsentence_1, MR_1_pattern)
    
    if (!is.na(MR_1_match [1, 2])) {
      MR_1 <- tolower(MR_1_match [1, 2])
      if (MR_1 == "no" | MR_1 == "trivial" | MR_1 == "mild" | MR_1 == "mild-moderate" | MR_1 == "mild - moderate" | MR_1 == "mild to moderate" | MR_1 == "not assessed" | MR_1 == "shadowing from the prosthesis") {
        output_MR <- MR_1
        cat(sprintf("MR: %s\n", MR_1))
      } else {
        if (!is.na(MRsentence_matches_2 [1, 2])) {
          MRsentence_2 <- MRsentence_matches_2 [1, 2]
          MR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          MR_2_match <- str_match(MRsentence_2, MR_2_pattern)
          if (!is.na(MR_2_match [1, 2])) {
            MR_2 <- tolower(MR_2_match [1, 2])
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
    cat("MR: Error, no MR doppler sentence found")
    output_MR <- ""
    output_MRError <- "MR: Error, no MR doppler sentence found"
  }
  
  #Mitral Valve Structure
  
  MVStructuresentence_pattern_1 <- "Mitral Valve:.*?([^.]*(?:Mitral valve|mitral valve)(?:\\sis|\\sappears|\\sValve|\\sgrossly|\\snot well seen|\\shas a|\\sabnormal|\\w+\\smechanical|\\w+\\sbioprosthesis)[^.]*).*?(?:Tricuspid Valve:|Pulmonic Valve:|CONCLUSIONS)"
  MVStructuresentence_matches_1 <- str_match(document_text, MVStructuresentence_pattern_1)
  
  output_MVStructure <- ""
  output_MVStructureError <- ""
  
  if (!is.na(MVStructuresentence_matches_1 [1, 2])) {
    MVStructuresentence_1 <- MVStructuresentence_matches_1 [1, 2]
    cat(sprintf("MV Structure Sentence 1: %s\n", MVStructuresentence_1))
    MVStructure_1_pattern <- "(normal|Normal|mildly-moderately|Mildly-moderately|mildly to moderately|Mildly to moderately|mildly|Mildly|moderately|Moderately|moderately-severely|Moderately-severely|moderately to severely|Moderately to severely|moderately|Moderately|severely|Severely|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|bioprosthetic valve|thickened|rheumatic|calcified|mechanical)"
    MVStructure_1_match <- str_match(MVStructuresentence_1, MVStructure_1_pattern)
    
    if (!is.na(MVStructure_1_match [1, 2])) {
      MVStructure_1 <- tolower(MVStructure_1_match [1, 2])
      output_MVStructure <- MVStructure_1
      cat(sprintf("MV Structure: %s\n", MVStructure_1))
    } else {
      MVStructure_2_pattern <- "(bicuspid|tricuspid|trileaflet|abnormal|mechanical|bioprosthesis)"
      MVStructure_2_match <- str_match(MVStructuresentence_1, MVStructure_2_pattern)
      if (!is.na(MVStructure_2_match [1, 2])){
        MVStructure_2 <- MVStructure_2_match [1, 2]
        output_MVStructure <- MVStructure_2
        cat(sprintf("MV Structure: %s\n", MVStructure_2))
      } else {
        cat("MV Structure: Error, no MV structure categorization found in doppler sentence")
        output_MVStructure <- ""
        output_MVStructureError <- "Error, no MV structure categorization found in doppler sentence"
      }
    }
  } else {
    MVStructuresentence_pattern_2 <- "Mitral Valve:.*?(Bioprosthetic valve|bioprosthetic valve).*?(?:Tricuspid valve|tricuspid valve)"
    MVStructuresentence_matches_2 <- str_match(document_text, MVStructuresentence_pattern_2)
    if (!is.na(MVStructuresentence_matches_2 [1, 2])) {
      MVStructure_match_2 <- MVStructuresentence_matches_2 [1, 2]
      cat(sprintf("MV Structure: %s\n", MVStructure_match_2))
      output_MVStructure <- MVStructure_match_2
    } else {
      MVStructuresentence_pattern_3 <- "Mitral Valve:.*?([^.]*anterior and posterior leaflets[^.]*).*?(?:Tricuspid Valve:|Pulmonic Valve:|CONCLUSIONS)"
      MVStructuresentence_matches_3 <- str_match(document_text, MVStructuresentence_pattern_3)
      if (!is.na(MVStructuresentence_matches_3 [1, 2])) {
        MVStructuresentence_2 <- MVStructuresentence_matches_3 [1, 2]
        MVStructure_2_pattern <- "(normal|Normal|mildly-moderately|Mildly-moderately|mildly to moderately|Mildly to moderately|mildly|Mildly|moderately|Moderately|moderately-severely|Moderately-severely|moderately to severely|Moderately to severely|moderately|Moderately|severely|Severely|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|bioprosthetic valve|thickened|rheumatic|calcified|mechanical)"
        MVStructure_2_match <- str_match(MVStructuresentence_2, MVStructure_2_pattern) 
        cat(sprintf("MV Structure: %s\n", MVStructuresentence_2))
        if (!is.na(MVStructure_2_match [1, 2])) {
          output_MVStructure <- MVStructure_2_match [1, 2]
          cat(sprintf("MV Structure: %s\n", MVStructure_2_match [1, 2]))
        } else {
          output_MVStructure <- ""
          output_MVStructureError <- "No categorization found"
        }
      } else {
      cat("MV Structure: Error, no MV Structure doppler sentence found")
      output_MVStructure <- ""
      output_MVStructureError <- "Error, no MV Structure doppler sentence found"
      }
    }
  } 
  
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
    MVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
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
  
  # Tricuspid regurgitant velocity
  pattern_TRvelocity <- "(?:tricuspid regurgitant velocity is)\\s+(\\d+\\.\\d+)"
  match_TRvelocity <- regexec(pattern_TRvelocity, document_text, perl = TRUE, ignore.case = TRUE)
  
  if (!is.na(match_TRvelocity[[1]][1])) {
    TR_velocity <- regmatches(document_text, match_TRvelocity)[[1]][2]
    cat(sprintf("TR Velocity: %s\n", TR_velocity))
    output_TRvelocity <- sprintf("%s", TR_velocity)
  } else {
    cat("TR Velocity: Tricuspid regurgitant velocity not found in the document.\n")
    output_TRvelocity <- "Tricuspid regurgitant velocity not found in the document"
  }
  
  #Aortic Regurgitation
  
  ARsentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Aortic valve regurgitation|aortic valve regurgitation|Aortic regurgitation|aortic regurgitation|Aortic insufficiency|aortic insufficiency|Aortic valve insufficiency|aortic valve insufficiency)[^.]*).*CONCLUSIONS"
  ARsentence_matches_1 <- str_match(document_text, ARsentence_pattern_1)
  ARsentence_pattern_2 <- "CONCLUSIONS.*?([^.]*(?:Aortic valve regurgitation|aortic valve regurgitation|Aortic regurgitation|aortic regurgitation|Aortic insufficiency|aortic insufficiency|Aortic valve insufficiency|aortic valve insufficiency)[^.]*)"
  ARsentence_matches_2 <- str_match(document_text, ARsentence_pattern_2)
  
  output_AR <- ""
  output_ARError <- ""
  
  if (!is.na(ARsentence_matches_1 [1, 2])) {
    ARsentence_1 <- ARsentence_matches_1 [1, 2]
    cat(sprintf("AR Sentence 1: %s\n", ARsentence_1))
    AR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    AR_1_match <- str_match(ARsentence_1, AR_1_pattern)
    
    
    
    if (!is.na(AR_1_match [1, 2])) {
      AR_1 <- tolower(AR_1_match [1, 2])
      if (AR_1 == "no" | AR_1 == "trivial" | AR_1 == "mild" | AR_1 == "mild-moderate" | AR_1 == "mild - moderate" | AR_1 == "mild to moderate" | AR_1 == "not assessed" | AR_1 == "shadowing from the prosthesis") {
        output_AR <- AR_1
        cat(sprintf("AR: %s\n", AR_1))
      } else {
        if (!is.na(ARsentence_matches_2 [1, 2])) {
          ARsentence_2 <- ARsentence_matches_2 [1, 2]
          AR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
          AR_2_match <- str_match(ARsentence_2, AR_2_pattern)
          if (!is.na(AR_2_match [1, 2])) {
            AR_2 <- tolower(AR_2_match [1, 2])
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
            output_ARError <- "AR: Error, no AR conclusions sentence found"}
          
        }
      }
    } else {
      cat("AR: Error, no AR categorization found in doppler sentence\n")
      output_AR <- ""
      output_ARError <- "AR: Error, no AR categorization found in doppler sentence"
    }
    
    
  } else {
    cat("AR: Error, no AR doppler sentence found\n")
    output_AR <- ""
    output_ARError <- "AR: Error, no AR doppler sentence found"
  }
  
  #Aortic Valve Structure
  
  AVStructuresentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Aortic valve|aortic valve)(?:\\sis|\\sappears|\\snot well seen|\\snormal)[^.]*).*CONCLUSIONS"
  AVStructuresentence_matches_1 <- str_match(document_text, AVStructuresentence_pattern_1)
  
  output_AVStructure <- ""
  output_AVStructureError <- ""
  
  if (!is.na(AVStructuresentence_matches_1 [1, 2])) {
    AVStructuresentence_1 <- AVStructuresentence_matches_1 [1, 2]
    cat(sprintf("AV Structure Sentence 1: %s\n", AVStructuresentence_1))
    AVStructure_1_pattern <- "(normal|Normal|mildly-moderately|Mildly-moderately|mildly to moderately|Mildly to moderately|mildly|Mildly|moderately|Moderately|moderately-severely|Moderately-severely|moderately to severely|Moderately to severely|moderately|Moderately|severely|Severely|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|bioprosthetic valve)"
    AVStructure_1_match <- str_match(AVStructuresentence_1, AVStructure_1_pattern)
    
    if (!is.na(AVStructure_1_match [1, 2])) {
      AVStructure_1 <- tolower(AVStructure_1_match [1, 2])
      output_AVStructure <- AVStructure_1
      cat(sprintf("AV Structure: %s\n", AVStructure_1))
    } else {
      AVStructure_2_pattern <- "(bicuspid|tricuspid|trileaflet)"
      AVStructure_2_match <- str_match(AVStructuresentence_1, AVStructure_2_pattern)
      if (!is.na(AVStructure_2_match [1, 2])){
        AVStructure_2 <- AVStructure_2_match [1, 2]
        output_AVStructure <- AVStructure_2
        cat(sprintf("AV Structure: %s\n", AVStructure_2))
      } else {
      cat("AV Structure: Error, no AV structure categorization found in doppler sentence\n")
      output_AVStructure <- ""
      output_AVStructureError <- "Error, no AV structure categorization found in doppler sentence"
      }
    }
  } else {
    AVStructuresentence_pattern_2 <- "Aortic Valve:.*?(Bioprosthetic valve|bioprosthetic valve).*?(?:Mitral valve|mitral valve)"
    AVStructuresentence_matches_2 <- str_match(document_text, AVStructuresentence_pattern_2)
    if (!is.na(AVStructuresentence_matches_2 [1, 2])) {
      AVStructure_match_2 <- AVStructuresentence_matches_2 [1, 2]
      cat(sprintf("AV Structure: %s\n", AVStructure_match_2))
      output_AVStructure <- AVStructure_match_2
    } else {
    cat("AV Structure: Error, no AV Structure doppler sentence found\n")
    output_AVStructure <- ""
    output_AVStructureError <- "Error, no AV Structure doppler sentence found"
    }
  } 
  
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
    AVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild\\b|Mild\\b|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate\\b|Moderate\\b|severe\\b|Severe\\b|no\\b|No\\b|trace\\b|Trace\\b|trivial\\b|Trivial\\b|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    AVStenosis_1_match <- str_match(AVStenosissentence_1, AVStenosis_1_pattern)
    
    if (!is.na(AVStenosis_1_match [1, 2])) {
      AVStenosis_1 <- tolower(AVStenosis_1_match [1, 2])
      if (AVStenosis_1 == "no" | AVStenosis_1 == "trivial"|AVStenosis_1 == "trace") {
        output_AVStenosis <- AVStenosis_1
        cat(sprintf("AV Stenosis: %s\n", AVStenosis_1))
      } else {
        if (!is.na(AVStenosissentence_matches_2 [1, 2])) {
          
          AVGradient_pattern <- "CONCLUSIONS.*?(?:M[a-z][a-z]n|m[a-z][a-z]n)(?:\\sAV)?(?:\\sPG|\\spressure\\sgradient|\\sgradient)(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?\\s(\\d+(?:.)?\\d+)"
          AVGradient_match <- str_match(document_text, AVGradient_pattern)
          AVPeakGradient_pattern <- "CONCLUSIONS.*?(?:P[a-z][a-z]k|p[a-z][a-z]k)(?:\\sAV)?(?:\\sPG|\\spressure\\sgradient|\\sgradient)\\D+(\\d+(?:.)?\\d+)"
          AVPeakGradient_match <- str_match(document_text, AVPeakGradient_pattern)
          AVArea_pattern <- "CONCLUSIONS.*?(?:Aortic stenosis|aortic stenosis).*?(?:Valve|valve) area(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?\\s(\\d+(?:.)?\\d+)"
          AVArea_match <- str_match(document_text, AVArea_pattern)
          AVArea_pattern_2 <- "CONCLUSIONS.*?AVA\\s+(\\d+(?:\\.\\d+)?)"
          AVArea_match_2 <- str_match(document_text, AVArea_pattern_2)
          AVArea_pattern_3 <- "CONCLUSIONS.*?AVA\\D+(?:\\d+(?:\\.\\d+)?)(?:\\s)?(?:cm)?\\s\\w+\\s(\\d+(?:\\.\\d+)?)"
          AVArea_match_3 <- str_match(document_text, AVArea_pattern_3)
          AVArea_pattern_4 <- "CONCLUSIONS.*?(?:Aortic|aortic)(?:\\svalve\\sarea)(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?\\s(\\d+(?:.)?\\d+)"
          AVArea_match_4 <- str_match(document_text, AVArea_pattern_4)
          
          LVOTDiameter_pattern <- "CONCLUSIONS.*?AVA\\D+LVOT\\D+(\\d+(?:\\.\\d+)?)(?:\\s)?(?:cm)?\\s\\w+\\s(?:\\d+(?:\\.\\d+)?)"
          LVOTDiameter_match <- str_match(document_text, LVOTDiameter_pattern)
          LVOTDiameter_pattern_2 <- "CONCLUSIONS.*?LVOT(?:\\sdiameter)?(?:\\sof)?\\s(\\d+(?:\\.\\d+)?)"
          LVOTDiameter_match_2 <- str_match(document_text, LVOTDiameter_pattern_2)
          AVPeakVelocity_pattern <- "CONCLUSIONS.*?(?:Peak|peak)(?:\\sAV)? (?:velocity|velocities)(?:\\s\\w+)?(?:\\s\\w+)?(?:\\s\\w+)?\\s(\\d+(?:.\\d+)?)"
          AVPeakVelocity_match <- str_match(document_text, AVPeakVelocity_pattern)
          AVPeakVelocity_pattern_2 <- "CONCLUSIONS.*?(?:Vmax|VMAX|VMax|vmax)(?:\\sAV)?\\D+(\\d+(?:.\\d+)?)"
          AVPeakVelocity_match_2 <- str_match(document_text, AVPeakVelocity_pattern_2)
          AVDimensionlessIndex_pattern <- "CONCLUSIONS.*?\\b(?:DI|Dimensionless index|Dimensionless Index|dimensionless index)\\b(?:\\sof|\\sis)?\\D+(\\d+(?:.\\d+)?)"
          AVDimensionlessIndex_match <- str_match(document_text, AVDimensionlessIndex_pattern)
          AViSV_pattern <- "CONCLUSIONS.*?(?:iSV|SVi|SVI|indexed stroke volume|stroke volume index)\\D+(\\d+(?:.)?\\d+)"
          AViSV_match <- str_match(document_text, AViSV_pattern)
          
          if (!is.na(AVGradient_match [1, 2])) {
            output_AVGradient <- AVGradient_match [1, 2]
            cat(sprintf("AV Gradient: %s\n", AVGradient_match [1, 2]))
          } else {
            output_AVGradient <- ""
            cat("AV Gradient: No match found\n")
          }
          if (!is.na(AVPeakGradient_match [1, 2])) {
            output_AVPeakGradient <- AVPeakGradient_match [1, 2]
            cat(sprintf("AV Peak Gradient: %s\n", AVPeakGradient_match [1, 2]))
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
          AVStenosis_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild\\b|Mild\\b|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate\\b|Moderate\\b|severe\\b|Severe\\b|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
          AVStenosis_2_match <- str_match(AVStenosissentence_2, AVStenosis_2_pattern)
          if (!is.na(AVStenosis_2_match [1, 2])) {
            AVStenosis_2 <- tolower(AVStenosis_2_match [1, 2])
            if (AVStenosis_1 == AVStenosis_2) {
              cat(sprintf("AV Stenosis: %s\n", AVStenosis_1))
              output_AVStenosis <- AVStenosis_1
            } else {
              cat("AV Stenosis: Error, non-matching findings\n")
              output_AVStenosis <- AVStenosis_1 
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
    cat("AV Stenosis: Error, no AV Stenosis doppler sentence found\n")
    output_AVStenosis <- ""
    output_AVStenosisError <- "AVStenosis: Error, no AVStenosis doppler sentence found"
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
    TR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
    TR_1_match <- str_match(TRsentence_1, TR_1_pattern)
    
    if (!is.na(TR_1_match [1, 2])) {
      TR_1 <- tolower(TR_1_match [1, 2])
      if (TR_1 == "no" | TR_1 == "trivial" | TR_1 == "mild" | TR_1 == "mild-moderate" | TR_1 == "mild - moderate" | TR_1 == "mild to moderate" | TR_1 == "not assessed" | TR_1 == "shadowing from the prosthesis") {
        output_TR <- TR_1
        cat(sprintf("TR: %s\n", TR_1))
      } else {
        if (!is.na(TRsentence_matches_2 [1, 2])) {
          TRsentence_2 <- TRsentence_matches_2 [1, 2]
          TR_2_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial)"
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
  
  #Tricuspid Valve Structure
  
  TVStructuresentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Tricuspid valve|tricuspid valve)(?:\\sstructure)?(?:\\sis|\\sappears|\\snot well seen)[^.]*).*CONCLUSIONS"
  TVStructuresentence_matches_1 <- str_match(document_text, TVStructuresentence_pattern_1)
  
  output_TVStructure <- ""
  output_TVStructureError <- ""
  
  if (!is.na(TVStructuresentence_matches_1 [1, 2])) {
    TVStructuresentence_1 <- TVStructuresentence_matches_1 [1, 2]
    cat(sprintf("TV Structure Sentence 1: %s\n", TVStructuresentence_1))
    TVStructure_1_pattern <- "(normal|Normal|mildly-moderately|Mildly-moderately|mildly to moderately|Mildly to moderately|mildly|Mildly|moderately|Moderately|moderately-severely|Moderately-severely|moderately to severely|Moderately to severely|moderately|Moderately|severely|Severely|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|bioprosthetic valve)"
    TVStructure_1_match <- str_match(TVStructuresentence_1, TVStructure_1_pattern)
    
    if (!is.na(TVStructure_1_match [1, 2])) {
      TVStructure_1 <- tolower(TVStructure_1_match [1, 2])
      output_TVStructure <- TVStructure_1
      cat(sprintf("TV Structure: %s\n", TVStructure_1))
    } else {
      TVStructure_2_pattern <- "(bicuspid)"
      TVStructure_2_match <- str_match(TVStructuresentence_1, TVStructure_2_pattern)
      if (!is.na(TVStructure_2_match [1, 2])){
        TVStructure_2 <- TVStructure_2_match [1, 2]
        output_TVStructure <- TVStructure_2
        cat(sprintf("TV Structure: %s\n", TVStructure_2))
      } else {
        cat("TV Structure: Error, no TV structure categorization found in doppler sentence\n")
        output_TVStructure <- ""
        output_TVStructureError <- "Error, no TV structure categorization found in doppler sentence"
      }
    }
  } else {
    TVStructuresentence_pattern_2 <- "Tricuspid Valve:.*?(Bioprosthetic valve|bioprosthetic valve).*?(?:Pulmonic valve|pulmonic valve)"
    TVStructuresentence_matches_2 <- str_match(document_text, TVStructuresentence_pattern_2)
    if (!is.na(TVStructuresentence_matches_2 [1, 2])) {
      TVStructure_match_2 <- TVStructuresentence_matches_2 [1, 2]
      cat(sprintf("TV Structure: %s\n", TVStructure_match_2))
      output_TVStructure <- TVStructure_match_2
    } else {
      cat("TV Structure: Error, no TV Structure doppler sentence found\n")
      output_TVStructure <- ""
      output_TVStructureError <- "Error, no TV Structure doppler sentence found"
    }
  }
  
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
    TVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
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
    PR_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis|could not be assessed)"
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
  
  #Pulmonic Valve Structure
  
  PVStructuresentence_pattern_1 <- "TWO-DIMENSIONAL STUDY AND DOPPLER EVALUATION.*?([^.]*(?:Pulmonic valve|pulmonic valve)(?:\\sstructure)?(?:\\sis|\\sappears|\\snot well seen)[^.]*).*CONCLUSIONS"
  PVStructuresentence_matches_1 <- str_match(document_text, PVStructuresentence_pattern_1)
  
  output_PVStructure <- ""
  output_PVStructureError <- ""
  
  if (!is.na(PVStructuresentence_matches_1 [1, 2])) {
    PVStructuresentence_1 <- PVStructuresentence_matches_1 [1, 2]
    cat(sprintf("PV Structure Sentence 1: %s\n", PVStructuresentence_1))
    PVStructure_1_pattern <- "(normal|Normal|mildly-moderately|Mildly-moderately|mildly to moderately|Mildly to moderately|mildly|Mildly|moderately|Moderately|moderately-severely|Moderately-severely|moderately to severely|Moderately to severely|moderately|Moderately|severely|Severely|no\\b|No\\b|not well seen|not visualized|not clearly visualized|not well visualized|bioprosthetic valve)"
    PVStructure_1_match <- str_match(PVStructuresentence_1, PVStructure_1_pattern)
    
    if (!is.na(PVStructure_1_match [1, 2])) {
      PVStructure_1 <- tolower(PVStructure_1_match [1, 2])
      output_PVStructure <-PVStructure_1
      cat(sprintf("PV Structure: %s\n", PVStructure_1))
    } else {
      PVStructure_2_pattern <- "(bicuspid|tricuspid|trileaflet)"
      PVStructure_2_match <- str_match(PVStructuresentence_1, PVStructure_2_pattern)
      if (!is.na(PVStructure_2_match [1, 2])){
        PVStructure_2 <- PVStructure_2_match [1, 2]
        output_PVStructure <- PVStructure_2
        cat(sprintf("PV Structure: %s\n", PVStructure_2))
      } else {
        cat("PV Structure: Error, no PV structure categorization found in doppler sentence\n")
        output_PVStructure <- ""
        output_PVStructureError <- "Error, no PV structure categorization found in doppler sentence"
      }
    }
  } else {
    PVStructuresentence_pattern_2 <- "Pulmonic Valve:.*?(Bioprosthetic valve|bioprosthetic valve).*?(?:Pulmonic valve|pulmonic valve)"
    PVStructuresentence_matches_2 <- str_match(document_text, PVStructuresentence_pattern_2)
    if (!is.na(PVStructuresentence_matches_2 [1, 2])) {
      PVStructure_match_2 <- PVStructuresentence_matches_2 [1, 2]
      cat(sprintf("PV Structure: %s\n", PVStructure_match_2))
      output_PVStructure <- PVStructure_match_2
    } else {
      cat("PV Structure: Error, no PV Structure doppler sentence found\n")
      output_PVStructure <- ""
      output_PVStructureError <- "Error, no PV Structure doppler sentence found"
    }
  } 
  
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
    PVStenosis_1_pattern <- "(mild-moderate|Mild-moderate|mild to moderate|Mild to moderate|mild|Mild|moderate|Moderate|moderate-severe|Moderate-severe|moderate to severe|Moderate to severe|moderate|Moderate|severe|Severe|no\\b|No\\b|trace|Trace|trivial|Trivial|not assessed|Shadowing from the prosthesis|shadowing from the prosthesis)"
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
        output_pasp <- "PASP estimate not found in the document"
      }
    }
  }
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
      `LV Hypertrophy` = output_LVHypertrophy,
      `LV Hypertrophy Error` = output_LVHypertrophyError,
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
      `Right Atrial Pressure` = output_RAP,
      `RV Function` = output_RVFunction,
      `RV Function Error` = output_RVFunctionError,
      `MV Regurgitation` = output_MR,
      `MV Regurgitation Error` = output_MRError,
      `MV Structure` = output_MVStructure,
      `MV Structure Error` = output_MVStructureError,
      `MV Stenosis` = output_MVStenosis,
      `MV Stenosis Error` = output_MVStenosisError,
      `AV Regurgitation` = output_AR,
      `AV Regurgitation Error` = output_ARError,
      `AV Structure` = output_AVStructure,
      `AV Structure Error` = output_AVStructureError,
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
      `TV Stenosis` = output_TVStenosis,
      `TV Stenosis Error` = output_TVStenosisError,
      `PV Regurgitation` = output_PR,
      `PV Regurgitation Error` = output_PRError,
      `PV Structure` = output_PVStructure,
      `PV Structure Error` = output_PVStructureError,
      `PV Stenosis` = output_PVStenosis,
      `PV Stenosis Error` = output_PVStenosisError,
      `TR Velocity` = output_TRvelocity,
      `PASP` = output_pasp
  
    )
    output_list <- c(output_list, list(output_df))
}

# Create a data frame from the output list
output_data <- do.call(rbind, output_list)

# Rename the columns to ensure uniqueness
colnames(output_data) <- make.unique(as.character(colnames(output_data)))

# Write the data frame to an Excel file
write.xlsx(output_data, '/Users/Nischal/TTE_DataExtraction/CSV_Echo Variables Output_R.xlsx', rowNames = FALSE)
