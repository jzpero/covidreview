library(dplyr)

#Case formatting from https://stat.ethz.ch/R-manual/R-devel/library/base/html/chartr.html
capwords <- function(s, strict = FALSE) {
  cap <- function(s) paste(toupper(substring(s, 1, 1)),
                           {s <- substring(s, 2); if(strict) tolower(s) else s},
                           sep = "", collapse = " " )
  sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
}

#Create a PubMed link in HTML
createLink <- function(PMID, text) {
  sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s" target="_blank">%s</a>', PMID, text)
}

included.headers <- c("TitleLinks", "Author", "Journal","Date",  "PMID", "Type of Study", "Specialties")

server <- function(input, output, session) { # Executes once per session (no need to restart service)
  #Update the data once
  link <- list.files("data/", pattern="(current)", full.names=TRUE)[1]
  
  #Data Processing (done once)
  rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE)
  date_data <- read.csv("data/date_output.csv", header=T, colClasses = c("character", "character"))
  headers <- colnames(rawtable)
  filtered.table <<- rawtable[!duplicated(rawtable$PMID),]
  filtered.table$Journal <- capwords(filtered.table$Journal)
  N <<- nrow(filtered.table)

  # Date Mapping to PubMed Data
  for (i in 1:N) {
    if (filtered.table$PMID[i] %in% date_data$pmid) {
      replacement <- (date_data %>% filter(pmid == filtered.table$PMID[i]))$date
      if (!is.na(replacement)) filtered.table$Date[i] <- replacement
    }
  }
  filtered.table$Date <- anytime::anydate(filtered.table$Date)

  #Create filter choices
  unique.authors <- lapply(strsplit(paste(filtered.table$Author, collapse=','), ","), trimws)[[1]]
  unique.authors <<- sort(unique(unique.authors[lapply(unique.authors, nchar) > 0]))
  unique.journals <- sort(unique(filtered.table$Journal))
  unique.studytypes <<- sort(unique(filtered.table$'Type of Study'))
  unique.specialties <<- sort(c("Internal Medicine", "General", "Dermatology", "ICU", "Emergency Medicine", "Anesthesia", "Radiology", "OBGYN", "Public Health", "Cardiology", "Oncology", "Psych", "Family Medicine", "Gastroenterology", "Geriatrics", "Hematology", "Infectious Disease", "Immunology", "Medical Education", "Microbiology", "Nephrology", "Neurology", "Ophthalmology", "Palliative Care", "Pathology", "Pediatrics","Respirology", "Rheumatology", "Surgery", "Urology"))
  
  # Special processing of specialty data
  spec.out <- vector("list", length=N)
  spec.cols <- grep("Spec", headers)
  for (i in 1:N) {
    k <- unlist(filtered.table[i,spec.cols], use.names = F)
    k <- sort(k[!is.na(k)])
    spec.out[[i]] <- k
  }
  filtered.table$Areas <- spec.out
  filtered.table$Specialties <- sapply(filtered.table$Areas, function(x) paste(unlist(x), collapse=", "))
  
  #Populate the search filters
  updateSelectInput(session, "journal", choices = c("Select a journal" = "", unique.journals))
  updateSelectInput(session, "author", choices = c("Select authors" = "", unique.authors))
  updateSelectInput(session, "study", choices = c("Select a type" = "", unique.studytypes))
  updateSelectInput(session, "specialty", choices = c("Select an area of interest" = "", unique.specialties))
  
  #Initiate display table
  display.table <- filtered.table
  
  #clear all button actions
  observeEvent(input$clearAll, {
    shinyjs::reset("searchpanel")
  })
  
  #pie chart
  # output$pie <- renderCachedPlot(pie(sort(table(display.table$`Type of Study`))), cacheKeyExpr="session")
  # date_data <- data.frame(table(filtered.table$Date))
  # lo <- loess(date_data$Freq~as.numeric(date_data$Var1))
  # output$bar <- renderCachedPlot({
  #   plot(table(filtered.table$Date), type = "h", lwd = 5, ylab = "Count")
  #   lines(predict(lo), col='red', lwd=2)
  # }, cacheKeyExpr = "barsession")

  #Main Data Output
  output$ex1 <- DT::renderDataTable(server=FALSE, {
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
      if (input$specSwitch == "Any term"){
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
    
    #Caption rendering
    output$ref_caption <- renderUI(
      if (!is.null(input$ex1_rows_selected)) {
        HTML(paste0(
          trimws(display.table[input$ex1_rows_selected,"Author"]), ". ",
          "<b>",display.table[input$ex1_rows_selected,"TitleLinks"], "</b> ",
          "<i>", trimws(display.table[input$ex1_rows_selected,"Journal"]), "</i>. <br><br>", if (is.na(display.table[input$ex1_rows_selected, "Abstract"])) "No abstract." else display.table[input$ex1_rows_selected, "Abstract"]
        ))} else HTML("<i>Select a reference...</i>")
    )
    
    output$N <- renderText(nrow(display.table))
    
    #Create Links
    display.table$TitleLinks <- createLink(display.table$PMID, display.table$Title)
    
    #Export option
    output$export <- downloadHandler(
      filename = function() {
        paste("references",Sys.Date(),".csv", sep = "")
      },
      content = function(file) {
        write.csv(display.table[,gsub("TitleLinks", "Title", included.headers)], file, row.names = FALSE)
      }
    )
    
    # PDF Rmd Report
    # output$report <- downloadHandler(
    #   filename = "report.pdf",
    #   content = function(file) {
    #     # Copy the report file to a temporary directory before processing it, in
    #     # case we don't have write permissions to the current working dir (which
    #     # can happen when deployed).
    #     tempReport <- file.path(tempdir(), "report.Rmd")
    #     file.copy("markdown/report.Rmd", tempReport, overwrite = TRUE)
    #     
    #     # Set up parameters to pass to Rmd document
    #     params <- list(dtable=display.table[,included.headers])
    #     
    #     # Knit the document, passing in the `params` list, and eval it in a
    #     # child of the global environment (this isolates the code in the document
    #     # from the code in this app).
    #     rmarkdown::render(tempReport, output_file = file,
    #                       params = params,
    #                       envir = new.env(parent = globalenv())
    #     )
    #   }
    # )
    
    #Output
    DT::datatable(
      display.table[,included.headers],
      extensions = "Responsive",
      options = list(pageLength = 10, order = list(list(3, "desc"), list(4, "desc"))),
      rownames= FALSE, escape=FALSE, selection = 'single')
  })
}
