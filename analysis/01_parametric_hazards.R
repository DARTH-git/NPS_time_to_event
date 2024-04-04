#* Title: Ex. 01 - Expected time to event from Parametric hazards
#* 
#* Code function: 
#*    This code corresponds to the first example of the NPS manuscript.
#*    
#*    It showcases a use of the nps method drawing
#*    times to event and comparing its results with the next parametric 
#*    distributions:
#*    - Exponential,
#*    - Gamma, and
#*    - Log-normal
#* 
#* Creation date: February 01 2024
#* Authors:
#* - David U. Garibay-Treviño, M.Sc.
#* - Hawre Jalal, M.D., Ph.D.
#* - Fernando Alarid-Escudero, Ph.D.

# 01 Initial Setup --------------------------------------------------------

## 01.01 Clean environment ------------------------------------------------
remove(list = ls())

#* Refresh environment memory
gc()

## 01.02 Load libraries ----------------------------------------------------
library(dplyr)
library(ggplot2)
library(flexsurv)
library(tidyr)

source("R/summary_functions.R")


# 02 Define general parameters --------------------------------------------

#´ Number of samples to draw from the life table
n_samp_life_tables <- 1e5

#' Numberof samples, by sex, to draw from the life table
n_samp_by_sex <- 1e5

# Sample size for every sampling iteration
n_samples  <- 1e4

# Number of times to repeat the sampling
n_sim_reps <- 1e3

# Seed for reproducibility in random number generation
n_seed <- 10242022


# 03 Define required functions --------------------------------------------

# Calculate expected value using NPS method
calc_ev_nps <- function(n_samples, v_probs){
  
  # Sample times to event
  v_time_to_event_rates_cat <- sample(size    = n_samples, 
                                      x       = 0:150, 
                                      prob    = v_probs, 
                                      replace = TRUE)
  
  return(mean(v_time_to_event_rates_cat))
}

# Calculate expected value using NPS approach and continuous time approximation
calc_ev_nps_corr <- function(n_samples, v_probs){
  
  # Sample times to event
  v_time_to_event_rates_cat <- sample(size    = n_samples, 
                                      x       = 0:150, 
                                      prob    = v_probs, 
                                      replace = TRUE)
  
  # Generate a random number following a unifrom distribution
  v_unif <- runif(n_samples)
  
  # Add random number
  v_time_to_event_rates_cat_unif <- v_time_to_event_rates_cat + v_unif
  
  return(mean(v_time_to_event_rates_cat_unif))
}


# 07 Calculate expected values from distributions -------------------------


## 07.01 Exponential distribution ------------------------------------------

# Define distribution parameters
par_exp_rate     <- 0.1

ev_exp           <- 1/par_exp_rate # Analytical expected value
var_exp          <- ev_exp^2       # Analytical variance

# Get instantaneous probability of ocurrence
v_prob_exp_rates <- pexp(q = 1:151, rate = par_exp_rate) -
  pexp(q = 0:150, rate = par_exp_rate)


# Set seed for reproducibility in random number generation
set.seed(n_seed)

# Simulations using the nps method multiple times
ev_exp_uncorr <- mean(replicate(n_sim_reps,
                                expr = calc_ev_nps(n_samples = n_samples,
                                                   v_probs = v_prob_exp_rates)))

# Simulations using the nps method, adding continuous time approximation
ev_exp_corr <- mean(replicate(n_sim_reps,
                              expr = calc_ev_nps_corr(n_samples = n_samples,
                                                      v_probs   = v_prob_exp_rates)))

# Using general function
v_sim_nps_out_exp <- calc_stats_nps_corr(n_reps      = n_sim_reps, 
                                         n_samples   = n_samples, 
                                         v_time_int  = 0:150, 
                                         v_probs     = v_prob_exp_rates,
                                         alpha_level = 0.05, 
                                         true_ev     = ev_exp, 
                                         true_var    = var_exp)

# Remove seed
set.seed(NULL)


