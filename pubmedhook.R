library(xml2)
library(anytime)

# input the search result XML
c <- read_xml("data/pubmed_result.xml")
articles <- xml_find_all(c,"./PubmedArticle")

# input the existing dates information
data <- read.table("data/date_output.csv", header = T, sep=",", stringsAsFactors = F, colClasses = "character")

# PMIDS <- vector("character", length(articles))
# DATES <- vector("character", length(articles))

for (i in 1:length(articles)) {
   refid <- xml_text(xml_find_first(articles[i], "./MedlineCitation/PMID"))
   # only add nonexisting entries
   if (!refid %in% data$pmid) {
      group <- xml_find_all(articles[i], "./PubmedData/History/PubMedPubDate")
      node <- group[xml_attr(group, "PubStatus") == "pubmed"]
      year <- xml_text(xml_find_first(node, "./Year"))
      month <- xml_text(xml_find_first(node, "./Month"))
      day <- xml_text(xml_find_first(node, "./Day"))
      date_temp <- paste(year, month, day, sep="-")
      temp <- data.frame(pmid=refid, date=date_temp, stringsAsFactors = F)
      data <- rbind(data, temp, stringsAsFactors=F, make.row.names=F)
   }
   cat(i*100/length(articles),"%\n")
}

# output <- data.frame(pmid = PMIDS, date = anytime::anydate(DATES))
View(data)

write.table(data, "data/date_output.csv", row.names = FALSE, sep=",")
