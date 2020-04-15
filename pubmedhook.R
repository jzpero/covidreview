library(xml2)
library(anytime)

c <- read_xml("data/pubmed_result.xml")
articles <- xml_find_all(c,"./PubmedArticle")

PMIDS <- vector("character", length(articles))
DATES <- vector("character", length(articles))

for (i in 1:length(articles)) {
   PMIDS[i] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/PMID"))
   group <- xml_find_all(articles[i], "./PubmedData/History/PubMedPubDate")
   node <- group[xml_attr(group, "PubStatus") == "pubmed"]
   year <- xml_text(xml_find_first(node, "./Year"))
   month <- xml_text(xml_find_first(node, "./Month"))
   day <- xml_text(xml_find_first(node, "./Day"))
   DATES[i] <- paste(year, month, day, sep="-")
   cat(i, "\n")
}

output <- data.frame(pmid = PMIDS, date = anytime::anydate(DATES))
View(output)

write.table(output, "date_output2.csv", row.names = FALSE, sep=",")
