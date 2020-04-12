filterPanel <- wellPanel(
  id = "searchpanel",
  p(strong("Filter Options"), br(), "Any combination of filters accepted."),
  selectInput(inputId = "journal", label="Journal", choices = NULL, multiple = TRUE, ),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "study", "Type of Study", choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "author", "Author(s)",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  selectInput(inputId = "specialty", "Specialty Bucket",choices = NULL, multiple = TRUE),
  div(style = "margin-top:-15px"),
  shinyWidgets::radioGroupButtons(inputId="specSwitch", size="sm", label="Specialty matches:", choices=c("Any term", "All terms"), selected="Any term", status="info"),
  div(style = "margin-top:-10px"),
  hr(),
  div(style = "margin-top:-15px"),
  p(textOutput("N", inline = TRUE), " result(s)."),
  fluidRow(
    column(6,shinyWidgets::dropdown(
      downloadButton(outputId = "export", label = "CSV", class="btn-secondary btn-sm"),
      # downloadButton(outputId = "report", label = "PDF", class="btn-secondary btn-sm"),
      status="btn-primary btn-sm",
      size="sm",
      label="Download results"
    )),
    column(6, actionButton(inputId = "clearAll", "Clear filters", class="btn-primary btn-sm"))
  )
)

ui <- navbarPage(
  title = 'COVID-19 Literature Review',
  position = c("fixed-top"),
  tabPanel(
      'Included',
      id="tab-panel",
      shinyjs::useShinyjs(),
      fluidRow(
        column(3, filterPanel, wellPanel(htmlOutput("ref_caption"))),
        column(9, DT::dataTableOutput('ex1'))
      )
  ),
  # tabPanel("Unreviewed",
  #          fluidRow(
  #            column(3,
  #                   fluidRow(
  #                     filterPanel
  #                   ),
  #                   fluidRow(
  #                     wellPanel(
  #                       htmlOutput("ref_caption")
  #                     )
  #                   )
  #            ),
  #            column(9)
  #          )
  # ),
  navbarMenu("About",
    tabPanel("The Project",
           tags$style(type="text/css","body {padding-top:60px;}"),
           fluidRow(column(3),
             column(6,wellPanel(HTML(includeMarkdown("markdown/About-Proj.md")))),
             column(3))
    ),
    tabPanel('Methods',
           fluidRow(column(3),
                    column(6,wellPanel(HTML(includeMarkdown("markdown/Methods.md")))),
                    column(3))
    )#,
    # tabPanel('Statistics',
    #          tags$style(type="text/css","body {padding-top: 70px;}"),
    #          fluidRow(column(3),
    #                   column(6,
    #                          wellPanel(
    #                          p("Breakdown of Included Study Type"),
    #                          plotOutput("pie"),
    #                          p("References by Publication Date"),
    #                          plotOutput("bar"))),
    #                   column(3))
    # )
  ),
  collapsible = TRUE,
  includeCSS("www/yeti.css"),
  tags$head(includeHTML(("google-analytics.html")), tags$link(rel="shortcut icon", href="favicon.ico"))
)
