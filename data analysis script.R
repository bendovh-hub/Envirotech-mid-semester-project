# -------------------------------------------------------------------------
# Script Name: analyze_sensor_data.R
# Purpose: Plot a 3-panel time-series graph comparing SHT40 and SCD30 sensors
# -------------------------------------------------------------------------

# Load required libraries
library(dplyr)
library(tidyr)
library(stringr)
library(tidyverse)
library(ggplot2)

# 1. Load the data --------------------------------------------------------
raw_data <- read.csv("DATA.CSV")

raw_unfiltered <- raw_data %>%
  # Crop to the last continuous run based on the absolute minimum time
  slice(max(which(Time_ms == min(Time_ms))):n()) %>%
  select(Temp_SHT40, Temp_SCD30, RH_SHT40, RH_SCD30, CO2_SCD30)

# 2. Reshape into long format for facet plotting --------------------------
boxplot_data <- raw_unfiltered %>%
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Value") %>%
  mutate(
    Parameter = case_when(
      str_detect(Variable, "Temp") ~ "Temperature (°C)",
      str_detect(Variable, "RH") ~ "Relative Humidity (%)",
      str_detect(Variable, "CO2") ~ "CO2 Concentration (ppm)"
    ),
    # Group by sensor model for the X-axis, or use "Main" for CO2
    Sensor = case_when(
      str_detect(Variable, "SHT40") ~ "SHT40",
      str_detect(Variable, "SCD30") ~ "SCD30",
      TRUE ~ "SCD30 (Main)"
    )
  )

# 3. Generate the Boxplots ------------------------------------------------
ggplot(boxplot_data, aes(x = Sensor, y = Value, fill = Sensor)) +
  geom_boxplot(
    outlier.color = "red",       # Outliers will stand out as bright red dots
    outlier.shape = 16,          # Solid circle for outliers
    outlier.size = 2,
    alpha = 0.5
  ) +
  # free_y is critical here so we can actually see the outliers in each scale
  facet_wrap(~Parameter, scales = "free_y", ncol = 3) + 
  scale_fill_manual(values = c("SHT40" = "#377EB8", "SCD30" = "#4DAF4A", "SCD30 (Main)" = "#984EA3")) +
  labs(
    title = "Outlier Identification via Raw Data Boxplots",
    subtitle = "Analysis of sensor parameters before data cleaning",
    x = "Sensor Node",
    y = "Measured Values",
    fill = "Sensor Model"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  ) 

# 4. Data Processing & Cleaning -------------------------------------------

processed_data <- raw_data %>%
  # A. Handle manual resets: keep only the latest continuous run
  slice(max(which(Time_ms == min(Time_ms))):n()) %>%
  
  # B. Optimized filtering based on your real boxplot
  filter(
    # Remove the 0°C glitch but keep normal office temps
    Temp_SCD30 > 10, 
    
    # Remove the 0% humidity glitch
    RH_SCD30 > 10,   
    
    # Remove the 0 ppm glitch AND the 2000 ppm extreme error, 
    # but KEEP the real human spikes (up to 900-1000 ppm if they happened)
    CO2_SCD30 > 350 & CO2_SCD30 < 1500
  ) %>% 
  
  # C. Convert time from milliseconds to hours
  mutate(Time_hours = Time_ms / 1000 / 3600)

 # 5. Reshape data into a clever long format
facet_data <- processed_data %>%
  # Select only the columns we need for plotting
  select(Time_hours, Temp_SHT40, Temp_SCD30, RH_SHT40, RH_SCD30, CO2_SCD30) %>%
  # Pivot into a single long table
  pivot_longer(cols = -Time_hours, names_to = "Variable", values_to = "Value") %>%
  # Separate the variable name into two custom columns: Parameter and Sensor
  mutate(
    Parameter = case_when(
      str_detect(Variable, "Temp") ~ "Temperature (°C)",
      str_detect(Variable, "RH") ~ "Relative Humidity (%)",
      str_detect(Variable, "CO2") ~ "CO2 Concentration (ppm)"
    ),
    Sensor = case_when(
      str_detect(Variable, "SHT40") ~ "SHT40",
      str_detect(Variable, "SCD30") ~ "SCD30",
      TRUE ~ "SCD30 (Main)"
    )
  )

# 6. Plot using facet_wrap with free_y
ggplot(facet_data, aes(x = Time_hours, y = Value, color = Sensor)) +
  geom_line(size = 0.8) +
  # free_y allows each panel to have its own custom Y scale
  facet_wrap(~Parameter, ncol = 1, scales = "free_y") + 
  scale_color_manual(values = c("SHT40" = "#377EB8", "SCD30" = "#4DAF4A", "SCD30 (Main)" = "#984EA3")) +
  labs(
    title = "Environmental Monitoring Analysis",
    subtitle = "3-Day Continuous Measurement",
    x = "Elapsed Time (Hours)",
    y = NULL, # Y-axis label is blank because each panel has its title
    color = "Sensor Node"
  ) +
  theme_bw() +
  theme(
    strip.text = element_text(face = "bold"), # Makes panel headers bold
    legend.position = "bottom"
  )

