# CodeBook - Getting and Cleaning Data Course Project  

Roberto Preste  

___ 

## Disclaimer  

In a couple of places during the analysis, I used some tricks offered by the `tidyverse` and `janitor` packages to perform some tasks quicker. Particularly, the `janitor::clean_names()` function is great and I highly recommend it.  

___ 

## Data  

From the original [UCI dataset](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones) description:  

> The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz. The experiments have been video-recorded to label the data manually. The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data.  
>  
> The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain.  

___ 

## Variables  

Apart for the features already present in the original dataset, some more variables are computed during this analysis and included in the resulting files.  

### dataset_mean_std.csv  

| variable | description |  
| --- | --- |  
| `activity` | Activity label |  

### dataset_grouped_means.txt  

| variable | description |  
| --- | --- |  
| `activity` | Activity label |  
| `subject` | Subject id |  

___ 

## Analysis  

### Merging train and test sets  

First of all I read the feature names from the `features.txt` file; these are then used to read the `X_train.txt` and `X_test.txt` datasets with proper column names. These two files are merged with `y_train.txt` and `y_test.txt` respectively, and then the two datasets are merged together using `dplyr::bind_rows()`.  

### Mean and std extraction  

In order to extract only the features reporting information about mean and standard deviation of measurements, I took advantage of the `tidyselect::contains()` function, which can be used to select features containing a specific string in their name, in this case `"mean"` and `"std"`.  

### Join activities  

Activities in the dataset are encoded by an integer number in the `act_id` variable, so I loaded the `activity_labels.txt` file, which maps each integer with a descriptive activity name, and joined it with the dataset. As such, a new column was added containing the proper activity description for each measurement.  

### Finalize dataset 1  

The newly added column was renamed as `activity`, and features in the dataset were rearranged and cleaned using the `janitor::clean_names()` function, to replace dots with underscores and convert every feature name to snake_case.  
The results are saved in a file called `dataset_mean_std.csv`.  

### Join subjects  

I read the `subject_train.txt` and `subject_test.txt` files, merged them together row-wise and then added these data as a new column `subject` to the previous dataset. The resulting dataset had its features rearranged in order to have the `activity` and `subject` upfront.  

### Calculate grouped mean  

I grouped the data by `activity` and `subject`, and applied the mean to each other feature using the `dplyr::summarise_all()`, which functions like `dplyr::summarise()` but performs the given operation on all (non-grouping) variables.  

### Finalize dataset 2  

The final dataset was saved to a file called `dataset_grouped_means.txt`.  

