# README

# Examples using nonparametric sampling (NPS) to draw times to event

This repository contains the code used to replicates examples 1 to 5
contained in the “*A computationally efficient nonparametric sampling
method of time to event for individual-level models*” paper (**NOTE: ADD
DOI AND LINK ONCE PUBLISHED**).

This repository also provides a function to make samples considering a
multivariate categorical distribution. This function has an `R` and a
`Python` ports, they are located in the `R/nps_nhppp.R` and the
`python/nps_nhppp.py`, respectively.

Besides, this repository contains the code used to execute all the
examples using `R`, which are located inside the `analysis` folder. The
examples are the following:

- `01_parametric_hazards.R`. Shows how the NPS method can be implemented
  to draw times to event using discretized hazards derived coming from
  parametric distributions.
- `02_homogeneous_cohort.R`. Shows how the NPS method can be implemented
  to draw times to event using discretized hazards derived life tables
  from a **homogeneous** cohort.
- `03_heterogeneous_cohort.R`. Shows how the NPS method can be
  implemented to draw times to event using discretized hazards derived
  life tables from a **heterogeneous** cohort.
- `04_hazards_with_time_dependent_covariates.R`. Shows how the NPS
  method can be implemented to draw times to event using discretized
  hazards derived from processes following hazard proportional hazards
  with the following specification
  $h_i(t) = h_0(t) e^{(x_i(t)\beta)} = h_0(t) e^{((\alpha_0 + \alpha_1 t)\beta)}$,
  with $x_i(t) = \alpha_0 + \alpha_1 t$.
- `05_time_dependent_covariates_following_random_paths.R`. Shows how the
  NPS method can be implemented to draw times to event using discretized
  hazards derived from processes following a parametric baseline hazard
  with random covariates with the following specification
  $h_i(t) = h_0(t) e^{(x_i(t)\beta)} = h_0(t) e^{((\alpha_0 + \alpha_1 t)\beta)}$,
  with $x_i(t) = \alpha_0 + \alpha_1 y_i(t)$ where $y_i(t)$ follows a
  Gaussian random walking process $y_i(t) = y_i(t-1) + \epsilon_i$, and
  where $\epsilon_i \sim Normal(\mu = 0, \sigma = 0.5)$.

Finally, this repository also provides a `Python` port for the first
three examples. They can be located inside the `python` folder.
