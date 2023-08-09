
# This script is designed to provide users with an output file containing a list of genetically unique samples with harmonzied phenotypes for each sample.
# By default, the script will use the most current list of released ADSP WGS files (ng00067.v10), filter the sample list
#to include the recommended list of genetically unique samples in the WGS 36k, and pull phenotype values for each sample.
# Please read the setup instructions below and then run the script:


####################
# SETUP INSTRUCTIONS
# The following libraries are used in this script, please download them before running
#Note: if you cannot use dplyr, remove step 3 below (it is optional)

library("readxl")
library(dplyr)
library(stringr)


# Please include the file names and locations for each of the files below
# Default code uses the most recent files for the 36k (ng00067.v10). It also uses the ALL consent version of each file. If you are not approved for all consents, merge the by-consent files for for each file type and replace the file names below with your merged file.
# To use the defaults, place each file in a folder called "data" in the same directory as this script and set working directory to source file location

cc_pheno_file = "data/ADSPCaseControlPhenotypes_DS_2022.08.18.v2_ALL.csv"
fam_pheno_file = "data/ADSPFamilyBasedPhenotypes_DS_2022.08.18.v2_ALL.csv"
adni_pheno_file = "data/ADNIPhenotypes_DS_2022.08.18.v2_ALL.csv"

sample_manifest_file = "data/SampleManifest_DS_2022.08.18.v2_ALL.csv"

ibd_pair_rec_file = "data/gcad.r4.wgs.36361.2023.06.06.pairwise_IBD.summary.xlsx"




####################
# 0. Read data files
# This code will read each of the files listed above and store them as tables


# Case/Control phenotypes
d.cc= read.csv(cc_pheno_file, header=T, as.is=T, sep=",", stringsAsFactors=FALSE)


# Family study phenotypes
d.fs= read.csv(fam_pheno_file, header=T, as.is=T, sep=",", stringsAsFactors=FALSE)


# ADNI phenotypes
d.adni= read.csv(adni_pheno_file, header=T, as.is=T,sep=",",stringsAsFactors=FALSE)


# sample to subject mapping
sample.manifest = read.csv(sample_manifest_file, header=T, as.is=T,sep=",",stringsAsFactors=FALSE)


# IBD pairs and recommended keep/drop list (for genetically unique samples)
ibd_keep_drop = read_excel(ibd_pair_rec_file, sheet="R4WGS_recommendation_list", col_names=TRUE, col_types="text")



####################
# 1. Harmonize phenotypes into a standard format across all phenotype files
# This code will harmonize the phenotypes in order to combine them into one table
# Define DX (diagnosis) and Age
# DX_harmonized (AD case/control diagnosis): 0=Control, 1=AD Case
# Age_harmonized: AD cases use onset age and controls use age at last visit
# other_diagnosis_flag: 0/1 (True/False) indicator for if a subject has an "other diagnosis" (not case or control)
  #For case/control or family-based subjects, there will be a comment in the Comments field with more details on diagnosis
  #For adni subjects, the subject was classified as MCI

# Case/Control
d.cc$Age_harmonized = NA
d.cc$DX_harmonized  = d.cc$AD
d.cc$Age_harmonized = d.cc$Age
d.cc$other_diagnosis_flag = 0

d.cc$other_diagnosis_flag[str_detect(d.cc$Comments,"Diagnosis: ")]=1

d.cc$FamID = NA


# Family
d.fs$Age_harmonized = NA
d.fs$DX_harmonized  = NA
d.fs$Age_harmonized = d.fs$Age
d.fs$other_diagnosis_flag = 0

d.fs$DX_harmonized[which(d.fs$AD%in%1:3)]=1 # AD
d.fs$DX_harmonized[which(d.fs$AD==0)]=0 # Control

d.fs$other_diagnosis_flag[str_detect(d.fs$Comments,"Diagnosis: ")]=1
d.fs$other_diagnosis_flag[which(d.fs$AD==5)]=1


