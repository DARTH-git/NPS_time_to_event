#* Title: Ex. 02 - Draw age to death from homogeneous cohort
#* 
#* Code function: 
#*    This code corresponds to the second example of the NPS manuscript.
#*    
#*    It showcases a use of the nps_nhppp method while drawing
#*    ages to death from a homogeneous cohort in 2015.
#*    
#*    The homogeneous cohort is the "Total" population, without disaggregating 
#*    it by sex.
#* 
#* Creation date: February 01 2024
#* Authors:
#* - David U. Garibay-Treviño, M.Sc.
#* - Fernando Alarid-Escudero, Ph.D.

# 01 Initial Setup --------------------------------------------------------

## 01.01 Clean environment ------------------------------------------------
remove(list = ls())

#* Refresh environment memory
gc()

## 01.02 Load libraries ----------------------------------------------------
library(dplyr)
library(ggplot2)
library(tidyr)
library(tibble)

  
# 02 Define general parameters --------------------------------------------

#´ Number of samples to draw from the life table
n_samp_life_tables <- 1e5

# Seed for reproducibility in random number generation
n_seed <- 10242022

# To print a specific number of digits in tibbles
options(pillar.sigfig = 4)

# 03 Load base data -------------------------------------------------------

#' Yearly USA data, from 2000 to 2019, 
#' Mortality rate for males, females and total
#' Obtained from The Human Mortality Database:
#' https://www.mortality.org/cgi-bin/hmd/country.php?cntr=USA&level=1
load("data/all_cause_mortality.rda")


# 04 Filter data ----------------------------------------------------------

# For homogeneous population example
df_all_cause_mortality_filt <- all_cause_mortality %>% 
  as_tibble() %>% 
  filter(Year == 2015)

# 05 Data wrangling -------------------------------------------------------

#* Following Lee & Wang (2013) - Statistical methods for survival data analysis
#* 4th ed - chapter 2: Functions of survival time
df_lifetable <- df_all_cause_mortality_filt %>% 
  dplyr::arrange(Sex, Year, Age) %>% 
  dplyr::group_by(Sex) %>% 
  dplyr::mutate(
    H_t = cumsum(Rate),        # H(t) - Cumulative hazard
    S_t = exp(-H_t),           # S(t) - Cumulative survival
    F_t = 1 - exp(-H_t),       # F(t) - Cumulative probability: 1 - S(t)
    p_t = c(F_t[1], diff(F_t)) # f(t) - Instantaneous probability
  ) %>% 
  ungroup()


# Calculate life expectancy from lifetables data
df_le_lifetable <- df_lifetable %>% 
  group_by(Sex) %>% 
  summarise(le = sum(S_t))


# Obtain life expectancy from lifetables
le_lifetable_homog <- df_le_lifetable[df_le_lifetable$Sex == "Total", ]$le


# 06 Calculate life expectancy using nps method ---------------------------

# Filter to have homogeneous population
df_lifetable_homog <- df_lifetable %>%
  filter(Sex == "Total")

# Set seed for reproducibility in random number generation
set.seed(n_seed)

#' Sample ages to death from a categorical sampling
v_cat_life_table_homog <- sample(x       = df_lifetable_homog$Age,
                                 size    = n_samp_life_tables,
                                 prob    = df_lifetable_homog$p_t,
                                 replace = TRUE)

#' Create vector of drawings following a uniform distribution
v_unif_life_table_homog <- runif(n = n_samp_life_tables, min = 0, max = 1)

# Remove seed
set.seed(NULL)

#' Add this vector to the categorical sampling outputs
v_cat_life_table_corr_homog <- v_cat_life_table_homog + v_unif_life_table_homog

#´ Life expectancy without continuous time correction
le_homog_uncorr <- mean(v_cat_life_table_homog)

#´ Life expectancy with correction
le_homog_corr <- mean(v_cat_life_table_corr_homog)


# 07 Summarize results ----------------------------------------------------

# Create dataframe with summarized results
df_summary <- tibble::tibble(
  Source             = c("Life tables - Homogeneous cohort"),
  Exact              = c(le_lifetable_homog),
  NPS                = c(le_homog_uncorr),
  NPS_continous_time = c(le_homog_corr))


# Check results table
df_summary



# 08 Plotting -------------------------------------------------------------

#' Create dataset for plotting
df_lifetable_samp <- data.frame(
  age_death = v_cat_life_table_corr_homog,
  type = "NPS Homogeneous"
)

axis_text_size    <- 14
axis_title_size   <- 14
legend_text_size  <- 14
legend_title_size <- 14
title_size        <- 14

#' Generate comparison plot (Issues with plot quality)
ggplt_lifetable_comparison_homog <- ggplot(data    = df_lifetable_samp,
                                           mapping = aes(x = age_death)) + 
  geom_histogram(mapping = aes(y = after_stat(density),
                               color = "Sample from NPS"),
                 binwidth = 1,
                 position = "identity",
                 alpha = 0.5,
                 fill = NA,
                 # To define the location of the bins
                 boundary = 0,
                 closed = "left") +
  geom_segment(data = df_lifetable_homog, 
               mapping = aes(x = Age, xend = Age + 1, 
                             y = p_t, yend = p_t,
                             color = "Lifetables"),
               linewidth = 1) +
  scale_x_continuous(breaks       = seq(0, 100, 10),
                     minor_breaks = seq(0, 100, 5)) + 
  labs(x = "Age", 
       y = "Probability of death") +
  theme_bw() + 
  scale_color_manual(name = "Type",
                     values = c("Sample from NPS" = "skyblue",
                                "Lifetables" = "black")) +
  theme(legend.position = "bottom",
        axis.text     = element_text(size = axis_text_size),
        axis.title    = element_text(size = axis_title_size),
        legend.text   = element_text(size = legend_text_size),
        legend.title  = element_text(size = legend_title_size),
        plot.title    = element_text(size = title_size - 4, hjust = 0.5),
        plot.subtitle = element_text(size = title_size - 6, hjust = 0.5),
        plot.caption  = element_text(size = title_size - 8))
