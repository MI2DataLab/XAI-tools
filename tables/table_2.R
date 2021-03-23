library(rvest)
library(dplyr)
library(xtable)
library(rjson)
library(knitr)
library(kableExtra)


library(deepdep)

r_packages <- c()
r_packages["ALEPlot"] <- NA
r_packages["auditor"] <- "ModelOriented/auditor"
r_packages["DALEX"] <- "ModelOriented/DALEX"
r_packages["DALEXtra"] <- "ModelOriented/DALEXtra"
r_packages["EIX"] <- "ModelOriented/EIX"
r_packages["ExplainPrediction"] <- NA
r_packages["fairness"] <- "kozodoi/fairness"
r_packages["fastshap"] <- "bgreenwell/fastshap"
r_packages["flashlight"] <- "mayer79/flashlight"
r_packages["forestmodel"] <- "NikNakk/forestmodel"
r_packages["fscaret"] <- NA
r_packages["iBreakDown"] <- "ModelOriented/iBreakDown"
r_packages["ICEbox"] <- "kapelner/ICEbox"
r_packages["iml"] <- "christophM/iml"
r_packages["ingredients"] <- "ModelOriented/ingredients"
r_packages["lime"] <- "thomasp85/lime"
r_packages["live"] <- "ModelOriented/live"
r_packages["mcr"] <- NA
r_packages["modelDown"] <- "ModelOriented/modelDown"
r_packages["modelStudio"] <- "ModelOriented/modelStudio"
r_packages["pdp"] <- "bgreenwell/pdp"
r_packages["randomForestExplainer"] <- "ModelOriented/randomForestExplainer"
r_packages["shapper"] <- "ModelOriented/shapper"
r_packages["smbinning"] <- NA
r_packages["survxai"] <- "MI2DataLab/survxai"
r_packages["vip"] <- "koalaverse/vip"
r_packages["vivo"] <- "ModelOriented/vivo"





###############################



get_first_release <- function(package){
  cran_archive_url <- paste0("https://cran.r-project.org/src/contrib/Archive/", package)
  cran_archive_html <- read_html(cran_archive_url) 
  body_nodes <- cran_archive_html %>% 
    html_node("body") %>% 
    html_children()
  archive_df <- html_table(body_nodes[[2]])
  first_release <- sub(" .*", "", archive_df[3, "Last modified"])
  first_release
}


get_pkg_license <- function(package, pkg_df){
  pkg_license <- pkg_df[which(pkg_df[,1] == "License:"), 2]
  pkg_license_clean <- gsub("\\s*\\[[^\\]+\\]", "", pkg_license)
  pkg_license_clean <- gsub(" \\| ", "/", pkg_license_clean)
  pkg_license_clean <- gsub("file LICENSE", "addons", pkg_license_clean)
  pkg_license_clean
}

get_pkg_version <- function(package, pkg_df){
  pkg_version <- pkg_df[which(pkg_df[,1] == "Version:"), 2]
  pkg_version_clean <- gsub("\\s*\\[[^\\]+\\]", "", pkg_version)
  pkg_version_clean <- gsub(" \\| ", "/", pkg_version_clean)
  pkg_version_clean <- gsub("file LICENSE", "addons", pkg_version_clean)
  pkg_version_clean
}

get_github_stars <- function(repo){
  if (!is.na(repo)){
    github_url <- paste0("https://api.github.com/repos/", repo)
    data = fromJSON(file=github_url)
    github_stars <- data[["stargazers_count"]]
  } else {
    github_stars <- "-"
  }
  github_stars
}



table_2_r <- lapply(names(r_packages), function(package){
  print(package)
  cran_url <- paste0("https://CRAN.R-project.org/package=", package)
  cran_html <- read_html(cran_url)
  
  body_nodes <- cran_html %>% 
    html_node("body") %>% 
    html_children()
  pkg_df <- html_table(body_nodes[[3]])
  pkg_license <- get_pkg_license(package, pkg_df)
  pkg_last_update <- pkg_df[which(pkg_df[,1] == "Published:"), 2]
  pkg_downloads <- get_downloads(package)[6]
  github_stars <- get_github_stars(r_packages[package])
  first_release <- get_first_release(package)
  pkg_version <- get_pkg_version(package, pkg_df)
  
  c(package, pkg_license, pkg_last_update, pkg_version, github_stars, pkg_downloads, first_release)  %>% 
    matrix(nrow = 1)
}) %>%
  do.call(rbind, .) %>% 
  data.frame()  %>%
  setNames(c("Package", "License", "Date of\\last update",  "Last Version","GitHub\\stars", "CRAN\\downloads", "Date of\\first release"))




