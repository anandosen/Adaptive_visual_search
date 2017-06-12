This package implements the adaptive visual search observer to determine whether a prostate SPECT image has a lesion and if so to localize its position. It is implemented using IDL and linux shell scripts. A brief description of the main scripts are given below.

1. adaptive_vs_main.csh is the main cshell script that combines all other shell scripts and IDL scripts. The main task of this script is to create list of files and other parameters and for use by the IDL scripts. Refer to in-script comments for details. The final output file from this script is lroc_areas.txt, which stores the performance of the adaptive visual search for each parameter set.

2. comb_cont.csh is a script for generating filenames with the variable contrasts. This script in turn calls the script vary_contrast.

3. getAvgTgt_ms.csh generates the template image from which all other features are created. The template file is named targ_file (This file was created previously by Prof. Howard Gifford).

4. make_feat_list.pro is an IDL script that creates a table of features for a set of image files. These table are stored in feat_file (raw) and norm_feat_file (normalized). Each row in these tables correspond to a suspicious lesion location. The columns in these tables are truth about the presence of lesion, human indication of lesion (always 0 as it wasn't used), value of search feature, four columns for the values of the four analysis features and finally the image file number. Some aggregate feature statistics are stored in the file delta.

5. training.pro is an IDL script to train on the feature combinations and identify the best possible combinations (could be multiple) for a particular image set. The best combinations are stored in the file max_feat_sets in form of a four-column table where each row is a feature combination. Each entry is a binary value indicating whether the specific feature was used in the combination.

6. testing.pro is an IDL script that uses the best feature combinations on a set of test images to identify and localize lesions. For each feature combination a file featset_{number} is generated which is further used for performance evaluation. The first column is the filename followed by a rating statistic, presence/absence of lesion and an identically one fith column (required for the performance evaluation software we are using). The last four columns of these files contain the x and y coordinates of the true and estimated lesion location.

7. avg_lroc.pro is an IDL script for calculating the average performance (area under the localization ROC curve) in case there are multiple best-performing feature combinations during the training process. The LROC area is initially computed using the C-executable empiricalLROC.

8. convolve.pro is an IDL function for computing the convolution and cross correlation of a template-image with and image (This file was created previously by Prof. Howard Gifford).

9. _tmptest.pro is a temporary IDL file for running other IDL scripts.

Questions and Comments
Dr. Anando Sen
anandosen@gmail.com