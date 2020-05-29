library(xml2)
library(anytime)
library(stringr)

files <- list.files("data/pubmed/", full.names=TRUE)

writeToDisk <- function(count) {
   updates <- data.frame(pmid = PMIDS[1:count], date=DATES[1:count], jabbrv=JABBRVS[1:count], stringsAsFactors=F)
   data <- rbind(data, updates, stringsAsFactors=F, make.row.names=F)
   write.table(data, "data/metadata.csv", row.names = FALSE, sep=",")
   # cat("Writing...\n")
}

# c_ref <- read.csv("data/countrylist.csv", stringsAsFactors = F)
# c_ref <- c_ref$ï..Country

for (file in files) {
   c <- read_xml(file)
   cat(file,"\n")
   
   articles <- xml_find_all(c,"./PubmedArticle")
   
   # input the existing dates information
   data <- read.table("data/metadata.csv", header = T, sep=",", stringsAsFactors = F, colClasses = "character")
   
   PMIDS <- vector("character", length(articles))
   DATES <- vector("character", length(articles))
   JABBRVS <- vector("character", length(articles))
   COUNTRIES <- vector("character", length(articles))
   count <- 0
   
   for (i in 1:length(articles)) {
      refid <- xml_text(xml_find_first(articles[i], "./MedlineCitation/PMID"))
      
      # only add nonexisting entries
      if (!refid %in% data$pmid) {
         count <- count + 1
         group <- xml_find_all(articles[i], "./PubmedData/History/PubMedPubDate")
         node <- group[xml_attr(group, "PubStatus") == "pubmed"]
         if (length(node) == 0) {
            node <- group[xml_attr(group, "PubStatus") == "entrez"]
         }
         year <- xml_text(xml_find_first(node, "./Year"))
         month <- xml_text(xml_find_first(node, "./Month"))
         day <- xml_text(xml_find_first(node, "./Day"))
         
         PMIDS[count] <- refid
         DATES[count] <- paste(year, month, day, sep="-")
         JABBRVS[count] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/MedlineJournalInfo/MedlineTA"))
         
         # t <- str_detect(tail(strsplit(
         #    xml_text(xml_find_first(articles[i], "./MedlineCitation/Article/AuthorList/Author/AffiliationInfo/Affiliation"))
         #    , split=',')[[1]], 1), c_ref)
         # 
         # if (!is.na(any(t)) & any(t)) {
         #    COUNTRIES[count] <- c_ref[t]
         # }
         # FULLJOURN[count] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/Article/Journal/Title"))
      }
      # cat(i*100/length(articles),"%","(",i,")","\n")
      
      # every 100, write to disk and clear buffer
      # if (count == 100) {
      #    writeToDisk()
      #    PMIDS <- vector("character", 100)
      #    DATES <- vector("character", 100)
      #    JABBRVS <- vector("character", 100)
      #    count <- 0
      # }
   }

   #write the remainder
   writeToDisk(count)
}

