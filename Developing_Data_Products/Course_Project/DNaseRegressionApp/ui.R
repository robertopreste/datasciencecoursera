library(shiny)
library(plotly)

shinyUI(fluidPage(
  
  titlePanel("DNase Regression"),
  
  sidebarLayout(
    sidebarPanel(
       sliderInput("span", "Loess model span: ", 
                   min = 0.1, max = 1.0, value = 0.75, step = 0.01), 
       checkboxInput("fit", strong("Show the Loess model on the plot."), 
                     value = T), 
       numericInput("pred", "Insert your optical density value: ", 
                    min = 0.0, max = 2.0, value = 1.0, step = 0.1), 
       submitButton("Submit")
    ),
    
    mainPanel(
        p("The DNase dataset is part of the datasets R package, and was 
          obtained during development of an ELISA assay for the recombinant 
          protein DNase in rat serum."), 
        p("The aim of the experiment was to determine the concentration 
          of the DNase protein starting from the detected optical density 
          of the sample."), 
        strong("You can tweak the span parameter of the Loess regression 
               used to model these data, and then provide your own optical 
               density to predict the related DNase concentration."), 
       plotlyOutput("regrPlot"), 
       br(), br(), 
       strong(textOutput("predtxt"))
    )
  )
))
