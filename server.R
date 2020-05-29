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
  sprintf('<a href="https://www.ncbi.nlm.nih.gov/pubmed/%s" target="_blank"><b>%s</b></a>', PMID, text)
}

included.headers <- c("Title - Linked", "Author", "Journal","Date",  "PMID", "Type of Study", "buckets_raw", "Specialty")

# Load the most recent data
link <- list.files("data/", pattern="(current)", full.names=TRUE)[1]

# Load the cached data OR create an empty DF
if (file.exists("data/cache.RDS")) {
  filtered.table <- readRDS("data/cache.RDS")
} else {
  filtered.table <- data.frame(AuthorList=c(), Author=c(), Journal=c(), 'Type of Study'=c(),  Title=c(), Date=c(), PMID=c(), specialty_raw=c(), buckets_raw=c(), Abstract=c(),stringsAsFactors = FALSE, check.names = FALSE)
}

# Load the current data
rawtable <- read.csv(link, sep = ",", na.strings="", encoding = "UTF-8", check.names=FALSE, stringsAsFactors=FALSE, colClasses = "character")
rawtable <- rawtable %>% select(-"")
metadata <- read.csv("data/metadata.csv", header=T, colClasses = c("character", "character", "character"))
headers <- colnames(rawtable)

# For current data NOT in cache, deduplicate entries, merging the specialties and type bucket
unique_refs <- unique(rawtable$PMID)
new_data <- rawtable[!rawtable$PMID %in% filtered.table$PMID,]
new_unique_pmid <- unique(new_data$PMID)

if (length(new_unique_pmid) > 0) {
  for (i in 1:length(new_unique_pmid)) {
    group <- (new_data %>% filter(PMID == new_unique_pmid[i])) # separate out the reviews of the same reference
    group_spec <- group %>% select(starts_with("Spec"))
    vec_spec <- c()
    group_buck <- group %>% select(starts_with("Type of Publication"))
    vec_buck <- c()


    for (j in 1:nrow(group)) { #iterate through the reviews of the reference and create a list of (specialty) values and (type bucket) values
      vec_spec <- c(vec_spec, group_spec[j,])
      vec_buck <- c(vec_buck, group_buck[j,])
    }

    specialties <- unique(as.vector(unlist(vec_spec))) # get unique entries as vector
    specialties <- specialties[!is.na(specialties)]
    buckets <- unique(as.vector(unlist(vec_buck))) # get unique entries as vector
    buckets <- buckets[!is.na(buckets)]

    authors <- lapply(strsplit(as.character(group$Author[1]), ","),trimws)

    d <- group$Date[1]
    if (group$PMID[1] %in% metadata$pmid) {
      replacement <- (metadata %>% filter(pmid == group$PMID[1]))$date
      if (!is.na(replacement)) d <- replacement
    }

    j_temp <- (metadata %>% filter(pmid == group$PMID[1]))$jabbrv
    if (length(j_temp) > 0) journal <- j_temp
    else journal <- capwords(group$Journal[1])

    # Fill filtered.table with useful data
    temp <- data.frame(AuthorList=I(authors), Author=group$Author[1], Journal=journal, 'Type of Study'=group$`Type of Study`[1], Title=group$Title[1], Date=d, PMID=group$PMID[1], specialty_raw=I(list(specialties)), buckets_raw=I(list(buckets)), Abstract=group$Abstract[1],stringsAsFactors = FALSE,check.names = FALSE)
    filtered.table <- rbind(filtered.table, temp)
  }

  # Write filtered.table to directory
  saveRDS(filtered.table,file="data/cache.RDS")
}

N <<- nrow(filtered.table)

