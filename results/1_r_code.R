# Read in the Survey of Youth in Custody
syc <- readr::read_csv(
  file = "data/syc_r.csv", # Tell it where the file is
  col_types = "nn", # Tell it that there are two columns, and they are "numeric" (n)
)

# Read the stratum size provided in Assignment 2 Question 4, shape (16, 1)
N_h_list = c(2724, 3192, 4107, 2705, 3504, 376, 56, 
             528, 624, 520, 672, 384, 744, 847, 824, 1848)

# glimpse the read data set
dplyr::glimpse(syc)

# Extra step: rescaling *finalwt* variable
# As can be seen from the code below, the sum of finalwt in each stratum is different from $N_h$. Therefore, we rescale the finalwt to make the sum of finalwt in each stratum to be equal to N_h, based on the R code provided by Professor Boudreau (here we sincerely thank him for helping us with the project and providing us with the code).  

# compute the sum of finalwt in each stratum
finalwt_h_list = c()
for (h in 1:16)
{
  sub_dataset = syc[syc$stratum == h, ]
  finalwt_h = sum(sub_dataset$finalwt)
  finalwt_h_list = c(finalwt_h_list, finalwt_h)
}

# Compare the sum of finalwt in each stratum and the N_h list
comparison_df <- data.frame(finalwt_h_sum = finalwt_h_list, N_h = N_h_list)
print(comparison_df)

# we want the sum of finalwt in each stratum to be equal to N_h
# therefore, we rescale it using finalwt_h * N_h / finalwt_h_sum
finalwt2 = c()
for (h in 1:16)
{
  finalwt_h = syc[syc$stratum == h, ]$finalwt
  N_h = N_h_list[h]
  finalwt_h_sum = finalwt_h_list[h]
  finalwt_h = finalwt_h * N_h / finalwt_h_sum
  finalwt2 = c(finalwt2, finalwt_h)
}
syc$finalwt = finalwt2

print(sum(syc$finalwt))

# Make sure rescaling is complete 
finalwt_h_list = c()
for (h in 1:16)
{
  sub_dataset = syc[syc$stratum == h, ]
  finalwt_h = sum(sub_dataset$finalwt)
  finalwt_h_list = c(finalwt_h_list, finalwt_h)
}

# Compare the sum of finalwt2 in each stratum to the N_h
comparison_df <- data.frame(finalwt_h_sum = finalwt_h_list, N_h = N_h_list)
print(comparison_df)

mirror_match_bootstrap_h = function(dataset, N_h_list, h)
{
  # Perform one mirror-match bootstrap for stratum h
  # parameters
  # ---------
  # 
  # dataset : data.frame
  #   dataset of shape (n, 2)
  # N_h_list : vector
  #   vector of shape (16, 1)
  # h : int
  #   stratum number
  #
  # return
  # ------
  #
  # bootstrap_weights : vector
  #   bootstrap weights for the sample units in the stratum (from 1 to n_h)
  #   shape (n_h, 1)
  
  # get the stra_weights df, shape is (n_h, 2)
  stra_weights_df = get_stratum(dataset, h)
  # get the stra_weights vector, shape is (n_h, 1)
  stra_weights = stra_weights_df$finalwt
  # get n_h from the dimension of stra_weights_df
  n_h = dim(stra_weights_df)[1]
  # get N_h from the N_h_list
  N_h = N_h_list[h]
  # compute the n_h_prime using the formula n_{h}^{\prime} = f_n \times n_h
  n_h_prime = n_h * (n_h / N_h)
  # get random integer n_h_prime by applying random_n_h_prime if it is not integer
  if (!n_h_prime %% 1 == 0)
  {
    n_h_prime = random_n_h_prime(n_h_prime, n_h, h)
  }
  # compute k_h
  k_h = get_k_h(n_h, n_h_prime, N_h)
  # create a vector of indices for the stra_weights, shape is (n_h, 1)
  indices = seq(1, n_h)
  # create a counter to count the number of times a index is selected, shape is (n_h, 1)
  counter = rep(0, n_h)
  # print information about the stratum h
  # print(paste("The stratum is", h, "the n_h is", n_h, "the n_h_prime is", n_h_prime, "the k_h is", k_h))
  
  # carry out sample without replacement from indices (k_h times), sample size is n_h_prime
  for (s in 1:k_h)
  {
    # sample without replacement
    bootstrapsample = sample(indices, n_h_prime, replace = FALSE)
    for (index in bootstrapsample)
    {
      # log the number of appearances of index of elements in stratum h in the bootstrapsample
      counter[index] = counter[index] + 1
    }
  }
  # calculate the bootstrap weights using stra_weights (n_h, 1) and counter (n_h, 1)
  # apply element-wise multiplication of the two vectors
  bootstrap_weights = counter * stra_weights
  
  # make sure the length of bootstrap_weights is n_h
  if (length(bootstrap_weights) == n_h)
  {
    return(bootstrap_weights)
  }
  else
  {
    stop("bootstrap_weights does not have length n_h")
  }
  
}

get_stratum = function(dataset, h)  # get the weights of stratum h from the dataset
{
  # make sure stratum number is in the range of 1 to 16
  if (h %in% seq(1, 16))
  {
    # get the weights of stratum h from the dataset
    stra_weights_df = dataset[dataset$stratum == h, ]
    return(stra_weights_df)
  }
  else
  {
    stop("Stratum number does not exist.")
  }
}

