library(shiny)
library(tidyverse)
library(quanteda)
library(data.table)
library(stringi)

# load pretrained ngrams models
load("data/ngrams_trained.RData")

# source various functions used 
source("scripts.R")

# prediction function
predict_word <- function(bigPre, gamma2=0.4, gamma3=0.4) {
    bigPre <- gsub(" ", "_", bigPre)
    bigPre <- gsub(".", "", bigPre, fixed = T)
    bigPre <- gsub(",", "", bigPre, fixed = T)
    bigPre <- gsub("'", "", bigPre, fixed = T)
    if (length(str_split(bigPre, "_")[[1]]) > 2) {
        bigPre <- tail(str_split(bigPre, "_")[[1]], 2)
        bigPre <- paste(bigPre, collapse = "_")
    }
    # print(bigPre)
    obs_trigs <- getObsTrigs(bigPre, trigs)
    unobs_trig_tails <- getUnobsTrigTails(obs_trigs$ngram, unigs)
    bo_bigrams <- getBoBigrams(bigPre, unobs_trig_tails)
    obs_bo_bigrams <- getObsBoBigrams(bigPre, unobs_trig_tails, bigrs)
    unobs_bo_bigrams <- getUnobsBoBigrams(bigPre, unobs_trig_tails, obs_bo_bigrams)
    qbo_obs_bigrams <- getObsBigProbs(obs_bo_bigrams, unigs, gamma2)
    unig <- str_split(bigPre, "_")[[1]][2]
    unig <- unigs[unigs$ngram == unig,]
    alpha_big <- getAlphaBigram(unig, bigrs, gamma2)
    qbo_unobs_bigrams <- getQboUnobsBigrams(unobs_bo_bigrams, unigs, alpha_big)
    qbo_obs_trigrams <- getObsTriProbs(obs_trigs, bigrs, bigPre, gamma3)
    bigram <- bigrs[bigrs$ngram %in% bigPre, ]
    alpha_trig <- getAlphaTrigram(obs_trigs, bigram, gamma3)
    qbo_unobs_trigrams <- getUnobsTriProbs(bigPre, qbo_obs_bigrams,
                                           qbo_unobs_bigrams, alpha_trig)
    qbo_trigrams <- rbind(qbo_obs_trigrams, qbo_unobs_trigrams)
    qbo_trigrams <- qbo_trigrams[order(-qbo_trigrams$prob), ]
    # pred <- getPrediction(qbo_trigrams)
    # preds <- getPredictions(qbo_trigrams)
    
    return(qbo_trigrams)
}

shinyServer(function(input, output) {
    # calculate most probable words and their probabilities
    predictions <- eventReactive(input$predictButton, {
        predict_word(
            bigPre = input$phrase,
            gamma2 = input$gamma2,
            gamma3 = input$gamma3
        )
    })
    
    # find most probable word and probability
    most_prob <- eventReactive(input$predictButton, {
        getPrediction(predictions())
    })
    # find top 5 most probable words and probabilities
    top_probs <- eventReactive(input$predictButton, {
        getPredictions(predictions())
    })
    
    output$pred <- renderText({
        paste0("Predicted word: ", most_prob()[1])
    })
    output$prob <- renderText({
        paste0("Prediction probability: ", round(as.numeric(most_prob()[2]), 5))
    })
    
    output$pred_plot <- renderPlot({
        p <- top_probs() %>%
            ggplot(aes(x = reorder(ngram, prob), y = prob)) +
            geom_col(aes(fill = ngram)) +
            coord_flip() +
            guides(fill = FALSE) +
            labs(title = "Top 5 predicted words",
                 x = "Word", y = "Predicted probability") + 
            theme_light()
        p
    })
  
})
