# Install packages if not already installed
if (!require("here", quietly = TRUE)) {
  install.packages("here", repos = "https://cloud.r-project.org/")
}
if (!require("rvest", quietly = TRUE)) {
  install.packages("rvest", repos = "https://cloud.r-project.org/")
}
if (!require("dplyr", quietly = TRUE)) {
  install.packages("dplyr", repos = "https://cloud.r-project.org/")
}
if (!require("httr", quietly = TRUE)) {
  install.packages("httr", repos = "https://cloud.r-project.org/")
}
# loading libraries
library(here)
library(rvest)
library(dplyr)
library(httr)
# Set directory and clean environment
setwd(here())
rm(list = ls())  

# Define URL
url <- "https://steamcharts.com/app/2246340"

# Define scraper function
game_scraper <- function(url) {
  Sys.sleep(runif(1, 2, 10))  # Random delay to mimic human behaviour
  page <- GET(url, add_headers("User-Agent" = "Mozilla/5.0"))
  html <- read_html(page)
  
  data <- html_nodes(html, ".num") %>% html_text()
  if (length(data) >= 3) {
    data <- data[-3]
  } else { # data should always be longer than 3 elements, but included just in case
    return(NULL)
  }
  
  timestamp <- Sys.time()
  df <- data.frame(t(data), stringsAsFactors = FALSE)
  colnames(df) <- c("no_players", "day_peak", "all_time_peak")
  
  df$no_players <- as.integer(df$no_players)
  df$day_peak <- as.integer(df$day_peak)
  df$all_time_peak <- as.integer(df$all_time_peak)
  df$timestamp <- timestamp
  return(df)
}

# Run the scraper
new_y_df <- game_scraper(url)
filename <- "y_data.csv"

# Write to CSV
if (!is.null(new_y_df)) { # in case scraping function fails
  if (file.exists(filename)) {
    y_df <- read.csv(filename)
    y_df$timestamp <- as.POSIXct(y_df$timestamp)
    y_df <- rbind(y_df, new_y_df)
  } else {
    y_df <- new_y_df
  }
  write.csv(y_df, filename, row.names = FALSE)
} else {
  cat("No data scraped, skipping write.\n")
}