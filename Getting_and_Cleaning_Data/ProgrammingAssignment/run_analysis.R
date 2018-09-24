library(tidyverse)
library(janitor)


# Merging train and test sets ---------------------------------------------

# feature names that will be used to read the datasets
features <- read.table("UCI HAR Dataset/features.txt", col.names = c("n", "name"))

# read in train set
train_X <- read.table("UCI HAR Dataset/train/X_train.txt", col.names = features$name)
train_Y <- read.table("UCI HAR Dataset/train/y_train.txt", col.names = c("act_id"))
train_set <- bind_cols(train_X, train_Y)

# read in test set 
test_X <- read.table("UCI HAR Dataset/test/X_test.txt", col.names = features$name)
test_Y <- read.table("UCI HAR Dataset/test/y_test.txt", col.names = c("act_id"))
test_set <- bind_cols(test_X, test_Y)

# merge train and test sets
df <- bind_rows(train_set, test_set)


# Mean and std extraction -------------------------------------------------

# extract features with mean and std calculations 
df <- df %>% 
    select(contains("mean"), contains("std"), act_id)


# Join activities -------------------------------------------------------

# read in activity descriptions 
activities <- read.table("UCI HAR Dataset/activity_labels.txt", col.names = c("act_id", "act_lbl"))

# add descriptive values to activities
df <- merge(df, activities, by = "act_id")


# Finalize dataset 1 ------------------------------------------------------

# clean feature names 
df <- df %>% 
    mutate(activity = act_lbl) %>% 
    select(-act_id, -act_lbl) %>% 
    clean_names("snake")

# save this first dataset 
write_csv(df, "dataset_mean_std.csv")


# Join subjects -----------------------------------------------------------

# read in subjects data 
train_subj <- read.table("UCI HAR Dataset/train/subject_train.txt", col.names = "subject")
test_subj <- read.table("UCI HAR Dataset/test/subject_test.txt", col.names = "subject")
subjects <- bind_rows(train_subj, test_subj)

# add subjects information to the dataset 
df2 <- bind_cols(df, subjects)

# rearrange the columns 
df2 <- df2 %>% 
    select(activity, subject, everything())


# Calculate grouped mean --------------------------------------------------

# calculate the average of each variable for each activity and each subject
df_means <- df2 %>% 
    group_by(activity, subject) %>% 
    summarise_all(mean, na.rm = T)


# Finalize dataset 2 ------------------------------------------------------

# save this second dataset
write.table(df_means, "dataset_grouped_means.txt", row.names = FALSE)


