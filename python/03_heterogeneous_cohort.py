#* This python script replicates the exponential example provided in:
#* - "analysis/03_heterogeneous_cohort.R"

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import scipy.stats as stats
import pandas as pd

# To import `nps_nhpp` function
from python.nps_nhpp import nps_nhpp


################################################################################
# Load base data
################################################################################

df_mort_data_raw = pd.read_csv(filepath_or_buffer = "data/all_cause_mortality.csv")

################################################################################
# Data Wrangling
################################################################################

# Keep data only for year 2015
df_mort_data_1 = df_mort_data_raw.query("Year == 2015").copy()

# Reset index (row ennumeration) of new data set
df_mort_data_1.reset_index(drop = True, inplace = True)

df_mort_data_1.sort_values(by = ["Sex", "Year", "Age"], inplace = True)

df_grouped = df_mort_data_1.groupby('Sex')

df_mort_data_1['H_t'] = df_grouped['Rate'].cumsum()          # H(t) - Cumulative hazard
df_mort_data_1['S_t'] = df_mort_data_1['H_t'].apply(lambda x: np.exp(-x)) # S(t) - Cumulative survival
df_mort_data_1['F_t'] = 1 - df_mort_data_1['S_t']           # F(t) - Cumulative probability: 1 - S(t)
df_mort_data_1['p_t'] = df_mort_data_1.groupby('Sex')['F_t'].diff().fillna(df_mort_data_1['F_t']) # f(t) - Instantaneous probability

#* Check sum of probabilities.
df_mort_data_1.groupby(["Sex"])["p_t"].sum()


#* It we incomplete, so we will create another row to fill the probabilities
df_mort_append_0 = df_mort_data_1.groupby(["Sex"]).tail(1)

df_mort_append_0.loc[:, "Age"]  = 101
df_mort_append_0.loc[:, "p_t"]  = 1 - df_mort_append_0["F_t"]
df_mort_append_0.loc[:, "F_t"]  = df_mort_append_0[["F_t", "p_t"]].sum(axis = 1)
df_mort_append_0.loc[:, "S_t"]  = 1 - df_mort_append_0["F_t"]
df_mort_append_0.loc[:, "H_t"]  = np.nan
df_mort_append_0.loc[:, ["H_t", "Rate"]]  = np.nan


# Concatenate the original and the extra dataframes
df_mort_data_2 = pd.concat([df_mort_data_1, df_mort_append_0])
df_mort_data_2.sort_values(by = ["Sex", "Year", "Age"], inplace = True)
df_mort_data_2.reset_index(drop = True, inplace = True)

# Now the sum of probs by Sex == 1
df_mort_data_2.groupby(["Sex"])["p_t"].sum()

#* Conver into wide format
#* - Year will be discarded while turning data into wide format
df_mort_data_2_wide = df_mort_data_2.pivot(columns = "Age", index = ["Year", "Sex"], values = "p_t") 

df_mort_data_2_wide.reset_index(inplace = True)

df_mort_data_2_wide.rename_axis(None, axis = 1, inplace = True)

################################################################################
# Sample times to events from heterogeneous cohorts
################################################################################

# We will use the "Male" and "Female" sex categories to sample 100,000 individuals
a_age_values = np.arange(0, 102)
n_samples = int(1e5)
a_sex = ["Male", "Female"]
p_sex = [0.5, 0.5] # Must add up to 1

# Instantiate base dataset
df_test_sex = pd.DataFrame(data = {"Year": np.repeat(2015, n_samples)})

# Draw sex of the individuals
np.random.seed(seed = 1234) # Set seed for reproducibility
df_test_sex["Sex"] = np.random.choice(a = a_sex, size = n_samples, replace = True, p = p_sex) 
np.random.seed(seed = None)

# Append probability distribution based on Year and Sex
df_test_sex_probs = pd.merge(df_test_sex, df_mort_data_2_wide, how = "left", on = ["Year", "Sex"])

# Obtain probability arrays
a_pob_probs = df_test_sex_probs.loc[:, 0:101].to_numpy()

#* Sample age of death for every individual distribution using the
#* `nps_nhpp` function
np.random.seed(seed = 234090) # Set seed for reproducibility
df_test_sex["age_death"] = nps_nhpp(a_probs = a_pob_probs, correction = "none")
np.random.seed(seed = None)

################################################################################
# Compare results
################################################################################

# Sampled values from NPS NHPP method
df_test_sex.groupby(["Sex"])["age_death"].mean()
# Exact
df_mort_data_2.groupby(["Sex"])["S_t"].sum()


################################################################################
# Plotting
################################################################################


# Get base probability distributions for females and males
df_prob_values_females = df_mort_data_2_wide.loc[df_mort_data_2_wide["Sex"] == "Female", 0:101]
df_prob_values_males   = df_mort_data_2_wide.loc[df_mort_data_2_wide["Sex"] == "Male", 0:101]

a_prob_values_females  = df_prob_values_females.iloc[0].to_numpy()
a_prob_values_males    = df_prob_values_males.iloc[0].to_numpy()

# Graph histogram vs Prob mass function - Females
plt.rcParams["font.size"] = "22"
plt.hist(x = df_test_sex.loc[df_test_sex["Sex"] == "Female", "age_death"], bins = np.arange(0, 102), density = True)
plt.plot(a_age_values, a_prob_values_females, color = "orange", linewidth = 4)
plt.title("Histogram of death by age in simulated population, Females, 2015")
plt.grid(True, linestyle = "dotted", linewidth = 2)
plt.show()
plt.close()


# Graph histogram vs Prob mass function - Males
plt.rcParams["font.size"] = "22"
plt.hist(x = df_test_sex.loc[df_test_sex["Sex"] == "Male", "age_death"], bins = np.arange(0, 102), density = True)
plt.plot(a_age_values, a_prob_values_males, color = "orange", linewidth = 4)
plt.title("Histogram of death by age in simulated population, Males, 2015")
plt.grid(True, linestyle = "dotted", linewidth = 2)
plt.show()
plt.close()



