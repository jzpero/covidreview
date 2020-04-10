library(xml2)
library(anytime)

getPubDates <- function(query_vector) {
      c <- read_xml("data/pubmed_result.xml")
      articles <- xml_find_all(c,"./PubmedArticle")
      
      PMIDS <- vector("character", length(articles))
      DATES <- vector("character", length(articles))
      
      for (i in 1:length(articles)) {
         PMIDS[i] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/PMID"))
         DATES[i] <- xml_text(xml_find_first(articles[i], "./MedlineCitation/Article/ArticleDate"))
      }
      
      output <- data.frame(pmid = PMIDS, date = anytime::anydate(DATES))
}