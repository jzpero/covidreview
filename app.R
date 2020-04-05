library(shiny)
library (DT)
library(tidyverse)

ui <- navbarPage(
    title = 'COVID-19 Literature',
    position = c("fixed-top"),
    tabPanel('All',     DT::dataTableOutput('ex1'),  tags$style(type="text/css", "body {padding-top: 70px;}")),
    tabPanel('Case Reports',        DT::dataTableOutput('ex2')),
    tabPanel('Systematic Reviews',        DT::dataTableOutput('ex3')),
    tabPanel('Meta-analyses',        DT::dataTableOutput('ex4'))
)

#process the DistillerSR output CSV
dtable <- read.csv("~/data/2020-04-05-21-21-18.csv", stringsAsFactors=FALSE)
headers <- colnames(dtable)
# View(dtable)
included.headers <- c("Title", "Author", "Journal","Date",  "PMID", "Type.of.Study")
filtered.table <- dtable[!duplicated(dtable$PMID),included.headers]

included <- function(input, output) {
    #All
    output$ex1 <- DT::renderDataTable(
        DT::datatable(filtered.table, options = list(pageLength = 25), rownames= FALSE)
    )
    #Case Reports
    output$ex2 <- DT::renderDataTable(
        DT::datatable(filtered.table[grepl("Case", filtered.table$Type.of.Study),], options = list(pageLength = 25), rownames= FALSE)
    )
    #Systematic
    output$ex3 <- DT::renderDataTable(
        DT::datatable(filtered.table[grepl("Systematic", filtered.table$Type.of.Study),], options = list(pageLength = 25), rownames= FALSE)
    )
    #Meta-analysis
    output$ex4 <- DT::renderDataTable(
        DT::datatable(filtered.table[grepl("Meta", filtered.table$Type.of.Study),], options = list(pageLength = 25), rownames= FALSE)
    )
}

# Run the application 
shinyApp(ui = ui, server = included)
