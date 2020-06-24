library(xml2)
library(anytime)
library(stringr)

files <- list.files("data/pubmed/", full.names=TRUE)
start_index <- 48

writeToDisk <- function(count) {
   updates <- data.frame(pmid = PMIDS[1:count], date=DATES[1:count], jabbrv=JABBRVS[1:count], stringsAsFactors=F)
   data <- rbind(data, updates, stringsAsFactors=F, make.row.names=F)
   write.table(data, "data/metadata.csv", row.names = FALSE, sep=",")
}

for (file in files[start_index:length(files)]) {
   c <- read_xml(file, options = c("RECOVER", "NOERROR", "NOBLANKS"))
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
      }
   }
   #write the remainder
   writeToDisk(count)
}