pip_last_update <- function(package){
  pip_url <- paste0("https://pypi.org/project/", package)
  pip_html <- read_html(pip_url)
  pip_body_nodes <- pip_html %>% 
    html_nodes(xpath = '//*[@id="content"]/div[1]/div/div[2]/p') 
  pip_release <- pip_body_nodes %>%
    html_nodes("time")%>%
    html_attr("datetime")
  sub("T.*", "", pip_release)
}

pip_first_release <- function(package){
  print(paste("Release", package))
  Sys.sleep(runif(1))
  pip_url <- paste0("https://pypi.org/project/", package,"/#history")
  pip_html <- read_html(pip_url)
  pip_body_nodes <- pip_html %>% 
    html_nodes(xpath = '//*[@id="history"]/div/div') 
  pip_release <- pip_body_nodes[[length(pip_body_nodes)]] %>%
    html_nodes('time')%>%
    html_attr("datetime")
  sub("T.*", "", pip_release)
}

pip_last_version <- function(package){
  print(paste("Last version", package))
  pip_url <- paste0("https://pypi.org/project/", package)
  pip_html <- read_html(pip_url)
  pip_body_nodes <- pip_html %>% 
    html_nodes(xpath = '//*[@id="content"]/div[1]/div/div[1]/h1') 
  pip_release <- pip_body_nodes %>%
   html_text()
  sub(".*\\s", "", trimws(pip_release))
}

table_2_python <- list(
  c("aix360",    "Apache 2.0", pip_last_update("aix360"), pip_last_version("aix360"), get_github_stars("Trusted-AI/AIX360"), "-", pip_first_release("aix360")),
  c("eli5",      "MIT", pip_last_update("eli5"), pip_last_version("eli5"), get_github_stars("TeamHG-Memex/eli5"), "-", pip_first_release("eli5")),
  c("interpret", "MIT", pip_last_update("interpret"), pip_last_version("interpret"), get_github_stars("interpretml/interpret"), "-", pip_first_release("interpret")),
  c("lime",      "BSD", pip_last_update("lime"), pip_last_version("lime"), get_github_stars("marcotcr/lime"), "-", pip_first_release("lime")),
  c("shap",      "MIT", pip_last_update("shap"), pip_last_version("shap"), get_github_stars("slundberg/shap"), "-", pip_first_release("shap")),
  c("skater",    "MIT", pip_last_update("skater"), pip_last_version("skater"),get_github_stars("oracle/Skater"), "-", pip_first_release("skater"))
) %>%
  do.call(rbind, .) %>% 
  data.frame()  %>%
  setNames(c("Package", "License", "Date of\\last update","Last Version", "GitHub\\stars", "CRAN\\downloads", "Date of\\first release"))



table_2_r[["RowFactor1"]] <- "\\centering\\arraybackslash \\rot{\\rlap{R}}"
table_2_python[["RowFactor1"]] <- "\\centering\\arraybackslash \\rot{\\rlap{Python}}"

table_2 <- rbind(table_2_r, table_2_python)
table_2 <- table_2[,c(8,1:7)]
colnames(table_2) <- c("", "Package", "License", 
                       "\\begin{tabular}[c]{@{}c@{}}Date of \\\\last update \\end{tabular}", 
                       "\\begin{tabular}[c]{@{}c@{}}Last \\\\version \\end{tabular}", 
                       "\\begin{tabular}[c]{@{}c@{}}GitHub \\\\stars\\end{tabular} ", 
                       "\\begin{tabular}[c]{@{}c@{}}CRAN \\\\downloads\\end{tabular}" , 
                       "\\begin{tabular}[c]{@{}c@{}}Date of \\\\first release \\end{tabular}")

kable(table_2, format = "latex", escape = FALSE,
      align = c("c","l","c","c", "c","r","r","c")) %>% 
  collapse_rows(columns = 1)




