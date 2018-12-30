library(shiny)

shinyUI(fluidPage(
  
    titlePanel("Capstone Project App: word prediction"),
  
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
            p("This Shiny App allows to predict the most probable word to follow a given sentence."), 
            p("Predictions are made based on a corpus deriving from blog posts, news and tweets, using a Katz back-off model."), 
            h3("Usage"), 
            p("Enter a sentence in the text input box, then click on Predict to get the predicted word."), 
            p("It is also possible to change the bigram and trigram discounts for the prediction."), 
            strong(textOutput("pred")), 
            strong(textOutput("prob")), 
            br(), 
            plotOutput("pred_plot")
        )
    )
))
