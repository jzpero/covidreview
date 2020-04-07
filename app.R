library(shiny)
library (DT)
library(tidyverse)
library(httr)
library(shinyWidgets)

#Get most recent data file from repo
# req <- GET("https://api.github.com/repos/jzpero/covid19lit/git/trees/master?recursive=1")
# stop_for_status(req)
# filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = F)
# link <- sprintf("https://raw.githubusercontent.com/jzpero/covid19lit/master/%s",grep("data/current", filelist, value = TRUE, fixed = TRUE))

source("ui.R")
source("server.R")

# Run the application 
shinyApp(ui = ui, server = server)