## 07.02 Gamma distribution ------------------------------------------------

# Define distribution parameters
par_gamma_shape <- 4
par_gamma_rate  <- 0.1

ev_gamma  <- par_gamma_shape/par_gamma_rate     # Analytical expected value
var_gamma <- par_gamma_shape/(par_gamma_rate^2) # Analytical variance

# Get instantaneous probability of ocurrence
v_prob_gamma_rates <- 
  pgamma(q = 1:151, shape = par_gamma_shape, rate = par_gamma_rate) - 
  pgamma(q = 0:150, shape = par_gamma_shape, rate = par_gamma_rate)


# Set seed for reproducibility in random number generation
set.seed(n_seed)

# Simulations using the nps method multiple times
ev_gamma_uncorr <- mean(replicate(n_sim_reps, 
                                  expr = calc_ev_nps(n_samples = n_samples, 
                                                     v_probs   = v_prob_gamma_rates)))

# Simulations using the nps method, adding continuous time approximation
ev_gamma_corr <- mean(replicate(n_sim_reps, 
                                expr = calc_ev_nps_corr(n_samples = n_samples, 
                                                        v_probs   = v_prob_gamma_rates)))
# Using general function
v_sim_nps_out_gamma <- calc_stats_nps_corr(n_reps      = n_sim_reps, 
                                           n_samples   = n_samples, 
                                           v_time_int  = 0:150, 
                                           v_probs     = v_prob_gamma_rates,
                                           alpha_level = 0.05, 
                                           true_ev     = ev_gamma, 
                                           true_var    = var_gamma)

# Remove seed
set.seed(NULL)


## 07.03 Log-normal distribution -------------------------------------------


# Define distribution parameters
par_lnorm_meanlog <- 3.5 
par_lnorm_sdlog   <- 0.15

# Analytical expected value
ev_lnorm  <- exp(par_lnorm_meanlog + ((par_lnorm_sdlog^2)/2))
# Analytical variance
var_lnorm <- exp(2*par_lnorm_meanlog + (par_lnorm_sdlog^2))*(exp(par_lnorm_sdlog^2) - 1)

# Get instantaneous probability of ocurrence
v_prob_lnorm_rates <- 
  plnorm(q = 1:151, meanlog = par_lnorm_meanlog, sdlog = par_lnorm_sdlog) - 
  plnorm(q = 0:150, meanlog = par_lnorm_meanlog, sdlog = par_lnorm_sdlog)

# Set seed for reproducibility in random number generation
set.seed(n_seed)

# Simulations using the nps method multiple times
ev_lnorm_uncorr <- mean(replicate(n_sim_reps,
                                  expr = calc_ev_nps(n_samples = n_samples,
                                                     v_probs   = v_prob_lnorm_rates)))

# Simulations using the nps method, adding continuous time approximation
ev_lnorm_corr <- mean(replicate(n_sim_reps, 
                                expr = calc_ev_nps_corr(n_samples = n_samples, 
                                                        v_probs   = v_prob_lnorm_rates)))

# Using general function
v_sim_nps_out_lnorm <- calc_stats_nps_corr(n_reps      = n_sim_reps, 
                                           n_samples   = n_samples, 
                                           v_time_int  = 0:150, 
                                           v_probs     = v_prob_lnorm_rates,
                                           alpha_level = 0.05, 
                                           true_ev     = ev_lnorm, 
                                           true_var    = var_lnorm)

# Remove seed
set.seed(NULL)



# 08 Summarize results ----------------------------------------------------

# Create dataframe with summarized results
df_summary <- tibble::tibble(
  distribution       = c("Exponential", "Gamma", "Log-normal"),
  analytical_value   = c(ev_exp, ev_gamma, ev_lnorm),
  NPS                = c(ev_exp_uncorr, ev_gamma_uncorr, ev_lnorm_uncorr),
  NPS_continous_time = c(ev_exp_corr, ev_gamma_corr, ev_lnorm_corr))


# Check results table
df_summary
