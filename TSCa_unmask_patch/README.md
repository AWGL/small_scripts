# TruSightCancer gene unmasking patch

## Introduction

As part of the old TruSightCancer pipeline, a panel was applied in the pipeline and only variants within that panel were outputted. 
This script re-runs the last step of the pipeline in order to apply a different panel.

## Instructions

- Make a copy of the `<sample>.variables` and the `<sample>_VariantReport.txt` files and change their filenames so that they are obviously the old version (e.g. append with .old)
- Open the original copy of the `<sample>.variables` file
- Find the variable called SampleProjects, which has a list of genes (e.g. `SampleProjects=( "TSC1" "TSC2" )`)
- Add the extra genes to be included within the brackets
  - All genes should be seperated by a space
  - Each gene should be enclosed in double speechmarks
  - e.g. to add BRCA 1&2 to the example above, the SampleProjects variable should be changed to `SampleProjects=( "TSC1" "TSC2" "BRCA1" "BRCA2" )`
- If not already there, `cd` into the sample folder (i.e. the one with the `<sample>.variables` file)
- Run the script `bash /data/dignostics/scripts/TSCa_unmask_patch.sh`
- Check that a new `<sample>_VariantReport.txt` file has been made and it has the new genes included
