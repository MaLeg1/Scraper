if (!require("httr", quietly = TRUE)) install.packages("httr", repos = "https://cloud.r-project.org/"); library(httr)
if (!require("rvest", quietly = TRUE)) install.packages("rvest", repos = "https://cloud.r-project.org/"); library(rvest)
if (!require("dplyr", quietly = TRUE)) install.packages("dplyr", repos = "https://cloud.r-project.org/"); library(dplyr)
if (!require("httpuv", quietly = TRUE)) install.packages("httpuv", repos = "https://cloud.r-project.org/"); library(httpuv)
if (!require("later", quietly = TRUE)) install.packages("later", repos = "https://cloud.r-project.org/"); library(later)

rm(list = ls())
url <- "https://steamcharts.com/app/2246340"

game_scraper <- function(url) {
  if (Sys.Date() > as.Date("2025-04-05")) {
    cat("Scraping period ended.\n")
    return(NULL)
  }
  Sys.sleep(runif(1, 2, 10))
  page <- GET(url, add_headers("User-Agent" = "Mozilla/5.0"))
  html <- read_html(page)
  data <- html_nodes(html, ".num") %>% html_text()
  if (length(data) >= 3) {
    data <- data[-3]
  } else {
    cat("Warning: Fewer than 3 elements found.\n")
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

save_and_push <- function() {
  new_y_df <- game_scraper(url)
  filename <- "y_data.csv"
  if (!is.null(new_y_df)) {
    if (file.exists(filename)) {
      y_df <- read.csv(filename)
      y_df$timestamp <- as.POSIXct(y_df$timestamp)
      y_df <- rbind(y_df, new_y_df)
    } else {
      y_df <- new_y_df
    }
    write.csv(y_df, filename, row.names = FALSE)
    system("git config --global user.email 'mathieu.legein@hotmail.com'")
    system("git config --global user.name 'Mathieu Legein'")
    system("git add y_data.csv")
    system("git commit -m 'Update y_data.csv - $(date)'")
    system("git push https://$GITHUB_TOKEN@github.com/MaLeg1/hourly-scraper.git main")
    cat("Scraped and pushed at", as.character(Sys.time()), "\n")
  } else {
    cat("No data scraped, skipping write.\n")
  }
}

schedule_daily <- function() {
  now <- Sys.time()
  next_run <- as.POSIXct(format(now, "%Y-%m-%d 12:00:00"), tz = "UTC")
  if (now > next_run) next_run <- next_run + 86400
  delay <- as.numeric(next_run - now, units = "secs")
  later::later(function() {
    save_and_push()
    later::later(schedule_daily, 86400)
  }, delay)
}

startServer("0.0.0.0", 8080, list(
  call = function(req) {
    list(status = 200L, headers = list('Content-Type' = 'text/plain'), body = "Scraper running")
  }
))

schedule_daily()
while (TRUE) Sys.sleep(1)
