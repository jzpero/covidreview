# Executes once per service start
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

included.headers <- c("Title - Linked", "Author", "Journal","Date",  "PMID", "Type of Study", "Specialty")

# Update the data once
link <- list.files("data/", pattern="(current)", full.names=TRUE)[1]

# Data Processing (done once)
rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE, colClasses = "character")
rawtable <- rawtable[,-54]
date_data <- read.csv("data/date_output.csv", header=T, colClasses = c("character", "character"))
headers <- colnames(rawtable)

# Deduplicate entries, merging the specialties
filtered.table <- data.frame(AuthorList=c(), Journal=c(), 'Type of Study'=c(),  Title=c(), Date=c(), PMID=c(), specialty_raw=c(), Abstract=c(),stringsAsFactors = FALSE, check.names = FALSE)

unique_refs <- unique(rawtable$Refid)
for (i in 1:length(unique_refs)) {
  group <- (rawtable %>% filter(Refid == unique_refs[i])) # separate out the reviews of the same reference
  group_spec <- group %>% select(starts_with("Spec"))
  vec <- c()
  
  for (j in 1:nrow(group)) { #iterate through the reviews of the reference and create a list of specialty values
    vec <- c(vec, group_spec[j,])
  }
  
  specialties <- unique(as.vector(unlist(vec))) # get unique entries as vector
  specialties <- specialties[!is.na(specialties)]
  
  authors <- lapply(strsplit(as.character(group$Author[1]), ","),trimws)
  
  d <- group$Date[1]
  if (group$PMID[1] %in% date_data$pmid) {
    replacement <- (date_data %>% filter(pmid == group$PMID[1]))$date
    if (!is.na(replacement)) d <- replacement
  }
  
  # Fill filtered.table with useful data
  temp <- data.frame(AuthorList=I(authors), Journal=capwords(group$Journal[1]), 'Type of Study'=group$`Type of Study`[1], Title=group$Title[1], Date=d, PMID=group$PMID[1], specialty_raw=I(list(specialties)), Abstract=group$Abstract[1],stringsAsFactors = FALSE,check.names = FALSE)
  filtered.table <- rbind(filtered.table, temp)
}

N <<- nrow(filtered.table)

#Create filter choices
unique.authors <- sort(unique(unlist(filtered.table$AuthorList)))
unique.authors <<- unique.authors[lapply(unique.authors, nchar) > 0]
unique.journals <- sort(unique(filtered.table$Journal))
unique.studytypes <<- sort(unique(filtered.table$'Type of Study'))
unique.specialties <<- sort(c("Internal Medicine", "General", "Dermatology", "ICU", "Emergency Medicine", "Anesthesia", "Radiology", "OBGYN", "Public Health", "Cardiology", "Oncology", "Psych", "Family Medicine", "Gastroenterology", "Geriatrics", "Hematology", "Infectious Disease", "Immunology", "Medical Education", "Microbiology", "Nephrology", "Neurology", "Ophthalmology", "Palliative Care", "Pathology", "Pediatrics","Respirology", "Rheumatology", "Surgery", "Urology"))

# Aesthestics for Shiny
filtered.table$Specialty <- lapply(filtered.table$specialty_raw, function(x) paste(x, collapse = ", "))
filtered.table$Author <- lapply(filtered.table$AuthorList, function(x) paste(x, collapse = ", "))

#############################################

server <- function(input, output, session) { # Executes once per session (no need to restart service)
  #Populate the search filters
  updateSelectInput(session, "journal", choices = c("Select a journal" = "", unique.journals))
  updateSelectInput(session, "author", choices = c("Select authors" = "", unique.authors))
  updateSelectInput(session, "study", choices = c("Select a publication type" = "", unique.studytypes))
  updateSelectInput(session, "specialty", choices = c("Select an area of interest" = "", unique.specialties))
  
  # Get a local copy of the dataset
  display.table <- filtered.table
  
  #clear all button actions
  observeEvent(input$clearAll, {
    shinyjs::reset("searchpanel")
  })

  #Main Data Output
  output$ex1 <- DT::renderDataTable(server=FALSE, {
    #Filter Journal
    if (!is.null(input$journal)) {
      display.table <- display.table[display.table$Journal %in% input$journal,]
    }

    #Filter Study
    if (!is.null(input$study)) {
      display.table <- display.table[display.table$"Type of Study" %in% input$study,]
    }

    #Filter Authors
    if (!is.null(input$author) & nrow(display.table) > 0) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      #iterate over author rows and flag as TRUE if any of the selected authors present
      for (i in 1:length(v)) {
        for (query in input$author) {
          if (query %in% display.table$AuthorList[[i]]) v[i] <- TRUE; break
        }
      }
      display.table <- display.table[v,]
    }

    # Filter Specialty (any)
    if (!is.null(input$specialty) & nrow(display.table)) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      if (input$specSwitch == "Any term"){
      #iterate over author rows and flag as TRUE if ANY of the selected authors present
        for (i in 1:nrow(display.table)) {
          for (query in input$specialty) {
            if (query %in% display.table$specialty_raw[[i]]) v[i] <- TRUE; break
          }
        }
      } else { #iterate over author rows and flag as TRUE if ALL of the selected authors present
        for (i in 1:nrow(display.table)) {
          if (all(sapply(input$specialty, function(x) x %in% display.table$specialty_raw[[i]]))) v[i] <- TRUE
        }
      }
      display.table <- display.table[v,]
    }

    #Caption rendering
    output$ref_caption <- renderUI(
      if (!is.null(input$ex1_rows_selected)) {
        HTML(paste0(
          paste(display.table$AuthorList[[input$ex1_rows_selected]],collapse=", "), ". ",
          "<b>",display.table[input$ex1_rows_selected,"Title - Linked"], "</b> ",
          "<i>", trimws(display.table[input$ex1_rows_selected,"Journal"]), "</i>. <br><br>", if (is.na(display.table[input$ex1_rows_selected, "Abstract"])) "No abstract." else display.table[input$ex1_rows_selected, "Abstract"]
        ))} else HTML("<i>Select a reference...</i>")
    )
    
    output$N <- renderText(nrow(display.table))
    
    #Create Links
    display.table$'Title - Linked' <- createLink(display.table$PMID, display.table$Title)
    
    #Export option
    output$export <- downloadHandler(
      filename = function() {
        paste("references",Sys.Date(),".csv", sep = "")
      },
      content = function(file) {
        write.csv(display.table[,gsub("Title - Linked", "Title", included.headers)], file, row.names = FALSE)
      }
    )
    
    #Output
    DT::datatable(
      display.table[,included.headers],
      extensions = "Responsive",
      options = list(pageLength = 10, order = list(list(3, "desc"), list(4, "desc"))),
      rownames= FALSE, escape=FALSE, selection = 'single')
  })
}
