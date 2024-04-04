#* Title:  Ex. 05 - Draw time to event from hazards with time-dependent 
#*         covariates following random paths
#* 
#* Code function: 
#*    This code corresponds to the fifth example of the NPS manuscript.
#*    
#*    It showcases a use of the nps method drawing times to event from 
#*    parametric baseline hazards with time-dependent covariates following
#*    random paths. 
#*    The baseline hazards follow the next distributions:
#*    - Weibull
#* 
#* Creation date: February 02 2024
#* Authors:
#* - David U. Garibay-Treviño, M.Sc.
#* - Hawre Jalal, M.D., Ph.D.
#* - Fernando Alarid-Escudero, Ph.D.


# 01 Initial Setup --------------------------------------------------------

## 01.01 Clean environment ------------------------------------------------
remove(list = ls())

#* Refresh environment memory
gc()

# 01.02 Load libraries ----------------------------------------------------
library(dplyr)
library(ggplot2)
library(tidyr)
library(tibble)
library(data.table)
library(flexsurv)
library(LambertW)
library(reshape2)

# Load function to implement multivariate categorical sampling
source(file = "R/nps_nhppp.R")

# 02 Define general parameters --------------------------------------------

# Parameters for time-varying covariates
alpha_0 <- 0
alpha_1 <- 1
beta    <- log(1.005) # When beta <- 0 the time-varying covariate is deactivated


# Define parameters for the Weibull baseline hazard
n_weib_shape <- 1.3
n_weib_scale <- 30.1

n_ind    <-  1000 # Number of simulated individuals
n_cycles <-  100  # Number of cycles
ourDrift <-  0.5

# Seed for reproducibility in random number generation
n_seed <- 10242022

# 03 Define required functions --------------------------------------------


# Define random path function
create_time_varying_covariate <- function(n_ind    = 100,
                                          n_cycles = 100,
                                          ourDrift = 0.005){
  
  m_random_paths <- matrix(nrow = n_ind, ncol = n_cycles)
  m_random_paths[, 1] <- 1 
  
  for (cycle in 2:n_cycles) {
    
    v_next_step = rnorm(n = n_ind, mean = 0, sd = ourDrift) 
    
    m_random_paths[, cycle] <- round(pmax(m_random_paths[, cycle - 1] + v_next_step, 0))
  }
  
  dtb_paths_individuals <- as.data.table(reshape2::melt(data       = m_random_paths, 
                                                        varnames   = c("id", "Time"), 
                                                        value.name = "Covariate"))
  setorder(dtb_paths_individuals, id, Time)
  
  return(dtb_paths_individuals)
}

## Function to apply the time-varying covariate to a baseline hazard
compute_time_varying_hazard_linear_3 <- function(hazard0, 
                                                 alpha_0,
                                                 alpha_1,
                                                 beta, 
                                                 time_var_cov){
  
  # This specification gets the full matrix of values as output
  hazard <- hazard0 %*% exp(beta*(alpha_0 + alpha_1*time_var_cov))
  
  return(hazard)
}


# 04 Draw time to events --------------------------------------------------

# Set seed for reproducibility
set.seed(1234) 

# Sample from Weibull baseline hazard (h_0)
hazard0 <- matrix(flexsurv::hweibull(x     = 1:n_cycles, 
                                     shape = n_weib_shape, 
                                     scale = n_weib_scale), 
                  ncol = 1)

# Set seed for reproducibility
set.seed(1234)

# Compute values of the hazard based on a range of covariate values
weibull_hazard <- compute_time_varying_hazard_linear_3(hazard0      = hazard0,
                                                       alpha_0      = alpha_0,
                                                       alpha_1      = alpha_1,
                                                       beta         = beta,
                                                       time_var_cov = seq(0:n_cycles))

# Convert to long format
df_weibull_hazard_long <- reshape2::melt(data       = weibull_hazard, 
                                         varnames   = c("Time", "Covariate"), 
                                         value.name = "h(t)")

dt_weibull_hazard_long <- as.data.table(df_weibull_hazard_long)

# Correct covariate id
dt_weibull_hazard_long[, Covariate := Covariate - 1]

#* Set key for efficient binary search
#* Check `vignette("datatable-keys-fast-subset") `
setkey(dt_weibull_hazard_long, Time, Covariate)

# Create time varying covariate, y_i(t)
set.seed(1234)
dtb_paths_individuals <- create_time_varying_covariate(n_ind    = n_ind,
                                                       n_cycles = n_cycles,
                                                       ourDrift = ourDrift)

set.seed(NULL)


# Obtain time-dependent hazards from indvidual-specific random paths
dtb_paths_individuals[, `h(t)` := dt_weibull_hazard_long[
  .(dtb_paths_individuals$Time, dtb_paths_individuals$Covariate),  `h(t)`]]


# Steps to get time-specific probability of event occurrence
dtb_paths_individuals[, H := cumsum(`h(t)`),  by = id]      # H(t) - Cumulative hazard
dtb_paths_individuals[, `F` := 1 - exp(-H)]                 # F(t) - Cumulative probability
dtb_paths_individuals[, f := c(`F`[1], diff(`F`)), by = id] # f(t) - Instantaneous probability

# Generate data set to sample time to event
dt_paths_individuals_wide <- data.table::dcast(data = dtb_paths_individuals,
                                               value.var = "f",
                                               formula = id ~ Time)

# Generate last cycle to sum probability up to 1
dt_paths_individuals_wide[, `101` := 1 - dtb_paths_individuals[Time == 100, `F`]]

# Sample time to event for all individuals
out_nps <- nps_nhppp(m_probs = as.matrix(dt_paths_individuals_wide[, `1`:`101`]),
                     v_categories = seq(0, 100),
                     correction = "none")


# 05 Summarize results ----------------------------------------------------


# Time to event (te) from random paths (rp)
n_mean_te_rp     <-  mean(out_nps)     # Expected value
n_sd_te_rp       <-  sd(out_nps)       # Standard deviation
n_quantile_te_rp <-  quantile(out_nps, probs = c(0.025, 0.975)) # 95% CI

# 06 Plotting -------------------------------------------------------------


# Random path of y_i(t) for first 10 id's
ggplt_random_path <- ggplot(data = dtb_paths_individuals[id <= 10], 
                            mapping = aes(x = Time, 
                                          y = Covariate,
                                          group = as.factor(id))) +
  geom_line() +
  scale_y_continuous(name     = expression(y[i](t)),
                     breaks = seq(0, 50, 2)) +
  scale_x_continuous(breaks = seq(0, 100, 25)) +
  theme_bw(base_size = 18) + 
  theme(legend.position = "none")

ggplt_random_path



#* Individual-specific hazard incorporating y_i(t) random path
#* For first 10 id's
ggplt_individual_hazards <- ggplot(data = dtb_paths_individuals[id <= 10], 
                                   mapping = aes(x = Time, 
                                                 y = `h(t)`,
                                                 group = as.factor(id))) +
  geom_line() +
  scale_y_continuous(name = expression(h[i](t)), 
                     breaks = seq(0, 0.1, 0.01)) +
  scale_x_continuous(breaks = seq(0, 100, 25)) +
  theme_bw(base_size = 18)

ggplt_individual_hazards


# Generate composed plot using `patchwork` package
ggpatch_rp_ih <- ggplt_random_path + ggplt_individual_hazards + 
  plot_annotation(tag_levels = "A", tag_suffix = ")")

ggpatch_rp_ih
