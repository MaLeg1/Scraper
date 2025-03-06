FROM rocker/r-ver:4.3.2
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    libcurl4-openssl-dev

# Copy your script
COPY scraper.R .

# Install R packages
RUN R -e "install.packages(c('httr', 'rvest', 'dplyr', 'httpuv', 'later'), repos='https://cloud.r-project.org/')"

# Command to run the script
CMD ["Rscript", "scraper.R"]