#Create filter choices
unique.authors <- sort(unique(unlist(filtered.table$AuthorList)))
unique.authors <<- unique.authors[lapply(unique.authors, nchar) > 0]
unique.journals <- sort(unique(filtered.table$Journal))
unique.studytypes <<- sort(unique(filtered.table$'Type of Study'))
unique.specialties <<- sort(c("Internal Medicine", "General", "Dermatology", "ICU", "Emergency Medicine", "Anesthesia", "Radiology", "ObsGyn", "Physiatry", "Public Health", "Cardiology", "Oncology", "Psychiatry", "Family Medicine", "Gastroenterology", "Geriatrics", "Hematology", "Infectious Disease", "Immunology", "Medical Education", "Microbiology", "Nephrology", "Neurology", "Ophthalmology", "Palliative Care", "Pathology", "Pediatrics","Respirology", "Rheumatology", "Surgery", "Urology"))
unique.buckets <<- sort(c("Guidance documents and guidelines", "Systematic review/meta analysis", "Observational studies", "Experimental studies","Natural history studies", "Case report","Lab studies","Reports of interventions/treatments","Imaging studies","Letter to the Editor/Narrative Review","Statistical modelling/analytical studies"))

# Aesthestics for Shiny
filtered.table$Specialty <- lapply(filtered.table$specialty_raw, function(x) paste(x, collapse = ", "))
filtered.table$Author <- unlist(lapply(filtered.table$AuthorList, function(x) if (length(x) > 3) paste(paste(x[1:3], collapse = ", "), "et al") else paste(x, collapse = ", ")))

#############################################

server <- function(input, output, session) { # Executes once per session (no need to restart service)
  #Populate the search filters
  updateSelectizeInput(session, "journal", choices = c("Select a journal" = "", unique.journals), server = T)
  updateSelectizeInput(session, "author", choices = c("Select authors" = "", unique.authors), server = T)
  updateSelectizeInput(session, "study", choices = c("Select a research type" = "", unique.studytypes), server = T)
  updateSelectizeInput(session, "bucket", choices = c("Select a publication type" = "", unique.buckets), server = T)
  updateSelectizeInput(session, "specialty", choices = c("Select an area of interest" = "", unique.specialties), server = T)
  
  # Parse URI
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['specialty']])) {
      if (query[['specialty']] %in% unique.specialties) updateTextInput(session, "specialty", value = query[['specialty']])
    }
  })
  
  
  # Get a local copy of the dataset
  display.table <- filtered.table
  
  #clear all button actions
  observeEvent(input$clearAll, {
    shinyjs::reset("searchpanel")
  })

  #Main Data Output
  output$ex1 <- DT::renderDataTable(server=TRUE, {
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
    
    # Filter type Bucket
    if (!is.null(input$bucket) & nrow(display.table)) {
      #Initialize FALSE Vector
      v <- vector("logical",nrow(display.table))
      #iterate over author rows and flag as TRUE if ANY of the selected authors present
      for (i in 1:nrow(display.table)) {
        for (query in input$bucket) {
          if (query %in% display.table$buckets_raw[[i]]) v[i] <- TRUE; break
        }
      }
      display.table <- display.table[v,]
    }

    # Filter Specialty
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
          display.table$Author[input$ex1_rows_selected], ". ",
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
        write.csv(display.table[,c("Title", "Author", "Journal", "Date", "PMID")], file, row.names = FALSE)
      }
    )
    
    #Output
    # DT::datatable(
    #   display.table[,included.headers],
    #   colnames = c("Type of Publication"="buckets_raw", "Title" = "Title - Linked", "Type of Research"="Type of Study"),
    #   extensions = "Responsive",
    #   options = list(pageLength = 10, order = list(list(4, "desc"))),
    #   rownames= FALSE, escape=-1, selection = 'single')
    display.table[,included.headers]
  },
  options = list(pageLength = 10, order = list(list(4, "desc"))),
  escape = c(-1),
  extensions = 'Responsive',
  rownames = F,
  selection = 'single',
  colnames = c("Type of Publication"="buckets_raw", "Title" = "Title - Linked", "Type of Research"="Type of Study")
  )
}
