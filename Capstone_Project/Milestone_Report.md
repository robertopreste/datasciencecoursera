Capstone Project - Milestone Report
================
Roberto Preste
2018-12-01

-   [Synopsis](#synopsis)
-   [Getting the data](#getting-the-data)
-   [Files statistics](#files-statistics)
-   [Sampling the data](#sampling-the-data)
    -   [Samples statistics](#samples-statistics)
-   [Cleaning the data](#cleaning-the-data)
-   [n-grams Statistics](#n-grams-statistics)
    -   [1-grams](#grams)
    -   [2-grams](#grams-1)
    -   [3-grams](#grams-2)
-   [Discussion and remarks](#discussion-and-remarks)
-   [Future plans](#future-plans)

Synopsis
--------

The aim of this capstone project is to apply data science techniques in the area of Natural Language Processing using R.
The starting dataset for this project is represented by a large corpus of documents, which will be used to build a simple but effective predictive text model. The data can be found [here](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip).

This milestone report will explain the basics steps taken to load and sample the data, clean it and organize it in a useful manner to perform the subsequent modeling tasks.

Getting the data
----------------

After downloading and unzipping the data in the `data/` directory, we can check which files we have.

``` r
list.files("./data/final/", recursive = T)
```

    ##  [1] "de_DE/de_DE.blogs.txt"   "de_DE/de_DE.news.txt"   
    ##  [3] "de_DE/de_DE.twitter.txt" "en_US/en_US.blogs.txt"  
    ##  [5] "en_US/en_US.news.txt"    "en_US/en_US.twitter.txt"
    ##  [7] "fi_FI/fi_FI.blogs.txt"   "fi_FI/fi_FI.news.txt"   
    ##  [9] "fi_FI/fi_FI.twitter.txt" "ru_RU/ru_RU.blogs.txt"  
    ## [11] "ru_RU/ru_RU.news.txt"    "ru_RU/ru_RU.twitter.txt"

There are three different files, `blogs.txt`, `news.txt` and `twitter.txt` for each of the four provided languages, DE, US, FI and RU. We will use the US dataset for this project.

Files statistics
----------------

Let's get some basic statistics about these files; specifically, their size in MB, number of lines and number of words.

``` r
corp_stats <- tibble(corpus = c("en_US.blogs.txt", "en_US.news.txt", "en_US.twitter.txt"), 
                     size_MB = c(blogs_size, news_size, twitter_size), 
                     num_lines = c(blogs_len, news_len, twitter_len), 
                     num_words = c(blogs_words, news_words, twitter_words))
corp_stats %>% 
    kable()
```

| corpus             |  size\_MB|  num\_lines|  num\_words|
|:-------------------|---------:|-----------:|-----------:|
| en\_US.blogs.txt   |  200.4242|      899288|    37546239|
| en\_US.news.txt    |  196.2775|     1010242|    34762395|
| en\_US.twitter.txt |  159.3641|     2360148|    30093413|

Sampling the data
-----------------

From what we see, the datasets are quite huge, so we'll need to select a small sample of them for the sake of simplicity. This of course might harm our analysis, but it should be fine for the purposes of this project.
We will select 1% of the lines in each document, and create a cumulative sample by merging together these 3 different samples.

``` r
set.seed(420)
blogs_sample <- sample_frac(blogs_df, size = .01, replace = T)
news_sample <- sample_frac(news_df, size = .01, replace = T)
twitter_sample <- sample_frac(twitter_df, size = .01, replace = T)
cum_sample <- bind_rows(blogs_sample, news_sample, twitter_sample)
```

### Samples statistics

Now we can compute the same statistics seen above, but for our reduced samples.

``` r
sample_stats <- tibble(sample = c("blogs", "news", "twitter", "cumulative"), 
                     size = c(blogs_sample_size, news_sample_size, twitter_sample_size, cum_sample_size), 
                     num_lines = c(blogs_sample_len, news_sample_len, twitter_sample_len, cum_sample_len), 
                     num_words = c(blogs_sample_words, news_sample_words, twitter_sample_words, cum_sample_words))
sample_stats %>% 
    kable()
```

| sample     | size   |  num\_lines|  num\_words|
|:-----------|:-------|-----------:|-----------:|
| blogs      | 2.5 Mb |        8993|      375790|
| news       | 2.6 Mb |       10102|      344597|
| twitter    | 3.2 Mb |       23601|      300564|
| cumulative | 8.3 Mb |       42696|     1020951|

After this sampling, the data should be much easier to analyse and manipulate, so we can proceed to clean and prepare it for the rest of the project.

Cleaning the data
-----------------

The data we have so far need to be cleaned a bit, this means removing common stop words ("the", "of", "in", etc.), removing punctuation and whitespaces, and converting every word to lowercase; we will also remove profanity words, based on a list available on [this GitHub repository](https://github.com/RobertJGabriel/Google-profanity-words).
This will of course harm the accuracy of our future predictions, but will ensure that the data are coherent and easy to work with.
We are going to use the `tm` package for this purpose.

First we will create a so-called *corpus*, which contains our data in a suitable format.

``` r
corpus <- VCorpus(VectorSource(c(cum_sample)))
```

Now we can apply all the desired transformations and cleaning steps.

``` r
corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removeWords, stopwords("en"))
corpus <- tm_map(corpus, removePunctuation, preserve_intra_word_contractions = T)
tospace <- content_transformer(function(x, pattern) {return (gsub(pattern, " ", x))})
corpus <- tm_map(corpus, tospace, "–")
corpus <- tm_map(corpus, tospace, "”")
corpus <- tm_map(corpus, tospace, "“")
corpus <- tm_map(corpus, tospace, "…")
corpus <- tm_map(corpus, removeNumbers)
remove_url <- function(x) gsub("(f|ht)tp(s?)://(.*)[.][a-z]+", " ", x)
corpus <- tm_map(corpus, content_transformer(remove_url))
remove_handles <- function(x) gsub("@[^\\s]+", " ", x)
corpus <- tm_map(corpus, content_transformer(remove_handles))
profanity <- readLines("./data/profanity.txt")
corpus <- tm_map(corpus, removeWords, profanity)
corpus <- tm_map(corpus, stripWhitespace)
```

Now we are ready to perform some analysis and gain a few interesting insights from our data.

n-grams Statistics
------------------

The clean corpus we generated can be used to analyse word frequencies, as well as a couple of n-grams frequencies. An n-gram is a contiguous sequence of *n* items (in this case, words) from a given corpus; we will explore bi-grams (*n* = 2) and tri-grams (*n* = 3).
In order to do this, we must first create a document-term matrix, which contains the frequency of each n-gram over the three documents we have (blogs, news and tweets).
We are going to use the `RWeka` library for this purpose.

### 1-grams

``` r
dtm1 <- DocumentTermMatrix(corpus)
top_1gram <- findMostFreqTerms(dtm1, n = 30)$`1`
top_1gram
```

    ##   will   said   just    one   like    can    get   time    new   good 
    ##   3077   3039   2953   2894   2618   2493   2307   2200   1948   1826 
    ##    now    day   love   know people    see  first   back  going   also 
    ##   1750   1665   1637   1600   1501   1399   1386   1348   1337   1285 
    ##  great   make  think   last   year   much    two really   work    got 
    ##   1248   1242   1238   1229   1227   1191   1178   1168   1133   1115

``` r
df_1gram <- tibble(word = names(top_1gram), freq = top_1gram)
p_1gram <- df_1gram %>% 
    ggplot(aes(x = reorder(word, -freq), y = freq, label = word)) + 
    geom_col(fill = "steelblue") + 
    labs(x = "", y = "Frequency", title = "Distribution of top 30 words") + 
    theme_light() + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
ggplotly(p_1gram, tooltip = c("freq", "word"))
```

    ## PhantomJS not found. You can install it with webshot::install_phantomjs(). If it is installed, please make sure the phantomjs executable can be found via the PATH variable.

<!--html_preserve-->

<script type="application/json" data-for="htmlwidget-f82bab617289f7136bd7">{"x":{"data":[{"orientation":"v","width":[0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999],"base":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"x":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"y":[3077,3039,2953,2894,2618,2493,2307,2200,1948,1826,1750,1665,1637,1600,1501,1399,1386,1348,1337,1285,1248,1242,1238,1229,1227,1191,1178,1168,1133,1115],"text":["freq: 3077<br />word: will","freq: 3039<br />word: said","freq: 2953<br />word: just","freq: 2894<br />word: one","freq: 2618<br />word: like","freq: 2493<br />word: can","freq: 2307<br />word: get","freq: 2200<br />word: time","freq: 1948<br />word: new","freq: 1826<br />word: good","freq: 1750<br />word: now","freq: 1665<br />word: day","freq: 1637<br />word: love","freq: 1600<br />word: know","freq: 1501<br />word: people","freq: 1399<br />word: see","freq: 1386<br />word: first","freq: 1348<br />word: back","freq: 1337<br />word: going","freq: 1285<br />word: also","freq: 1248<br />word: great","freq: 1242<br />word: make","freq: 1238<br />word: think","freq: 1229<br />word: last","freq: 1227<br />word: year","freq: 1191<br />word: much","freq: 1178<br />word: two","freq: 1168<br />word: really","freq: 1133<br />word: work","freq: 1115<br />word: got"],"type":"bar","marker":{"autocolorscale":false,"color":"rgba(70,130,180,1)","line":{"width":1.88976377952756,"color":"transparent"}},"showlegend":false,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":43.7625570776256,"r":7.30593607305936,"b":33.3000356779079,"l":48.9497716894977},"plot_bgcolor":"rgba(255,255,255,1)","paper_bgcolor":"rgba(255,255,255,1)","font":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"title":"Distribution of top 30 words","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":17.5342465753425},"xaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.4,30.6],"tickmode":"array","ticktext":["will","said","just","one","like","can","get","time","new","good","now","day","love","know","people","see","first","back","going","also","great","make","think","last","year","much","two","really","work","got"],"tickvals":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"categoryorder":"array","categoryarray":["will","said","just","one","like","can","get","time","new","good","now","day","love","know","people","see","first","back","going","also","great","make","think","last","year","much","two","really","work","got"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-45,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"y","title":"","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[-153.85,3230.85],"tickmode":"array","ticktext":["0","1000","2000","3000"],"tickvals":[0,1000,2000,3000],"categoryorder":"array","categoryarray":["0","1000","2000","3000"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"x","title":"Frequency","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":"transparent","line":{"color":"rgba(179,179,179,1)","width":0.66417600664176,"linetype":"solid"},"yref":"paper","xref":"paper","x0":0,"x1":1,"y0":0,"y1":1}],"showlegend":false,"legend":{"bgcolor":"rgba(255,255,255,1)","bordercolor":"transparent","borderwidth":1.88976377952756,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.689497716895}},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":[{"name":"Collaborate","icon":{"width":1000,"ascent":500,"descent":-50,"path":"M487 375c7-10 9-23 5-36l-79-259c-3-12-11-23-22-31-11-8-22-12-35-12l-263 0c-15 0-29 5-43 15-13 10-23 23-28 37-5 13-5 25-1 37 0 0 0 3 1 7 1 5 1 8 1 11 0 2 0 4-1 6 0 3-1 5-1 6 1 2 2 4 3 6 1 2 2 4 4 6 2 3 4 5 5 7 5 7 9 16 13 26 4 10 7 19 9 26 0 2 0 5 0 9-1 4-1 6 0 8 0 2 2 5 4 8 3 3 5 5 5 7 4 6 8 15 12 26 4 11 7 19 7 26 1 1 0 4 0 9-1 4-1 7 0 8 1 2 3 5 6 8 4 4 6 6 6 7 4 5 8 13 13 24 4 11 7 20 7 28 1 1 0 4 0 7-1 3-1 6-1 7 0 2 1 4 3 6 1 1 3 4 5 6 2 3 3 5 5 6 1 2 3 5 4 9 2 3 3 7 5 10 1 3 2 6 4 10 2 4 4 7 6 9 2 3 4 5 7 7 3 2 7 3 11 3 3 0 8 0 13-1l0-1c7 2 12 2 14 2l218 0c14 0 25-5 32-16 8-10 10-23 6-37l-79-259c-7-22-13-37-20-43-7-7-19-10-37-10l-248 0c-5 0-9-2-11-5-2-3-2-7 0-12 4-13 18-20 41-20l264 0c5 0 10 2 16 5 5 3 8 6 10 11l85 282c2 5 2 10 2 17 7-3 13-7 17-13z m-304 0c-1-3-1-5 0-7 1-1 3-2 6-2l174 0c2 0 4 1 7 2 2 2 4 4 5 7l6 18c0 3 0 5-1 7-1 1-3 2-6 2l-173 0c-3 0-5-1-8-2-2-2-4-4-4-7z m-24-73c-1-3-1-5 0-7 2-2 3-2 6-2l174 0c2 0 5 0 7 2 3 2 4 4 5 7l6 18c1 2 0 5-1 6-1 2-3 3-5 3l-174 0c-3 0-5-1-7-3-3-1-4-4-5-6z"},"click":"function(gd) { \n        // is this being viewed in RStudio?\n        if (location.search == '?viewer_pane=1') {\n          alert('To learn about plotly for collaboration, visit:\\n https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html');\n        } else {\n          window.open('https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html', '_blank');\n        }\n      }"}],"cloud":false},"source":"A","attrs":{"b0952534ad05":{"x":{},"y":{},"label":{},"type":"bar"}},"cur_data":"b0952534ad05","visdat":{"b0952534ad05":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"base_url":"https://plot.ly"},"evals":["config.modeBarButtonsToAdd.0.click"],"jsHooks":[]}</script>
<!--/html_preserve-->
### 2-grams

``` r
bi_gram_tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))
dtm2 <- DocumentTermMatrix(corpus, control = list(tokenize = bi_gram_tokenizer))
top_2gram <- findMostFreqTerms(dtm2, n = 30)$`1`
top_2gram
```

    ##       right now       last year        new york     high school 
    ##             248             214             198             149 
    ##      last night       years ago      first time         can get 
    ##             140             137             133             123 
    ##       feel like looking forward       last week     even though 
    ##             122             116             108             103 
    ##        st louis       make sure      looks like       next week 
    ##             100              98              95              94 
    ##    good morning  happy birthday   united states         one day 
    ##              93              89              86              85 
    ##         can see       look like      new jersey       every day 
    ##              83              81              81              80 
    ##       two years       just like           s day        let know 
    ##              79              76              76              72 
    ##         go back        just got 
    ##              70              70

``` r
df_2gram <- tibble(word = names(top_2gram), freq = top_2gram)
p_2gram <- df_2gram %>% 
    ggplot(aes(x = reorder(word, -freq), y = freq, label = word)) + 
    geom_col(fill = "seagreen") + 
    labs(x = "", y = "Frequency", title = "Distribution of top 30 bigrams") + 
    theme_light() + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggplotly(p_2gram, tooltip = c("freq", "word"))
```

<!--html_preserve-->

<script type="application/json" data-for="htmlwidget-0b38280da75a310b1213">{"x":{"data":[{"orientation":"v","width":[0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999],"base":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"x":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"y":[248,214,198,149,140,137,133,123,122,116,108,103,100,98,95,94,93,89,86,85,83,81,81,80,79,76,76,72,70,70],"text":["freq: 248<br />word: right now","freq: 214<br />word: last year","freq: 198<br />word: new york","freq: 149<br />word: high school","freq: 140<br />word: last night","freq: 137<br />word: years ago","freq: 133<br />word: first time","freq: 123<br />word: can get","freq: 122<br />word: feel like","freq: 116<br />word: looking forward","freq: 108<br />word: last week","freq: 103<br />word: even though","freq: 100<br />word: st louis","freq:  98<br />word: make sure","freq:  95<br />word: looks like","freq:  94<br />word: next week","freq:  93<br />word: good morning","freq:  89<br />word: happy birthday","freq:  86<br />word: united states","freq:  85<br />word: one day","freq:  83<br />word: can see","freq:  81<br />word: look like","freq:  81<br />word: new jersey","freq:  80<br />word: every day","freq:  79<br />word: two years","freq:  76<br />word: just like","freq:  76<br />word: s day","freq:  72<br />word: let know","freq:  70<br />word: go back","freq:  70<br />word: just got"],"type":"bar","marker":{"autocolorscale":false,"color":"rgba(46,139,87,1)","line":{"width":1.88976377952756,"color":"transparent"}},"showlegend":false,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":43.7625570776256,"r":7.30593607305936,"b":60.3444848157744,"l":43.1050228310502},"plot_bgcolor":"rgba(255,255,255,1)","paper_bgcolor":"rgba(255,255,255,1)","font":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"title":"Distribution of top 30 bigrams","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":17.5342465753425},"xaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.4,30.6],"tickmode":"array","ticktext":["right now","last year","new york","high school","last night","years ago","first time","can get","feel like","looking forward","last week","even though","st louis","make sure","looks like","next week","good morning","happy birthday","united states","one day","can see","look like","new jersey","every day","two years","just like","s day","let know","go back","just got"],"tickvals":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"categoryorder":"array","categoryarray":["right now","last year","new york","high school","last night","years ago","first time","can get","feel like","looking forward","last week","even though","st louis","make sure","looks like","next week","good morning","happy birthday","united states","one day","can see","look like","new jersey","every day","two years","just like","s day","let know","go back","just got"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-45,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"y","title":"","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[-12.4,260.4],"tickmode":"array","ticktext":["0","50","100","150","200","250"],"tickvals":[0,50,100,150,200,250],"categoryorder":"array","categoryarray":["0","50","100","150","200","250"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"x","title":"Frequency","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":"transparent","line":{"color":"rgba(179,179,179,1)","width":0.66417600664176,"linetype":"solid"},"yref":"paper","xref":"paper","x0":0,"x1":1,"y0":0,"y1":1}],"showlegend":false,"legend":{"bgcolor":"rgba(255,255,255,1)","bordercolor":"transparent","borderwidth":1.88976377952756,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.689497716895}},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":[{"name":"Collaborate","icon":{"width":1000,"ascent":500,"descent":-50,"path":"M487 375c7-10 9-23 5-36l-79-259c-3-12-11-23-22-31-11-8-22-12-35-12l-263 0c-15 0-29 5-43 15-13 10-23 23-28 37-5 13-5 25-1 37 0 0 0 3 1 7 1 5 1 8 1 11 0 2 0 4-1 6 0 3-1 5-1 6 1 2 2 4 3 6 1 2 2 4 4 6 2 3 4 5 5 7 5 7 9 16 13 26 4 10 7 19 9 26 0 2 0 5 0 9-1 4-1 6 0 8 0 2 2 5 4 8 3 3 5 5 5 7 4 6 8 15 12 26 4 11 7 19 7 26 1 1 0 4 0 9-1 4-1 7 0 8 1 2 3 5 6 8 4 4 6 6 6 7 4 5 8 13 13 24 4 11 7 20 7 28 1 1 0 4 0 7-1 3-1 6-1 7 0 2 1 4 3 6 1 1 3 4 5 6 2 3 3 5 5 6 1 2 3 5 4 9 2 3 3 7 5 10 1 3 2 6 4 10 2 4 4 7 6 9 2 3 4 5 7 7 3 2 7 3 11 3 3 0 8 0 13-1l0-1c7 2 12 2 14 2l218 0c14 0 25-5 32-16 8-10 10-23 6-37l-79-259c-7-22-13-37-20-43-7-7-19-10-37-10l-248 0c-5 0-9-2-11-5-2-3-2-7 0-12 4-13 18-20 41-20l264 0c5 0 10 2 16 5 5 3 8 6 10 11l85 282c2 5 2 10 2 17 7-3 13-7 17-13z m-304 0c-1-3-1-5 0-7 1-1 3-2 6-2l174 0c2 0 4 1 7 2 2 2 4 4 5 7l6 18c0 3 0 5-1 7-1 1-3 2-6 2l-173 0c-3 0-5-1-8-2-2-2-4-4-4-7z m-24-73c-1-3-1-5 0-7 2-2 3-2 6-2l174 0c2 0 5 0 7 2 3 2 4 4 5 7l6 18c1 2 0 5-1 6-1 2-3 3-5 3l-174 0c-3 0-5-1-7-3-3-1-4-4-5-6z"},"click":"function(gd) { \n        // is this being viewed in RStudio?\n        if (location.search == '?viewer_pane=1') {\n          alert('To learn about plotly for collaboration, visit:\\n https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html');\n        } else {\n          window.open('https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html', '_blank');\n        }\n      }"}],"cloud":false},"source":"A","attrs":{"b0955113cf5a":{"x":{},"y":{},"label":{},"type":"bar"}},"cur_data":"b0955113cf5a","visdat":{"b0955113cf5a":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"base_url":"https://plot.ly"},"evals":["config.modeBarButtonsToAdd.0.click"],"jsHooks":[]}</script>
<!--/html_preserve-->
### 3-grams

``` r
tri_gram_tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = 3, max = 3))
dtm3 <- DocumentTermMatrix(corpus, control = list(tokenize = tri_gram_tokenizer))
top_3gram <- findMostFreqTerms(dtm3, n = 30)$`1`
top_3gram
```

    ##              fake fake fake                mother s day 
    ##                          33                          29 
    ##          none repeat scroll        repeat scroll yellow 
    ##                          25                          25 
    ## stylebackground none repeat              happy new year 
    ##                          25                          24 
    ##               new york city                 let us know 
    ##                          23                          21 
    ##      president barack obama               two years ago 
    ##                          20                          18 
    ##             valentine s day              cake cake cake 
    ##                          17                          15 
    ##              happy mother s               cinco de mayo 
    ##                          15                          14 
    ##           happy mothers day                 last year s 
    ##                          14                          14 
    ##                  new year s              new york times 
    ##                          13                          13 
    ##          martin luther king                 come see us 
    ##                          12                          11 
    ##            county sheriff s                 g protein g 
    ##                          11                          11 
    ##                 rock n roll            g carbohydrate g 
    ##                          11                          10 
    ##            sheriff s office             st louis county 
    ##                          10                          10 
    ##             three years ago         wall street journal 
    ##                          10                          10 
    ##           attorney s office             fat g saturated 
    ##                           9                           9

``` r
df_3gram <- tibble(word = names(top_3gram), freq = top_3gram)
p_3gram <- df_3gram %>% 
    ggplot(aes(x = reorder(word, -freq), y = freq, label = word)) + 
    geom_col(fill = "darksalmon") + 
    labs(x = "", y = "Frequency", title = "Distribution of top 30 trigrams") + 
    theme_light() + 
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggplotly(p_3gram, tooltip = c("freq", "word"))
```

<!--html_preserve-->

<script type="application/json" data-for="htmlwidget-e369f49c00716985bf73">{"x":{"data":[{"orientation":"v","width":[0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999,0.899999999999999],"base":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"x":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"y":[33,29,25,25,25,24,23,21,20,18,17,15,15,14,14,14,13,13,12,11,11,11,11,10,10,10,10,10,9,9],"text":["freq: 33<br />word: fake fake fake","freq: 29<br />word: mother s day","freq: 25<br />word: none repeat scroll","freq: 25<br />word: repeat scroll yellow","freq: 25<br />word: stylebackground none repeat","freq: 24<br />word: happy new year","freq: 23<br />word: new york city","freq: 21<br />word: let us know","freq: 20<br />word: president barack obama","freq: 18<br />word: two years ago","freq: 17<br />word: valentine s day","freq: 15<br />word: cake cake cake","freq: 15<br />word: happy mother s","freq: 14<br />word: cinco de mayo","freq: 14<br />word: happy mothers day","freq: 14<br />word: last year s","freq: 13<br />word: new year s","freq: 13<br />word: new york times","freq: 12<br />word: martin luther king","freq: 11<br />word: come see us","freq: 11<br />word: county sheriff s","freq: 11<br />word: g protein g","freq: 11<br />word: rock n roll","freq: 10<br />word: g carbohydrate g","freq: 10<br />word: sheriff s office","freq: 10<br />word: st louis county","freq: 10<br />word: three years ago","freq: 10<br />word: wall street journal","freq:  9<br />word: attorney s office","freq:  9<br />word: fat g saturated"],"type":"bar","marker":{"autocolorscale":false,"color":"rgba(233,150,122,1)","line":{"width":1.88976377952756,"color":"transparent"}},"showlegend":false,"xaxis":"x","yaxis":"y","hoverinfo":"text","frame":null}],"layout":{"margin":{"t":43.7625570776256,"r":7.30593607305936,"b":97.0085301519732,"l":37.2602739726027},"plot_bgcolor":"rgba(255,255,255,1)","paper_bgcolor":"rgba(255,255,255,1)","font":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"title":"Distribution of top 30 trigrams","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":17.5342465753425},"xaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[0.4,30.6],"tickmode":"array","ticktext":["fake fake fake","mother s day","none repeat scroll","repeat scroll yellow","stylebackground none repeat","happy new year","new york city","let us know","president barack obama","two years ago","valentine s day","cake cake cake","happy mother s","cinco de mayo","happy mothers day","last year s","new year s","new york times","martin luther king","come see us","county sheriff s","g protein g","rock n roll","g carbohydrate g","sheriff s office","st louis county","three years ago","wall street journal","attorney s office","fat g saturated"],"tickvals":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],"categoryorder":"array","categoryarray":["fake fake fake","mother s day","none repeat scroll","repeat scroll yellow","stylebackground none repeat","happy new year","new york city","let us know","president barack obama","two years ago","valentine s day","cake cake cake","happy mother s","cinco de mayo","happy mothers day","last year s","new year s","new york times","martin luther king","come see us","county sheriff s","g protein g","rock n roll","g carbohydrate g","sheriff s office","st louis county","three years ago","wall street journal","attorney s office","fat g saturated"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-45,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"y","title":"","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"yaxis":{"domain":[0,1],"automargin":true,"type":"linear","autorange":false,"range":[-1.65,34.65],"tickmode":"array","ticktext":["0","10","20","30"],"tickvals":[0,10,20,30],"categoryorder":"array","categoryarray":["0","10","20","30"],"nticks":null,"ticks":"outside","tickcolor":"rgba(179,179,179,1)","ticklen":3.65296803652968,"tickwidth":0.33208800332088,"showticklabels":true,"tickfont":{"color":"rgba(77,77,77,1)","family":"","size":11.689497716895},"tickangle":-0,"showline":false,"linecolor":null,"linewidth":0,"showgrid":true,"gridcolor":"rgba(222,222,222,1)","gridwidth":0.33208800332088,"zeroline":false,"anchor":"x","title":"Frequency","titlefont":{"color":"rgba(0,0,0,1)","family":"","size":14.6118721461187},"hoverformat":".2f"},"shapes":[{"type":"rect","fillcolor":"transparent","line":{"color":"rgba(179,179,179,1)","width":0.66417600664176,"linetype":"solid"},"yref":"paper","xref":"paper","x0":0,"x1":1,"y0":0,"y1":1}],"showlegend":false,"legend":{"bgcolor":"rgba(255,255,255,1)","bordercolor":"transparent","borderwidth":1.88976377952756,"font":{"color":"rgba(0,0,0,1)","family":"","size":11.689497716895}},"hovermode":"closest","barmode":"relative"},"config":{"doubleClick":"reset","modeBarButtonsToAdd":[{"name":"Collaborate","icon":{"width":1000,"ascent":500,"descent":-50,"path":"M487 375c7-10 9-23 5-36l-79-259c-3-12-11-23-22-31-11-8-22-12-35-12l-263 0c-15 0-29 5-43 15-13 10-23 23-28 37-5 13-5 25-1 37 0 0 0 3 1 7 1 5 1 8 1 11 0 2 0 4-1 6 0 3-1 5-1 6 1 2 2 4 3 6 1 2 2 4 4 6 2 3 4 5 5 7 5 7 9 16 13 26 4 10 7 19 9 26 0 2 0 5 0 9-1 4-1 6 0 8 0 2 2 5 4 8 3 3 5 5 5 7 4 6 8 15 12 26 4 11 7 19 7 26 1 1 0 4 0 9-1 4-1 7 0 8 1 2 3 5 6 8 4 4 6 6 6 7 4 5 8 13 13 24 4 11 7 20 7 28 1 1 0 4 0 7-1 3-1 6-1 7 0 2 1 4 3 6 1 1 3 4 5 6 2 3 3 5 5 6 1 2 3 5 4 9 2 3 3 7 5 10 1 3 2 6 4 10 2 4 4 7 6 9 2 3 4 5 7 7 3 2 7 3 11 3 3 0 8 0 13-1l0-1c7 2 12 2 14 2l218 0c14 0 25-5 32-16 8-10 10-23 6-37l-79-259c-7-22-13-37-20-43-7-7-19-10-37-10l-248 0c-5 0-9-2-11-5-2-3-2-7 0-12 4-13 18-20 41-20l264 0c5 0 10 2 16 5 5 3 8 6 10 11l85 282c2 5 2 10 2 17 7-3 13-7 17-13z m-304 0c-1-3-1-5 0-7 1-1 3-2 6-2l174 0c2 0 4 1 7 2 2 2 4 4 5 7l6 18c0 3 0 5-1 7-1 1-3 2-6 2l-173 0c-3 0-5-1-8-2-2-2-4-4-4-7z m-24-73c-1-3-1-5 0-7 2-2 3-2 6-2l174 0c2 0 5 0 7 2 3 2 4 4 5 7l6 18c1 2 0 5-1 6-1 2-3 3-5 3l-174 0c-3 0-5-1-7-3-3-1-4-4-5-6z"},"click":"function(gd) { \n        // is this being viewed in RStudio?\n        if (location.search == '?viewer_pane=1') {\n          alert('To learn about plotly for collaboration, visit:\\n https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html');\n        } else {\n          window.open('https://cpsievert.github.io/plotly_book/plot-ly-for-collaboration.html', '_blank');\n        }\n      }"}],"cloud":false},"source":"A","attrs":{"b095127e4862":{"x":{},"y":{},"label":{},"type":"bar"}},"cur_data":"b095127e4862","visdat":{"b095127e4862":["function (y) ","x"]},"highlight":{"on":"plotly_click","persistent":false,"dynamic":false,"selectize":false,"opacityDim":0.2,"selected":{"opacity":1},"debounce":0},"base_url":"https://plot.ly"},"evals":["config.modeBarButtonsToAdd.0.click"],"jsHooks":[]}</script>
<!--/html_preserve-->
Discussion and remarks
----------------------

The provided dataset is composed of three different documents: blog posts, news and tweets. Our aim was to understand their structure and peculiarities in order to build a text prediction model, similar to those working daily on our smartphones.
I could have chosen to use only the blog posts and news text, since usually tweets can contain many more mistakes and contractions due to the 140-letter restriction; however, this so-called *Twitter slang* has become part of the common English language, so for the sake of completeness I included the tweets dataset into the data analysis as well.
In order to provide fast but reliable predictions, I had to sample these data; 1% of the original dataset seemed to be a reasonable amount, in order to achieve fast computations while still being representative of the whole corpus. This should be enough for the purpose of this project.
Stop words were removed, so we may not be able to predict some super-common words such as "and", "or", "in" and so on. An additional cleaning step would be word stemming, but this could have restricted our already-chopped dataset a bit too much, so I chose to avoid it.

All these choices might impair the accuracy of the prediction model, but hopefully the final application will still be able to perform quite well with the given amount of data.

Future plans
------------

The n-grams plots showed that some words are way more common than some others, and from the 2- and 3-grams plots it is evident how some of these words frequently appear together. This will be exploited for the creation of the prediction algorithm, which will probably take advantage of a back-off model, where the model would first look at the most common 3-grams (or maybe also 4-grams) in order to predict the next word, if nothing is found it will look in the 2-grams model and finally it will use the single-words model.
The final prediction application will be implemented as a ShinyApp.

All the code for this report as well as for the future development of the app will be available on [this GitHub repository](https://github.com/robertopreste/datasciencecoursera/tree/master/Capstone_Project).
