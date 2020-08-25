library(readr)
library(dplyr)

# VALUES

explanation_types <- c("Model parts", "Model profile", "Model diagnostics", "Predict parts", "Predict profile", "Predict diagnostics", "Generate")

dir <- "./use-case/"

# FUNCTIONS

get_setup <- function(rmd_file){
  header_rows <- apply(rmd_file, 2, FUN = function(x)grep("^# ", x, ignore.case = TRUE))
  
  ith_row <- 1
  code_to_eval <- ""
  
  while(ith_row <= header_rows[1]){
    row_code = rmd_file[ith_row, 1]
    if (grepl("```{r}", row_code, fixed = TRUE) | grepl("```{r, eval = FALSE}", row_code, fixed = TRUE)){
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
      while((!grepl("```", row_code, fixed = TRUE)) & (ith_row <= header_rows[1])){
        code_to_eval <- paste(code_to_eval, "\n", row_code)
        ith_row <- ith_row + 1
        row_code = rmd_file[ith_row, 1]
      }
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
      
    } else {
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
    }
  }
  return(code_to_eval)  
}



get_chunks <- function(rmd_file, type = "Model parts", pkg_name = ""){
  # find rows with headers
  header_rows <- apply(rmd_file, 2, FUN = function(x)grep("^# ", x, ignore.case = TRUE))
  # find header of interest
  type_row <- apply(rmd_file, 2, FUN = function(x)grep(paste("#", type), x, ignore.case = TRUE))
  if(length(type_row) == 0) return(data.frame(pkg_name = character(), type = character(), code_to_eval = character(), pkg_setup = character()))
  # find end of row of interest
  next_row <- header_rows[which(header_rows == type_row) + 1]
  if (is.na(next_row)) next_row <-nrow(rmd_file)
  
  pkg_setup <- get_setup(rmd_file)
  
  ith_row <- type_row
  type_codes <- data.frame(pkg_name = character(), type = character(), code_to_eval = character(), pkg_setup = character())
  
  while(ith_row <= next_row){
    row_code = rmd_file[ith_row, 1]
    if (grepl("```{r}", row_code, fixed = TRUE)){
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
      code_to_eval <- ""
      
      while((!grepl("```", row_code, fixed = TRUE)) & (ith_row <= next_row)){
        code_to_eval <- paste(code_to_eval, "\n", row_code)
        ith_row <- ith_row + 1
        row_code = rmd_file[ith_row, 1]
      }
      type_codes <- rbind(type_codes, data.frame(pkg_name, type, code_to_eval, pkg_setup))
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
      
    } else {
      ith_row <- ith_row + 1
      row_code = rmd_file[ith_row, 1]
    }
    
  }
  return(type_codes)
}


get_package_codes <- function(file_dir){
  
  package_name <- gsub('.*/', "", gsub(".Rmd", "", file_dir))
  rmd_file <- read_csv2(file_dir)
  
  pkg_results <- lapply(explanation_types, function(x){
    get_chunks(rmd_file, type = x, pkg_name = package_name)  
  } ) %>%
    bind_rows()
}

get_all_packages_codes <- function(dir){
  files <- list.files(dir)
  files <- files[grep(".Rmd", files)]

  lapply(paste0(dir, files), function(x) {
    get_package_codes(x)
    }) %>%
    bind_rows()
  
}

# EXTRACT CHUNKS

packages_chunks <- get_all_packages_codes(dir)

save(packages_chunks, file = "./benchmark/packages_chunks.rda")
