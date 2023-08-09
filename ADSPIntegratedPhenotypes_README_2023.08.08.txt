# Generate an Integrated Phenotype File for an ADSP Case/Control Analysis

The purpose of this script is to provide approved users of the Alzheimer’s Disease Sequencing Project (ADSP) dataset (ng00067) with a starting point for combining and using sample and phenotype information to generate a genetically unique list of whole genome samples to use in an Alzheimer’s Disease case/control analysis. The script uses phenotype files (case-control, family-based, and ADNI), the Sample Manifest file, and Pairwise IBD Summary file, all released within the ADSP dataset (ng00067). The PSP phenotype file is not used by default because the PSP samples are not included in the 36k WGS recommended analysis list. These files will be combined into one output file that will contain a list of genetically unique samples with sample and phenotype information for each sampleID. 

 
## Setup Instructions 

Before running the script, please ensure that you have downloaded the following libraries: readxl, dplyr, and stringr. These libraries are required for the script to function properly. 

Additionally, specify the file names and locations for each of the phenotype files. The default code assumes that the files are stored in a folder named "data" within the same directory as this script. Adjust the file paths accordingly if your files are located in a different directory.  

The default file list uses the “ALL” consent files. If you do not have access to these files (if you are not approved for all consent levels), then please combine your individual consent-level files for each file type into one and use that in place of the “ALL” files below. 


The default file list that will be utilized is (released in ng00067.v10): 

data/ADSPCaseControlPhenotypes_DS_2022.08.18.v2_ALL.csv 

data/ADSPFamilyBasedPhenotypes_DS_2022.08.18.v2_ALL.csv 

data/ADNIPhenotypes_DS_2022.08.18.v2_ALL.csv 

data/SampleManifest_DS_2022.08.18.v2_ALL.csv 

data/gcad.r4.wgs.36361.2023.06.06.pairwise_IBD.summary.xlsx 


## Script Execution Steps 

The script performs the following steps:
Reads the phenotype files (case/control, family-based, and ADNI), the sample to subject mapping file (Sample Manifest), and the IBD Summary R4 Recommendation list into tables. 

Harmonizes the phenotypes across all files. Adds the following harmonized phenotype values to each set of phenotypes: 
	
 	DX_harmonized (Diangosis): 0=Control, 1=AD Case 
 	
  	Age_harmonized: AD cases use onset age and controls use age at last visit 
  	
   	other_diagnosis_flag: 0/1 (True/False) indicates if a subject has an "other diagnosis" (if the subject is not considered a case or control but does have a diagnosis).
   		For case/control or family-based subjects, there will be a comment in the Comments field with more details on diagnosis. For adni subjects, the subject was classified as MCI. 

Drops the phenotype replicates present in both the case/control and family-based studies, keeping only the family-based samples. 

The "Family filter" step (Step 3) is optional and can be removed if one sample per family is not required. 
	If used, this section groups the data by families and selects one AD case subject per family to include in the sample list. 

Filters the sample list to include only genetically unique samples from the WGS dataset using the current Identity by Descent (IBD) recommendation list. Note: it will not include PSP or CBD 
samples. 

Combines the sample and phenotype information into a single table, including harmonized phenotype data for each sample. 

Selects the desired output columns and writes the final table to a file named "ADSP_36k_samples_pheno_output.csv" in comma-separated values (CSV) format. 

 
## Variables in Output File (ADSPIntegratedPhenotypes_DS_2023.08.08.csv)

SampleID: ADSP Sample ID - the unique identifier assigned to each sample in the dataset 

SUBJID: ADSP Subject ID associated with the sample 

Cohort: Name of cohort from which the participant was recruited 

BODY_SITE: The body site from which the sample was collected 

ANALYTE_TYPE: The type of analyte (e.g., DNA, RNA) extracted from the sample 

Sequencing_Center: The center responsible for conducting the sequencing 

Sequencing_Platform: The sequencing platform used for sample analysis 

SAMPLE_USE: Indicates the usage of the sample (e.g., WGS) 

Technical_Replicate: Indicates whether the sample is a technical replicate 

Study_DSS: The NIAGADS accession number for the study in which the sample is included 

Sample_Set: DSS accession number of the sample set or group to which the sample belongs 

Sex: The biological sex of the participant associated with the sample

Age_harmonized: The harmonized age of the participant - age at onset for cases, age at last exam for controls 

Age_baseline: The participant's age when first examined/entered ADSP study 

APOE_reported: The reported APOE genotype of the participant 

APOE_WGS: The APOE genotype derived from whole-genome sequencing (WGS) data 

Braak: The Braak stage from autopsy 

Race: The race or ethnicity of the participant (uses NIH Racial Categories) 

Ethnicity: The ethnicity of the participant (uses Hispanic or Latino/Not Hispanic or Latino) 

DX_harmonized: The harmonized diagnosis for Alzheimer's disease case/control analysis. - 0: Control - 1: AD Case 

other_diagnosis_flag: A flag indicating if the participant has a specified diagnosis other than AD (True/False) 

Comments: Additional notes about AD status conversions, updates, corrections (includes version when comment was made) 

Flag: Additional flag that identifies important considerations for using subject phenotypes 

 
These output variables provide a comprehensive set of information that can be used for case/control analysis and further investigations in Alzheimer's disease research. More details on these variables and their values can be found in the Data Dictionary for the output file ADSPIntegratedPhenotypes_DD_2023.08.08.xlsx
