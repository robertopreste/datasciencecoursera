# Getting and Cleaning Data Course Project  

Roberto Preste  

___

## Description  

My submission for the peer-graded assignment from Getting and Cleaning Data ([Coursera](https://www.coursera.org/learn/data-cleaning/)).  
Original dataset come from the [Human Activity Recognition Using Smartphones](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones) dataset, by UCI Machine Learning Repository.  

___ 

## Goal  

From the assignment instructions:  

> You should create one R script called run_analysis.R that does the following.

> 1. Merges the training and the test sets to create one data set.
> 2. Extracts only the measurements on the mean and standard deviation for each measurement.
> 3. Uses descriptive activity names to name the activities in the data set
> 4. Appropriately labels the data set with descriptive variable names.
> 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.  

___ 

## Reproducibility  

Results can be reproduced easily by downloading and extracting the data in the working directory, and placing the script `run_analysis.R` in the same working directory.  
A simple call to  
```Rscript run_analysis.R```  
will produce two files in the working directory:  

* `dataset_mean_std.csv`, which contains the mean and std calculations for each measurement  
* `dataset_grouped_means.txt`, which contains the mean of each measurement for each activity and subject  

The file `CodeBook.md` contains detailed information about the different steps performed in the script.  


