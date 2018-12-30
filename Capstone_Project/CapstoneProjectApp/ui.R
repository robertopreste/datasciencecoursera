library(shiny)

shinyUI(fluidPage(
  
    titlePanel("Capstone Project App"),
  
    sidebarLayout(
        sidebarPanel(
            textInput("phrase", 
                      "Enter a sentence (with the last word missing):", 
                      value = "", placeholder = "Enter a sentence"), 
            numericInput("gamma2", "Insert the bigram discount value: ", 
                         min = 0.0, max = 1.0, value = 0.4, step = 0.05), 
            numericInput("gamma3", "Insert the trigram discount value: ", 
                         min = 0.0, max = 1.0, value = 0.4, step = 0.05),
            
            actionButton("predictButton", "Predict")
        ),
        mainPanel(
            p("Predicted word: "), 
            strong(textOutput("pred")), 
            p("Prediction probability: "), 
            strong(textOutput("prob")), 
            p("Most probable words: "), 
            plotOutput("pred_plot")
        )
    )
))
