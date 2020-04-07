library(shiny)
library (DT)
library(tidyverse)
library(httr)
library(dplyr)

getData <- function(x) {
    #Get most recent data file from repo
    # req <- GET("https://api.github.com/repos/jzpero/covid19lit/git/trees/master?recursive=1")
    # stop_for_status(req)
    # filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = F)
    # link <- sprintf("https://raw.githubusercontent.com/jzpero/covid19lit/master/%s",grep("data/current", filelist, value = TRUE, fixed = TRUE))
    
    link <- "data/current_2020-04-06-19-34-50.csv"
    
    #Data Processing (done once)
    rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE)
    headers <- colnames(rawtable)
    filtered.table <<- rawtable[!duplicated(rawtable$PMID),]
    N <<- nrow(filtered.table)
    
    unique.authors <<- lapply(strsplit(paste(filtered.table$Author, collapse=','), ","), trimws)[[1]]
    unique.authors <<- sort(unique(unique.authors[lapply(unique.authors, nchar) > 0]))
    unique.journals <<- sort(unique(filtered.table$Journal))
    unique.studytypes <<- sort(unique(filtered.table$'Type of Study'))
    unique.specialties <<- sort(c("Internal Medicine", "General", "Dermatology", "ICU", "Emergency Medicine", "Anesthesia", "Radiology", "Peds", "OBGYN", "Public Health", "Cardiology", "Oncology", "Psych"))

    spec.out <- vector("list", length=N)
    spec.cols <- grep("Spec", headers)
    for (i in 1:N) {
        k <- unlist(filtered.table[i,spec.cols], use.names = F)
        k <- sort(k[!is.na(k)])
        k <- k[!grepl("Other", k)]
        spec.out[[i]] <- k
    }
    filtered.table$"Areas" <<- spec.out
}

getData()

createLink <- function(PMID, text) {
    sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s">%s</a>', PMID, text)
}

source("ui.R")
source("server.R")

# Run the application 
shinyApp(ui = ui, server = server)

