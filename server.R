server <- function(input, output, session) {
  #Update the data once
  link <- "data/current_2020-04-06-19-34-50.csv"
  
  #Data Processing (done once)
  rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE)
  headers <- colnames(rawtable)
  filtered.table <<- rawtable[!duplicated(rawtable$PMID),]
  N <<- nrow(filtered.table)
  
  #Create dropdown choices
  unique.authors <- lapply(strsplit(paste(filtered.table$Author, collapse=','), ","), trimws)[[1]]
  unique.authors <<- sort(unique(unique.authors[lapply(unique.authors, nchar) > 0]))
  unique.journals <- sort(unique(filtered.table$Journal))
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
  
  #Create a PubMed link in HTML
  createLink <- function(PMID, text) {
    sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s" target="_blank">%s</a>', PMID, text)
  }
  
  #Populate the search filters
  updateSelectInput(session, "journal", choices = c("Select a journal" = "", unique.journals))
  updateSelectInput(session, "author", choices = c("Select authors" = "", unique.authors))
  updateSelectInput(session, "study", choices = c("Select a type" = "", unique.studytypes))
  updateSelectInput(session, "specialty", choices = c("Select an area of interest" = "", unique.specialties))
  
  #Initiate table
  display.table <- filtered.table
  
  #clear all button actions
  observeEvent(input$clearAll, {
    shinyjs::reset("searchpanel")
  })

  # output$graph <- renderPlot({
  #   plot(date_range, date_counts)
  # })
  
  #Main Data Output
  output$ex1 <- DT::renderDataTable({

    #Filter Journal
    if (!is.null(input$journal)) {
      display.table <- display.table[display.table$Journal %in% input$journal,]
    }
    
    #Filter Study
    if (!is.null(input$study)) {
      display.table <- display.table[display.table$'Type of Study' %in% input$study,]
    }
    
    #Filter Authors
    if (!is.null(input$author) & nrow(display.table) > 0) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      #iterate over author rows and flag as TRUE if any of the selected authors present
      for (i in 1:length(v)) {
        for (query in input$author) {
          if (grepl(query, display.table$Author[i]))v[i] <- TRUE; break
        }
      }
      display.table <- display.table[v,]
    }
    
    #Filter Specialty (any)
    if (!is.null(input$specialty) & nrow(display.table)) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      if (input$specSwitch){
      #iterate over author rows and flag as TRUE if ANY of the selected authors present
        for (i in 1:nrow(display.table)) {
          for (query in input$specialty) {
            if (query %in% display.table$Areas[[i]]) v[i] <- TRUE; break
          }
        }
      } else { #iterate over author rows and flag as TRUE if ALL of the selected authors present
        for (i in 1:nrow(display.table)) {
          if (all(sapply(input$specialty, function(x) x %in% display.table$Areas[[i]]))) v[i] <- TRUE
        }
      }
      display.table <- display.table[v,]
    }
    
    #Create Links
    display.table$Title <- createLink(display.table$PMID, display.table$Title)
    
    #Output
    included.headers <- c("Title", "Author", "Journal","Date",  "PMID", "Type of Study", "Areas")
    DT::datatable(display.table[,included.headers], options = list(pageLength = 25), rownames= FALSE, escape=FALSE)
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