get_k_h = function(n_h, n_h_prime, N_h)  # compute the k_h, the number of resamplings with replacement
{
  f_h = n_h / N_h  # compute f_h
  f_h_star = n_h_prime / n_h  # compute f_h_star
  k_h = (n_h * (1 - f_h_star)) / (n_h_prime * (1 - f_h))  # compute k_h using the formula
  # apply the random_k_h function if k_h is not integer
  
  if (!k_h%%1 == 0)
  {
    k_h = random_k_h(k_h)
  }
  return(k_h)
}

random_n_h_prime = function(n_h_prime, n_h, h)  # randomization for k_h
{
  # make sure n_h_prime is in the proper range
  if (n_h_prime >= 1 && n_h_prime < n_h)
  {
    # get k_h_floor and k_h_ceil
    n_h_prime_floor = floor(n_h_prime)
    n_h_prime_ceil = ceiling(n_h_prime)
    
    # get prob for n_h_prime_floor
    # apply the formula in the paper
    p_floor = n_h_prime_ceil - n_h_prime
    # get prob for k_h_ceil
    p_ceil = 1 - p_floor
    
    # get the random integer n_h_prime based on the p_floor and p_ceil
    n_h_prime = sample(c(n_h_prime_floor, n_h_prime_ceil), 1, prob = c(p_floor, p_ceil))
    return(n_h_prime)
  }
  else if (h == 7)
  {
    n_h_prime = sample(c(1, 2), 1)
    return(n_h_prime)
  }
  else
  {
    stop(paste("n_h_prime must be larger than or equal to 1 and less than n_h, however got", n_h_prime))
  }
}

random_k_h = function(k_h)  # randomization for k_h
{
  # make sure k_h is larger than 1
  if (k_h >= 1)
  {
    # get k_h_floor and k_h_ceil
    k_h_floor = floor(k_h)
    k_h_ceil = ceiling(k_h)
    
    # get prob for k_h_floor
    # apply the formula in the paper
    p_floor = ((1 / k_h) - (1 / k_h_ceil)) / ((1 / k_h_floor) - (1 / k_h_ceil))
    # get prob for k_h_ceil
    p_ceil = 1 - p_floor
    
    # get the random integer k_h based on the p_floor and p_ceil
    k_h = sample(c(k_h_floor, k_h_ceil), 1, prob = c(p_floor, p_ceil))
    return(k_h)
  }
  else
  {
    stop("k_h must be larger than or equal to 1")
  }
}

mirror_match_bootstrap_full = function(dataset, N_h_list, stratum_list = seq(1, 16))
{
  # Perform one full mirror-match bootstrap for 16 strata
  # parameters
  # ---------
  # 
  # dataset : data.frame
  #   dataset of shape (n, 2)
  # N_h_list : vector
  #   vector of shape (16, 1)
  # stratum_list : vector
  #   list contatining all the stratum numbers
  #   default is seq(1, 16)
  #
  # return
  # ------
  #
  # bootstrap_weights : vector
  #   bootstrap weights for the full sample of size n consisting of 16 strata
  #   shape (n, 1)
  
  # compute the sample size n
  n = dim(dataset)[1]
  # create an empty vector for storing bootstrap weights
  bootstrap_weights_full = c()
  for (h in stratum_list)
  {
    # obtain the bootstrap weights for stratum h by applying the function mirror_match_bootstrap_h
    bootstrap_weights_h = mirror_match_bootstrap_h(dataset, N_h_list, h)
    # concatenate the new bootstrap weights to the bootstrap_weights_full
    bootstrap_weights_full = c(bootstrap_weights_full, bootstrap_weights_h)
  }
  
  # make sure the length of bootstrap_weights_full be n
  if (length(bootstrap_weights_full) == n)
  {
    return(bootstrap_weights_full)
  }
  else
  {
    stop("the length of bootstrap_weights_full must be n")
  }
}

mirror_match_bootstrap_B = function(dataset, N_h_list, B = 100, stratum_list = seq(1, 16))  # function for repeating the full bootstrap B times
{
  # stratum vector
  stratum_vector = dataset$stratum  
  bootstrap_weights_matrix = stratum_vector
  # repeat the bootstrap B times
  for (exp in 1:B)
  {
    # perform the mirror_match_bootstrap_full function
    bootstrap_weights_vector = mirror_match_bootstrap_full(dataset, N_h_list)
    # append the newly obtained bootstrap weight as a new column of bootstrap_weights_matrix
    bootstrap_weights_matrix = cbind(bootstrap_weights_matrix, bootstrap_weights_vector)
  }
  # convert the bootstrap_weights_matrix to data frame
  bootstrap_weights_matrix = as.data.frame(bootstrap_weights_matrix)
  # assign the column names
  names(bootstrap_weights_matrix) = c("stratum", paste0("w", 1:100))
  # delete the stratum column since we only need the bootstrap weights
  bootstrap_weights_matrix = subset(bootstrap_weights_matrix, select = -stratum)
  return(bootstrap_weights_matrix)
}

# apply the function to the syc dataset, m : data.frame
m <- mirror_match_bootstrap_B(syc, N_h_list)
dplyr::glimpse(m)
# save the bootstrap weights
write.csv(m, "data/bootstrap_weights_matrix.csv", row.names = FALSE)
