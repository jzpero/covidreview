ui <- navbarPage(
  title = 'COVID-19 Literature',
  position = c("fixed-top"),
  tabPanel(
      'Browse',
      tags$style(type="text/css","body {padding-top: 70px;}"),
      id="tab-panel",
      shinyjs::useShinyjs(),
      sidebarLayout(
         position = "right",
         sidebarPanel(
           id = "searchpanel",
           selectInput(inputId = "journal", "Journal", choices = NULL, multiple = TRUE),
           selectInput(inputId = "study", "Type of Study", choices = NULL, multiple = TRUE),
           selectInput(inputId = "author", "Author(s)",choices = NULL, multiple = TRUE),
           selectInput(inputId = "specialty", "Specialty Bucket",choices = NULL, multiple = TRUE),
           # sliderInput(inputId = "daterange", "Date Range", min=min(date_range), max=max(date_range), value=c(min(date_range), max(date_range)), round=T, ticks=T),
           # plotOutput(outputId="graph", height = "200px"),
           hr(),
           actionButton(inputId = "clearAll", "Clear All"),
           downloadButton(outputId = "export", label = "Download all"),
           downloadButton(outputId = "exportselected", label = "Download selected"),
           width=3
         ),
         mainPanel(
           DT::dataTableOutput('ex1'),
           width=9
         )
      )
  ),
  tabPanel('About',
         tags$style(type="text/css","body {padding-top: 70px;}"),
         fluidPage(
           h2("What is this?"),
           p("Recent literature on COVID-19 is highly variable in scope, quality, and applicability to the front-line physician. In a time where information and time are valuable resources, there must be a resource that provides curated primary and secondary literature so that clinical decisions can be made with more confidence. This project provides a way to browse current and relevant literature on COVID-19 that has been curated via a systematic review approach."),
           h2("Contributors"),
           HTML("Citations and data were reviewed and curated by <b>Becky Jones</b>, <b>Daniel Levin</b>, <b>Hannah Kearney</b>, <b>Jasper Ho</b>, and <b>Meghan Glibbery</b>, all medical students at McMaster University.<br>This tool was coded and designed by <b>Jasper Ho</b> <a href='https://www.twitter.com/jzpero'>@jzpero</a> in R using Shiny.<br> The project was conceptualized and is supervised by <b>Dr. Mark Crowther</b>.")
        )
  ),
    tabPanel('Methods',
           h2("Search Methods"),
           p(code('((((("COVID-19" [Supplementary Concept]) OR "severe acute respiratory syndrome coronavirus 2" [Supplementary Concept]) OR COVID-19[Title/Abstract]) OR coronavirus 19[Title/Abstract]) OR SARS-COV-2[Title/Abstract] OR wuhan coronavirus AND 2019/12:2030[pdat]) OR 2019-nCoV OR 2019nCoV OR COVID-19 OR SARS-CoV-2.')),
           h2("Screening Methods"),
           "References were independently screened via title/abstract review by two or more reviewers.",
           "Disagreements were resolved by group consensus or a third reviewer when necessary.",
           "Reference type, specialties of interest, and relevance to front-line clinicians were independently assessed and merged."
  ),
  collapsible = TRUE
)