# ADNI
d.adni$Age_harmonized = NA
d.adni$DX_harmonized  = NA
d.adni$other_diagnosis_flag = 0

d.adni$DX_harmonized[which(d.adni$AD_last_visit == 1 & d.adni$MCI_last_visit == 0)]=1 # AD
d.adni$DX_harmonized[which(d.adni$AD_last_visit == 0 & d.adni$MCI_last_visit == 0)]=0 # Control

d.adni$Age_harmonized[which(d.adni$DX_harmonized==1)] = d.adni$Age_AD_onset[which(d.adni$DX_harmonized==1)] # Age for case: age at onset
d.adni$Age_harmonized[which(d.adni$DX_harmonized==0)] = d.adni$Age_current[which(d.adni $DX_harmonized==0)] # Age for controls: current age

d.adni$other_diagnosis_flag[which(d.adni$AD_last_visit == 0 & d.adni$MCI_last_visit == 1)]=1 #MCI

d.adni$FamID = NA



####################
# 2. Drop the WGS phenotype replicates (who have phenotypes in both family and case-control studies) 
#    Rule: Keep the one in family study

n=length(intersect(d.cc$SUBJID, d.fs$SUBJID))
print(paste(c("Step 2: subjects to drop: ",n),collapse=""))

if (length(n)>0) {
  d.cc = d.cc[-which(d.cc$SUBJID %in% d.fs$SUBJID),]
}


####################
# 3. Family filter (only 1 sample per family)
# This section is optional - use if you want only one sample per famiy (otherwise, remove all of step 3)
# It groups data by family, cases first, and selects the first case in each family to include

one_per_fam <- 
  d.fs %>%
  group_by(FamID) %>%
  arrange(desc(DX_harmonized)) %>%
  filter(row_number()==1)


d.fs = one_per_fam


####################
# 4. Filter sample list for WGS unique samples
# By default, the code will filter samples to include WGS samples that are genetically unique using the current IBD recommendation list. It does not include PSP or CBD samples.

# subset to WGS
sample.manifest.wgs = sample.manifest[sample.manifest$SAMPLE_USE %in% c("WGS"),]
#load the recommendation keep/drop list from the IBD review
ibd_droplist = ibd_keep_drop$SampleID[ibd_keep_drop$ADSP_Recommendation == "Drop"]
#filter to include the recommended list of genetically unique WGS samples
sample.manifest.wgs.rec = sample.manifest.wgs[!(sample.manifest.wgs$SampleID %in% ibd_droplist),]



####################
# 5. Combine sample and phenotype information
# This code will create a table with sample information for the WGS genetically identical samples and include harmonzied phenotype data for each sample

commonnames=names(d.cc);
commonnames=commonnames[commonnames%in%names(d.fs)];
commonnames=commonnames[commonnames%in%names(d.adni)];

pheno_combine=rbind(d.cc[commonnames],d.fs[commonnames],d.adni[commonnames])

sample_pheno_merge = merge(x =sample.manifest.wgs.rec, y = pheno_combine, by = "SUBJID")


####################
# 6. Choose output columns and write final table to file
# For definitions of each variable, please see the data dictionary for the output file "ADSPIntegratedPhenotypes_DD_2023.08.08.xlsx"

sample_pheno_output = sample_pheno_merge[, c("SampleID", "SUBJID", "Cohort", "BODY_SITE", "ANALYTE_TYPE", "Sequencing_Center", "Sequencing_Platform", "SAMPLE_USE", "Technical_Replicate", "Study_DSS", "Sample_Set", "Sex", "Age_harmonized", "Age_baseline", "APOE_reported", "APOE_WGS", "Braak", "Race", "Ethnicity", "DX_harmonized", "other_diagnosis_flag", "Comments", "Flag")]

write.csv(sample_pheno_output, file="ADSPIntegratedPhenotypes_DS_2023.08.08.csv", row.names = FALSE)



