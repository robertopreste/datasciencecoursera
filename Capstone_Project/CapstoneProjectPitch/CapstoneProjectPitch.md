Capstone Project App: Word Prediction
========================================================
author: Roberto Preste
date: 2018-12-30 
autosize: true

Overview
========================================================

The aim of the [Data Science Capstone](https://www.coursera.org/learn/data-science-project) project was to create a simple (but functional) Shiny App that would predict the next word from a given phrase.  

The task was definitely interesting and stimulating to me, since it involved delving into a new subject, NLP, understanding its peculiarities and creating an efficient modeling application. I also had to take care of sampling the training data, in order to allow the application to run smoothly and without great delay, while still offering coherent results.  

The app I created is available on [shinyapps.io](https://robertopreste.shinyapps.io/WordPredictionApp).  
Documentation can be found on [GitHub](https://github.com/robertopreste/datasciencecoursera/tree/master/Capstone_Project).  
The pitch presentation for the app is on [rpubs.com](https://rpubs.com/robertopreste/wordpredictionpitch).  

Input data
========================================================

The data used in this project come from a corpus of sentences in four different languages gathered from blog posts, news and tweets, and is available from [this link](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip). I chose to use the English subset; some examples of these sentences are:  


```r
"How are you? Btw thanks for the RT. You gonna be in DC anytime soon?" 
"If you have an alternative argument, let's hear it! :)" 
"He wasn't home alone, apparently."
```

Before using any modeling approach, these data had to be cleaned and transformed in a suitable way. This meant removing punctuation, symbols and stop words, as well as dropping profanities, based on a list available on [this GitHub repository](https://github.com/RobertJGabriel/Google-profanity-words).  

Data modeling
========================================================

The clean corpus was used to train a model that is be able to predict the next word in a given sentence. I used a [Katz back-off model](https://en.wikipedia.org/wiki/Katz's_back-off_model), which is able to estimate the conditional probability of a word given its history in the preceding n-gram (set of words). This means that the prediction of the last word of a sentence is made based on the previous 1, 2 or `n` words.  

To build this model, we need to calculate the probabilities of encountering a specific word or a combination of words, using the available training corpus. In such a model, however, one has to take into account also unseen n-grams, i.e. set of words that are not observed in the training data.  
This is done using *discounting*, which, simply stated, means retaining some of the probability mass from the observed n-grams and redistributing it to unobserved n-grams.  

Word Prediction App
========================================================

The app I created uses a bigram and trigram back-off model; it accepts a sentence and is able to predict the following word based on the last words of the given phrase. Bigrams and trigrams discounts can also be tweaked.  

[![screenshot](app_shot.jpg)](https://robertopreste.shinyapps.io/WordPredictionApp)  

