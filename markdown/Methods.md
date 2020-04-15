## Search Methods
Our current PubMed search strategy is:

```
((((("COVID-19" [Supplementary Concept]) OR "severe acute respiratory syndrome coronavirus 2" [Supplementary Concept]) OR COVID-19[Title/Abstract]) OR coronavirus 19[Title/Abstract]) OR SARS-COV-2[Title/Abstract] OR wuhan coronavirus AND 2019/12:2030[pdat]) OR 2019-nCoV OR 2019nCoV OR COVID-19 OR SARS-CoV-2)
```

## Updating

Our search is ongoing as new literature emerges. Our internal repository of unfiltered articles has been updated on the following dates:

- March 28, 2020 (N=1890)
- April 8, 2020 (N=3288)

As we continually review and process the literature in sequential order, oldest to newest, we will continue to add included publications. Past updates are:

- April 12, 2020 (N=537)
- April 13, 2020 (N=659)
- April 14, 2020 (N=827)

## Inclusion Criteria
No strict inclusion criteria were established; the purpose of this literature review is to provide high-yield pertinent research to the front-line clinician across a breadth of areas, specifically oriented towards the Ontario/Canada/North American context of COVID-19.

The overarching driving question is, "What information is most valuable to someone involved in the care of COVID-19 patients?"

In general, the following types of references were usually included unless reasons for exclusion existed:

- Evidence-based documents or guidelines for intervention or treatment
- Clinical trials
- Systematic reviews and meta-analyses
- Case studies/reports with unique or significant findings
- Ontario- or Canada-specific analysis
- High-quality narrative reviews
- High-quality expert opinion or consensus


## Exclusion Criteria
Few strict exclusion criteria were applied. As above, our assessment of references was more qualitative than quantitative.

**Absolute exclusion criteria:** 

 - Full text not in the English language  
 - Full text not available via open-access source or institutional login

**Moderate exclusion criteria:**  

 - Poorly referenced or highly subjective with limited contributions to clinical practice
 - Case reports/studies with no unique findings
 - News articles
 - Explanation of journal responses to COVID-19
 - Relevant only to overseas/international settings

## Screening and Tagging Methods
References are independently screened via title/abstract review by two or more reviewers each.
Disagreements are resolved by group consensus or a third reviewer when necessary.
Reference type, specialties of interest, and relevance to front-line clinicians are assessed and assigned.
We update this website with newly included references on a regular basis.

## Webtool Implementation
This fully open-source tool has been written in Shiny in R. Source code, data, and acknowledgements are available at https://github.com/jzpero/covid19lit. Interested in contributing? Contact: jasper.ho (at) medportal.ca.

## Notes
This tool is a work in progress. It was also developed by a non-professional. It relies on online data from PubMed parsed from official tools, with custom code or public libraries. As such, there may be occasional errors. Please do not rely on any specific data found on this online tool without appropriate confirmation from the source. Errors may include:

- publication date (often incomplete or in varied formats on PubMed)
- relevant specialties (determined by title/abstract review, may not fully capture all applications)
