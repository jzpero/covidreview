# Workflow
This is a working document describing the process of updating the website. It is not a perfect process, and requires more manual scripting than I would like.

## (1) Download data to local repository
1. **Download most recent references from PubMed as an XML** to `data/pubmed_output.xml` (*note: the PubMed interface has changed, no longer allowing more than 10,000 references to be downloaded. Working on a workaround.*) [as often as desired]
2. **Download most recent included references from DistillerSR site** to `data/FILENAME.csv` [as often as desired]

## (2) Data processing
1. **If you have updated the included list from DistillerSR,**
   * Add "current_" prefix to the DistillerSR .csv located in `data/`
   * Remove "current_" prefix from the old csv, and keep as many versions as you want for backup.
2. **If you have updated the reference list from PubMed,** run `processing.R` which does the following (requires a file called `data/pubmed_output.xml` which depends on the old PubMed... fix coming):
   * Parses `pubmed` date; the date of publication is very inconsistently included and we needed a consistent solution.
   * Parses ISO abbreviations of journal names
   * Parse full journal names
   * Writes these data to `data/metadata.csv`

## (3) Test locally
## (4) Deployment
1. Transfer changes to your live environment however you want. I push to a remote dev branch of the repo, merge the changes to the master branch, and then pull these changes into the server.
2. Restart shinyserver: `sudo systemctl restart shiny-server`
3. Check that it's live and working.