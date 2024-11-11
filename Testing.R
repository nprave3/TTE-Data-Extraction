library(readxl)
library(stringr)
library(tidyverse)
library(openxlsx)

# Specify the file path
excel_file_path <- '/Users/Nischal/TTE_DataExtraction/Sample.xlsx'

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
    `LA Size` = output_LAsize,
    `LA Size Error` = output_LAsizeError,
    `PASP` = output_pasp
    
  )
  output_list <- c(output_list, list(output_df))
}

# Create a data frame from the output list
output_data <- do.call(rbind, output_list)

# Rename the columns to ensure uniqueness
colnames(output_data) <- make.unique(as.character(colnames(output_data)))

# Write the data frame to an Excel file
write.xlsx(output_data, '/Users/Nischal/TTE_DataExtraction/Test', rowNames = FALSE)
