ui <- navbarPage(
  title = 'COVID-19 Literature',
  position = c("fixed-top"),
  tabPanel(
      'All',
      id="tab-panel",
      shinyjs::useShinyjs(),
      fluidRow(
        column(8,
          DT::dataTableOutput('ex1')
        ),
        column(4,
            verticalLayout(
              wellPanel(
                id = "searchpanel",
                p(strong("Filter Options")),
                selectInput(inputId = "journal", label="Journal", choices = NULL, multiple = TRUE, ),
                selectInput(inputId = "study", "Type of Study", choices = NULL, multiple = TRUE),
                selectInput(inputId = "author", "Author(s)",choices = NULL, multiple = TRUE),
                selectInput(inputId = "specialty", "Specialty Bucket",choices = NULL, multiple = TRUE),
                shinyWidgets::switchInput(inputId="specSwitch", size="mini", label="Match", onLabel = "Any", offLabel = "All", value=TRUE, offStatus = "success"),
                hr(),
                actionButton(inputId = "clearAll", "Clear all", class="btn-primary btn-sm"),
                # downloadButton(outputId = "export", label = "Download all", class="btn-secondary btn-sm")
                # downloadButton(outputId = "exportselected", label = "Download selected", class="btn-secondary btn-sm")
              ),
              wellPanel(
                htmlOutput("ref_caption")
              )
            )
        )
      )
  ),
  # tabPanel("Critical Care"),
  # tabPanel("Internal Medicine"),
  # tabPanel("Emergency Medicine"),
  # tabPanel("Pediatrics"),
  # tabPanel("Radiology"),
  # tabPanel("Epi and Public Health"),
  # tabPanel("Basic Sciences"),
  navbarMenu("About",
    tabPanel("The Project",
           tags$style(type="text/css","body {padding-top: 70px;}"),
           fluidRow(column(3),
             column(6,wellPanel(HTML(includeMarkdown("markdown/About-Proj.md")))),
             column(3))
    ),
    tabPanel('Methods',
           tags$style(type="text/css","body {padding-top: 70px;}"),
           fluidRow(column(3),
                    column(6,wellPanel(HTML(includeMarkdown("markdown/Methods.md")))),
                    column(3))
    ),
    tabPanel('Statistics')
  ),
  collapsible = TRUE,
  includeCSS("www/yeti.css"),
  tags$head(includeHTML(("google-analytics.html")))
)
