#* Title: merge_pdf.R
#* 
#* Code function: This script merges all the PDF outputs from the 
#*                examples provided in the 'A Fast Nonparametric Sampling (NPS) Method for Time-to-Event in 
#*                Individual-Level Simulation Models.' manuscript
#* 
#* Creation date: July 02 2024

# 01 Initial Setup --------------------------------------------------------

## 01.01 Clean environment ------------------------------------------------
remove(list = ls())

#* Refresh environment memory
gc()

## 01.02 Load libraries ----------------------------------------------------
library(qpdf)



# 02 General parameters -------------------------------------------------

# Define the paths of the PDFs to merge
v_pdf_paths <- c("report/r_example_01.pdf",
                 "report/r_example_02.pdf",
                 "report/r_example_03.pdf",
                 "report/r_example_04.pdf",
                 "report/r_example_05.pdf",
                 "report/r_nps_function.pdf",
                 "report/py_example_01.pdf",
                 "report/py_example_02.pdf",
                 "report/py_example_03.pdf",
                 "report/py_nps_function.pdf")


# 03 Merge PDFs ---------------------------------------------------------

# Merge and save the PDFs into the defined path
qpdf::pdf_combine(input = v_pdf_paths,
                  output = "report/00_all_examples.pdf")
