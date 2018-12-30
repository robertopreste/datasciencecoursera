

getObsTrigs <- function(bigPre, trigrams) {
    trigs.winA <- data.frame(ngrams = vector(mode = "character", length = 0),
                             freq = vector(mode = "integer", length = 0))
    regex <- sprintf("%s%s%s", "^", bigPre, "_")
    trigram_indices <- grep(regex, trigrams$ngram)
    if (length(trigram_indices) > 0) {
        trigs.winA <- trigrams[trigram_indices, ]
    }
    
    return(trigs.winA)
}

getUnobsTrigTails <- function(obsTrigs, unigs) {
    obs_trig_tails <- str_split_fixed(obsTrigs, "_", 3)[, 3]
    unobs_trig_tails <- unigs[!(unigs$ngram %in% obs_trig_tails), ]$ngram
    
    return(unobs_trig_tails)
}

getBoBigrams <- function(bigPre, unobsTrigTails) {
    w_i_minus1 <- str_split(bigPre, "_")[[1]][2]
    boBigrams <- paste(w_i_minus1, unobsTrigTails, sep = "_")
    
    return(boBigrams)
}

getObsBoBigrams <- function(bigPre, unobsTrigTails, bigrs) {
    boBigrams <- getBoBigrams(bigPre, unobsTrigTails)
    obs_bo_bigrams <- bigrs[bigrs$ngram %in% boBigrams, ]

    return(obs_bo_bigrams)
}

getUnobsBoBigrams <- function(bigPre, unobsTrigTails, obsBoBigram) {
    boBigrams <- getBoBigrams(bigPre, unobsTrigTails)
    unobs_bigs <- boBigrams[!(boBigrams %in% obsBoBigram$ngram)]
    
    return(unobs_bigs)
}

getObsBigProbs <- function(obsBoBigrams, unigs, bigDisc=0.5) {
    first_words <- str_split_fixed(obsBoBigrams$ngram, "_", 2)[, 1]
    first_word_freqs <- unigs[unigs$ngram %in% first_words, ]
    obsBigProbs <- (obsBoBigrams$freq - bigDisc) / first_word_freqs$freq
    obsBigProbs <- data.frame(ngram = obsBoBigrams$ngram, 
                              prob = obsBigProbs)
    
    return(obsBigProbs)
}

getAlphaBigram <- function(unigram, bigrams, bigDisc=0.5) {
    regex <- sprintf("%s%s%s", "^", unigram$ngram[1], "_")
    bigsThatStartWithUnig <- bigrams[grep(regex, bigrams$ngram),]
    if (nrow(bigsThatStartWithUnig) < 1) {
        return(0)
    }
    alphaBi <- 1 - (sum(bigsThatStartWithUnig$freq - bigDisc) / unigram$freq)
    
    return(alphaBi)
}

getQboUnobsBigrams <- function(unobsBoBigrams, unigs, alphaBig) {
    qboUnobsBigs <- str_split_fixed(unobsBoBigrams, "_", 2)[, 2]
    w_in_Aw_iminus1 <- unigs[!(unigs$ngram %in% qboUnobsBigs), ]
    qboUnobsBigs <- unigs[unigs$ngram %in% qboUnobsBigs, ]
    denom <- sum(qboUnobsBigs$freq)
    qboUnobsBigs <- data.frame(ngram = unobsBoBigrams,
                               prob = (alphaBig * qboUnobsBigs$freq / denom))
    
    return(qboUnobsBigs)
}

getObsTriProbs <- function(obsTrigs, bigrs, bigPre, triDisc=0.5) {
    if (nrow(obsTrigs) < 1) {
        return(NULL)
    }
    obsCount <- filter(bigrs, ngram == bigPre)$freq[1]
    obsTrigProbs <- mutate(obsTrigs, freq = ((freq - triDisc) / obsCount))
    colnames(obsTrigProbs) <- c("ngram", "prob")
    
    return(obsTrigProbs)
}

getAlphaTrigram <- function(obsTrigs, bigram, triDisc=0.5) {
    if (nrow(obsTrigs) < 1) {
        return(1)
    }
    alphaTri <- 1 - sum((obsTrigs$freq - triDisc) / bigram$freq[1])
    
    return(alphaTri)
}

getUnobsTriProbs <- function(bigPre, qboObsBigrams, qboUnobsBigrams, alphaTrig) {
    qboBigrams <- rbind(qboObsBigrams, qboUnobsBigrams)
    qboBigrams <- qboBigrams[order(-qboBigrams$prob), ]
    sumQboBigs <- sum(qboBigrams$prob)
    first_bigPre_word <- str_split(bigPre, "_")[[1]][1]
    unobsTrigNgrams <- paste(first_bigPre_word, qboBigrams$ngram, sep = "_")
    unobsTrigProbs <- alphaTrig * qboBigrams$prob / sumQboBigs
    unobsTrigDf <- data.frame(ngram = unobsTrigNgrams, 
                              prob = unobsTrigProbs)
    
    return(unobsTrigDf)
}

getPrediction <- function(qbo_trigs) {
    prediction <- str_split(qbo_trigs$ngram[1], "_")[[1]][3]
    result <- c(prediction, qbo_trigs$prob[1])
    
    return(result)
}

getPredictions <- function(qbo_trigs) {
    preds <- head(qbo_trigs, n = 5)
    words <- sapply(preds$ngram, str_split, pattern = "_")
    preds$ngram <- sapply(words, tail, n = 1)

    return(preds)
}
