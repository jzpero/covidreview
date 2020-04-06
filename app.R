library(shiny)
library (DT)
library(tidyverse)
library(readr)
library(httr)

getData <- function(x) {
    #Get most recent data file from repo
    req <- GET("https://api.github.com/repos/jzpero/covid19lit/git/trees/master?recursive=1")
    stop_for_status(req)
    filelist <- unlist(lapply(content(req)$tree, "[", "path"), use.names = F)
    link <- grep("data/current", filelist, value = TRUE, fixed = TRUE)

    #Data Processing (done once)
    rawtable <- read_csv(sprintf("https://raw.githubusercontent.com/jzpero/covid19lit/master/"),link)
    headers <- colnames(rawtable)
    included.headers <- c("Title", "Author", "Journal","Date",  "PMID", "Type of Study")
    filtered.table <<- rawtable[!duplicated(rawtable$PMID),included.headers]
    unique.authors <<- lapply(strsplit(paste(filtered.table$Author, collapse=','), ","), trimws)[[1]]
    unique.authors <<- sort(unique(unique.authors[lapply(unique.authors, nchar) > 0]))
    unique.journals <<- sort(unique(filtered.table$Journal))
    unique.studytypes <<- sort(unique(filtered.table$`Type of Study`))
    
    # spec.table <- rawtable[,headers[grepl("Spec", headers)]]
    # spec.col <- sapply(1:nrow(spec.table), function(x) {
    #     a <- as.character(spec.table[x,])
    #     a <- a[!is.na(a)]
    # })
}

getData()

createLink <- function(PMID, text) {
    sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s">%s</a>', PMID, text)
}

ui <- navbarPage(
    title = 'COVID-19 Literature',
    position = c("fixed-top"),
    tabPanel('Browse',
         tags$style(type="text/css","body {padding-top: 70px;}"),
         shinyjs::useShinyjs(),
         id="tab-panel",
         sidebarLayout(
             position = "right",
             sidebarPanel(
                 # radioButtons(inputId = "searchtype", "Search behaviour", choices = c("Match ALL criteria (AND)", "Match AT LEAST ONE criteria (OR)")),
                 selectInput(inputId = "journal", "Journal", choices = NULL, multiple = TRUE),
                 selectInput(inputId = "study", "Type of Study", choices = NULL, multiple = TRUE),
                 selectInput(inputId = "author", "Author(s)",choices = NULL, multiple = TRUE),
                 actionButton(inputId = "clearAll", "Clear All"),
                 downloadButton(outputId = "export", label = "Download all"),
                 downloadButton(outputId = "exportselected", label = "Download selected"),
                 width=3
             ),
             mainPanel(
                 "Last updated: April 6, 2020. Contains 246 references screened from 1890 results.",
                 DT::dataTableOutput('ex1'),
                 width=9
             )
         )
    ),
    tabPanel('About',
         tags$style(type="text/css","body {padding-top: 70px;}"),
         fluidPage(
             h1("What is this?"),
             "Recent literature on COVID-19 is highly variable in scope, quality, and applicability to the front-line physician.",
             "In a time where information and time are valuable resources, there must be a resource that provides curated primary and secondary literature so that clinical decisions can be made with more confidence.",
             "This project provides a way to browse current and relevant literature on COVID-19 that has been curated via a systematic review approach.",
             h1("Contributors"),
             "This page was coded and designed by Jasper Ho in R using Shiny.", br(),
             "Citations and data were reviewed and curated by Becky Jones, Daniel Levin, Hannah Kearney, Jasper Ho, and Meghan Glibbery, all medical students at McMaster University.", br(),
             "Project was conceptualized and managed by Dr. Mark Crowther."
         )
    ),
    collapsible = TRUE
)

server <- function(input, output, session) {
    #Update the data once
    getData()
    
    #Populate the search filters
    updateSelectInput(session, "journal", choices = c("Select a journal" = "", unique.journals))
    updateSelectInput(session, "author", choices = c("Select authors" = "", unique.authors))
    updateSelectInput(session, "study", choices = c("Select a type" = "", unique.studytypes))
    
    #Initiate table
    display.table <- filtered.table
    
    #clear all button actions
    observeEvent(input$clearAll, {
        reset("journal")
        reset("study")
        reset("author")
    })

    #Main Data Output
    output$ex1 <- DT::renderDataTable({
        #Filter Journal
        if (!is.null(input$journal)) {
            display.table <- display.table[display.table$Journal %in% input$journal,]
        }
        
        #Filter Study
        if (!is.null(input$study)) {
            display.table <- display.table[display.table$`Type of Study` %in% input$study,]
        }
        
        #Filter Authors
        if (!is.null(input$author)) {
            #Initialize FALSE Vector
            v <- vector("logical",length(display.table$Author))
            #iterate over author rows and flag as TRUE if any of the selected authors present
            for (i in 1:length(v)) {
                for (query in input$author) {
                    if (grepl(query, display.table$Author[i]))v[i] <- TRUE; break
                }
            }
            display.table <- display.table[v,]
        }
        
        #Create Links
        display.table$Title <- createLink(display.table$PMID, display.table$Title)
        
        #Output
        DT::datatable(display.table, options = list(pageLength = 25), rownames= FALSE, escape=FALSE)
    })
    
    #Export option
    output$export <- downloadHandler(
        filename = function() {
            paste("references",Sys.Date(),".csv", sep = "")
        },
        content = function(file) {
            write.csv(display.table, file, row.names = FALSE)
        }
    )
    
    output$exportselected <- downloadHandler(
        filename = function() {
            paste("references",Sys.Date(),".csv", sep = "")
        },
        content = function(file) {
            write.csv(display.table[input$ex1_rows_selected,], file, row.names = FALSE)
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)

