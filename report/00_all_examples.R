#* Title: 00_all_examples.R
#* 
#* Code function: This script merges all the PDF's generated using the
#*                the quarto files located in the  `report` folder.
#* 
#* Creation date: August 13 2024

# 01 Initial Setup --------------------------------------------------------

## 01.01 Clean environment ------------------------------------------------
remove(list = ls())

#* Refresh environment memory
gc()

## 01.02 Load libraries ----------------------------------------------------
library(qpdf)



# 02 Merge PDF files ----------------------------------------------------

qpdf::pdf_combine(input = c("report/r_example_01.pdf",
                            "report/r_example_02.pdf",
                            "report/r_example_03.pdf",
                            "report/r_example_04.pdf",
                            "report/r_example_05.pdf",
                            "report/r_nps_function.pdf",
                            "report/py_example_01.pdf",
                            "report/py_example_02.pdf",
                            "report/py_example_03.pdf",
                            "report/py_nps_function.pdf"),
                  output = "report/00_all_examples.pdf")
