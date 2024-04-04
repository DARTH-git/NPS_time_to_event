#* This python script replicates the exponential example provided in:
#* - "analysis/01_parametric_hazards.R" 

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy.stats as stats
import pandas as pd


################################################################################
# Define general parameters
################################################################################

# Exponential rate
rate = 0.1
# Sample size
n_samp = int(1e6)

################################################################################
# Data Wrangling
################################################################################

# Obtain analytical values
a_true_mean   = 1/rate             ## mean
a_true_median = np.log(2)/rate   ## median
a_true_sd     = (1/(rate**2))**(1/2) ## SD

# Derive PDF from CDF
a_prob_exp_rates = stats.expon.cdf(np.arange(1, 152), scale = 1/rate) - stats.expon.cdf(np.arange(0, 151), scale = 1/rate)

# Normalize PDF
a_norm_exp_probs = a_prob_exp_rates/sum(a_prob_exp_rates)

# Sample values from normalized probabilites
a_random_exp_sample = np.random.choice(a = np.arange(0, 151), size = n_samp, replace = True, p = a_norm_exp_probs)

# Add random number between 0 and 1 to approximate continous time
a_random_exp_corr = a_random_exp_sample + np.random.random_sample(size = n_samp)

################################################################################
# Compare results
################################################################################

## From NPS sample
a_random_exp_sample.mean()
np.median(a = a_random_exp_sample)
a_random_exp_sample.std()
a_random_exp_sample.max()
a_random_exp_sample.min()
np.quantile(a = a_random_exp_sample, q = [0.025, 0.975])

## From NPS corrected
a_random_exp_corr.mean()
np.median(a = a_random_exp_corr)
a_random_exp_corr.std()
a_random_exp_corr.max()
a_random_exp_corr.min()
np.quantile(a = a_random_exp_corr, q = [0.025, 0.975])

## Against analytical mean
a_true_mean
a_true_median
a_true_sd


