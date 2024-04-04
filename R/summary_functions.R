
sample_ttt_nps <- function(n_samples, 
                           v_time_int = 0:150,
                           v_probs){
  
  v_time_to_event_rates_cat <- sample(size    = n_samples, x = v_time_int, 
                                      prob    = v_probs, 
                                      replace = TRUE)
  
  v_unif <- runif(n_samples)
  
  v_time_to_event_rates_cat_unif <- v_time_to_event_rates_cat + v_unif
  
  return(v_time_to_event_rates_cat_unif)
}


calc_stats_nps_corr <- function(n_reps = 1000, 
                                n_samples = 10000, v_time_int = 0:150, 
                                v_probs, alpha_level = 0.05,
                                true_ev, true_var){
  # Draw ´n_reps´ samples from the NPS TTT
  m_out <- replicate(n = n_reps, 
                     expr = sample_ttt_nps(n_samples = n_samples, 
                                           v_time_int = v_time_int, 
                                           v_probs = v_probs))
  
  ## Calculate summary statistics
  v_ev_est  <- colMeans(m_out)
  v_var_est <- matrixStats::colVars(m_out)
  
  v_se_ev_est  <- sqrt(v_ev_est/n_samples)
  v_se_var_est <- sqrt(v_var_est/n_samples)
  
  # Expected values
  mean_ev_est <- mean(v_ev_est)
  mean_var_est <- mean(v_var_est)
  
  # Bias
  bias_ev_est  <- abs(mean(v_ev_est) - true_ev)
  bias_var_est <- abs(mean(v_var_est) - true_var)
  
  # Monte Carlo Standard Error (MCSE) of Bias
  mcse_bias_ev_est  <- sqrt((sum((v_ev_est - true_ev)^2)/(n_reps - 1))/n_reps)
  mcse_bias_var_est <- sqrt((sum((v_var_est - true_var)^2)/(n_reps - 1))/n_reps)
  
  # Mean Square Error (MSE)
  mse_ev_est  <- sum((v_ev_est - true_ev)^2)/n_reps
  mse_var_est <- sum((v_var_est - true_var)^2)/n_reps
  
  # Confidence interval of bias
  z_score <- qnorm(p = 1 - alpha_level/2)
  ci_bias_ev_est <- c(LB = bias_ev_est - z_score*mcse_bias_ev_est, 
                      UB = bias_ev_est + z_score*mcse_bias_ev_est)
  ci_bias_var_est <- c(LB = bias_var_est - z_score*mcse_bias_var_est, 
                       UB = bias_var_est + z_score*mcse_bias_var_est)
  
  # Confidence intervals pf estimates
  chi_score_lb <- qchisq(p = alpha_level/2, df = (n_samples - 1))
  chi_score_ub <- qchisq(p = 1 - alpha_level/2, df = (n_samples - 1))
  
  m_ci_ev_est <- cbind(LB = v_ev_est - z_score*v_se_ev_est, 
                       UB = v_ev_est + z_score*v_se_ev_est)
  # DescTools::MeanCI(v_time_to_event_rates_cat_unif, conf.level = 0.95)
  # confint(lm(v_time_to_event_rates_cat_unif ~ 1))
  m_ci_var_est <- cbind(LB = ((n_samples - 1)*v_var_est)/chi_score_ub, 
                        UB = ((n_samples - 1)*v_var_est)/chi_score_lb)
  # DescTools::VarCI(v_time_to_event_rates_cat_unif, conf.level = 0.95)
  # Coverage
  coverage_ev_est  <- mean(true_ev >= m_ci_ev_est[, 1] & true_ev <= m_ci_ev_est[, 2])
  coverage_var_est <- mean(true_var >= m_ci_var_est[, 1] & true_var <= m_ci_var_est[, 2])
  # Output
  return(c(mean_ev_est = mean_ev_est,
           mean_var_est = mean_var_est,
           bias_ev_est = bias_ev_est,
           bias_var_est = bias_var_est,
           coverage_ev_est = coverage_ev_est,
           coverage_var_est = coverage_var_est
  ))
}

