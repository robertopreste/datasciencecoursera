library(shiny)
library(tidyverse)
library(plotly)
library(datasets)
data("DNase")

shinyServer(function(input, output) {
    
    modelOutput <- reactive({
        model <- loess(conc ~ density, data = DNase, span = input$span)
        predict(model, data.frame(density = input$pred))
    })
    
    output$predtxt <- renderText({
        paste0("With an optical density of ", input$pred, 
              " the estimated DNase concentration is ", round(modelOutput(), 4), ".")
    })
   
  output$regrPlot <- renderPlotly({
      
      g <- DNase %>% 
          ggplot(aes(x = density, y = conc)) + 
          geom_point() + 
          labs(x = "Optical Density", y = "Concentration")
      
      if (input$fit == T) {
          g <- g + geom_smooth(method = "loess", span = input$span)
      }
      
      g <- g + geom_point(x = input$pred, y = modelOutput(), 
                          color = "firebrick", shape = 18, size = 4)
      
      ggplotly(g)
  })
  
})
