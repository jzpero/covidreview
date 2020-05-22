library(xml2)
library(anytime)

# input the PubMed search result XML
c <- read_xml("data/pubmed_result.xml")
articles <- xml_find_all(c,"./PubmedArticle")

# input the existing dates information
data <- read.table("data/metadata.csv", header = T, sep=",", stringsAsFactors = F, colClasses = "character")

PMIDS <- vector("character", 100)
DATES <- vector("character", 100)
JABBRVS <- vector("character", 100)
FULLJOURN <- vector("character", 100)
count <- 0

writeToDisk <- function() {
   updates <- data.frame(pmid = PMIDS[1:count], date=DATES[1:count], jabbrv=JABBRVS[1:count], journal=FULLJOURN[1:count], stringsAsFactors=F)
   data <- rbind(data, updates, stringsAsFactors=F, make.row.names=F)
   write.table(data, "data/metadata.csv", row.names = FALSE, sep=",")
   cat("Writing...\n")
}

for (i in 1:length(articles)) {
   refid <- xml_text(xml_find_first(articles[i], "./MedlineCitation/PMID"))
   
   # only add nonexisting entries
   if (!refid %in% data$pmid) {
      count <- count + 1
      group <- xml_find_all(articles[i], "./PubmedData/History/PubMedPubDate")
      node <- group[xml_attr(group, "PubStatus") == "pubmed"]
      year <- xml_text(xml_find_first(node, "./Year"))
      month <- xml_text(xml_find_first(node, "./Month"))
      day <- xml_text(xml_find_first(node, "./Day"))

      PMIDS[count] <- refid
      DATES[count] <- paste(year, month, day, sep="-")
      JABBRVS[count] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/MedlineJournalInfo/MedlineTA"))
      FULLJOURN[count] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/Article/Journal/Title"))
   }
   cat(i*100/length(articles),"%","(",i,")","\n")
   
   # every 100, write to disk and clear buffer
   if (count == 100) {
      writeToDisk()
      PMIDS <- vector("character", 100)
      DATES <- vector("character", 100)
      JABBRVS <- vector("character", 100)
      count <- 0
   }
}

#write the remainder
if (count > 0) writeToDisk()
