getwd()

## library(ggplot2)
## a_plot <- ggplot(data = cars, aes(x = speed, y = dist)) +
##     geom_point()
## ggsave("graphics/cars_plot.png", plot = a_plot)

library(readr)

billboard_2000_raw <- read_csv(file = "https://clanfear.github.io/CSSS508/Lectures/Week5/data/billboard.csv")

str(billboard_2000_raw[, 65:ncol(billboard_2000_raw)])

# paste is a string concatenation function
# i = integer, c = character, D = date
# rep("i", 76) does the 76 weeks of integer ranks
bb_types <- paste(c("icccD", rep("i", 76)), collapse="") #<<

billboard_2000_raw <- 
  read_csv(file = "https://clanfear.github.io/CSSS508/Lectures/Week5/data/billboard.csv",
           col_types = bb_types) #<<

## read_csv(file, guess_max=5000) # Default is 1000

## vroom::vroom(file)

## write_csv(billboard_2000_raw, path = "billboard_data.csv")

dput(head(cars, 8))

temp <- structure(list(speed = c(4, 4, 7, 7, 8, 9, 10, 10), 
                       dist = c(2, 10, 4, 22, 16, 10, 18, 26)),
                       .Names = c("speed", "dist"),
                       row.names = c(NA, 8L), class = "data.frame")

library(pander)
pander(head(billboard_2000_raw[,1:10], 12), split.tables=120, style="rmarkdown")

library(tidyr); library(dplyr)
billboard_2000 <- billboard_2000_raw %>%
  pivot_longer(starts_with("wk"), 
               names_to ="week", 
               values_to = "rank") #<<
dim(billboard_2000)

head(billboard_2000)

summary(billboard_2000$rank)

billboard_2000 <- billboard_2000_raw %>%
  pivot_longer(starts_with("wk"), 
               names_to ="week", 
               values_to = "rank", 
               values_drop_na = TRUE) #<<
summary(billboard_2000$rank)

dim(billboard_2000)

summary(billboard_2000$week)

billboard_2000 <- billboard_2000 %>%
    mutate(week = parse_number(week)) #<<
summary(billboard_2000$week)

billboard_2000 <- billboard_2000_raw %>%
  pivot_longer(starts_with("wk"), 
               names_to ="week", 
               values_to = "rank",
               values_drop_na = TRUE,
               names_prefix = "wk", #<<
               names_transform = list(week = as.integer))  #<<
head(billboard_2000, 3)

billboard_2000 <- billboard_2000 %>%
    separate(time, into = c("minutes", "seconds"),
             sep = ":", convert = TRUE) %>% #<<
    mutate(length = minutes + seconds / 60) %>%
    select(-minutes, -seconds)
summary(billboard_2000$length)

(too_long_data <- 
   data.frame(Group     = c(rep("A", 3), rep("B", 3)),
              Statistic = rep(c("Mean", "Median", "SD"), 2),
              Value     = c(1.28, 1.0, 0.72, 2.81, 2, 1.33)))

(just_right_data <- too_long_data %>%
    pivot_wider(names_from = Statistic, values_from = Value))

billboard_2000 <- billboard_2000 %>%
    group_by(artist, track) %>%
    mutate(`Weeks at #1` = sum(rank == 1),
           `Peak Rank`   = ifelse(any(rank == 1), #<<
                                  "Hit #1",
                                  "Didn't #1")) %>%
    ungroup() #<<

library(ggplot2)
billboard_trajectories <- 
  ggplot(data = billboard_2000,
         aes(x = week, y = rank, group = track,
             color = `Peak Rank`)
         ) +
  geom_line(aes(size = `Peak Rank`), alpha = 0.4) +
    # rescale time: early weeks more important
  scale_x_log10(breaks = seq(0, 70, 10)) + 
  scale_y_reverse() + # want rank 1 on top, not bottom
  theme_classic() +
  xlab("Week") + ylab("Rank") +
  scale_color_manual(values = c("black", "red")) +
  scale_size_manual(values = c(0.25, 1)) +
  theme(legend.position = c(0.90, 0.25),
        legend.background = element_rect(fill="transparent"))

billboard_trajectories

billboard_2000 %>%
    distinct(artist, track, `Weeks at #1`) %>%
    arrange(desc(`Weeks at #1`)) %>%
    head(7)

billboard_2000 <- billboard_2000 %>%
    mutate(date = date.entered + (week - 1) * 7) #<<
billboard_2000 %>% arrange(artist, track, week) %>%
    select(artist, date.entered, week, date, rank) %>% head(4)

plot_by_day <- 
  ggplot(billboard_2000, aes(x = date, y = rank, group = track)) +
  geom_line(size = 0.25, alpha = 0.4) +
  # just show the month abbreviation label (%b)
  scale_x_date(date_breaks = "1 month", date_labels = "%b") +
  scale_y_reverse() + theme_bw() +
  # add lines for start and end of year:
  # input as dates, then make numeric for plotting
  geom_vline(xintercept = as.numeric(as.Date("2000-01-01", "%Y-%m-%d")),
             col = "red") +
  geom_vline(xintercept = as.numeric(as.Date("2000-12-31", "%Y-%m-%d")),
             col = "red") +
  xlab("Week") + ylab("Rank")

plot_by_day

spd_raw <- read_csv("https://clanfear.github.io/CSSS508/Seattle_Police_Department_911_Incident_Response.csv")

glimpse(spd_raw)

str(spd_raw$`Event Clearance Date`)

# install.packages("lubridate")
library(lubridate)
spd <- spd_raw %>% 
  mutate(`Event Clearance Date` = 
           mdy_hms(`Event Clearance Date`, #<<
                   tz = "America/Los_Angeles"))
str(spd$`Event Clearance Date`)

demo_dts <- spd$`Event Clearance Date`[1:2]
(date_only <- as.Date(demo_dts, tz = "America/Los_Angeles"))
(day_of_week_only <- weekdays(demo_dts))
(one_hour_later <- demo_dts + dhours(1))

spd_times <- spd %>%
    select(`Initial Type Group`, `Event Clearance Date`) %>%
    mutate(hour = hour(`Event Clearance Date`))

time_spd_plot <- ggplot(spd_times, aes(x = hour)) +
    geom_histogram(binwidth = 2) +
    facet_wrap( ~ `Initial Type Group`) +
    theme_minimal() +
    theme(strip.text.x = element_text(size = rel(0.6))) +
    ylab("Count of Incidents") + xlab("Hour of Day")

time_spd_plot

# install.packages("forcats")
library(forcats)
str(spd_times$`Initial Type Group`)
spd_times$`Initial Type Group` <- 
  factor(spd_times$`Initial Type Group`)
str(spd_times$`Initial Type Group`)
head(as.numeric(spd_times$`Initial Type Group`))

spd_times <- spd_times %>% 
  mutate(`Initial Type Group` = 
         fct_infreq(`Initial Type Group`))
head(levels(spd_times$`Initial Type Group`),4)

time_spd_plot_2 <- ggplot(spd_times, aes(x = hour)) +
  geom_histogram(binwidth = 2) +
  facet_wrap( ~ `Initial Type Group`) +
  theme_minimal() +
  theme(strip.text.x = element_text(size = rel(0.6))) +
  ylab("Count of Incidents") + xlab("Hour of Day")

time_spd_plot_2

## fct_reorder(factor_vector,
##         quantity_to_order_by,
##         function_to_apply_to_quantities_by_factor)

jayz <- billboard_2000 %>% 
  filter(artist == "Jay-Z") %>%
  mutate(track = factor(track))

jayz_bad_legend <- 
  ggplot(jayz, aes(x = week, y = rank, 
                   group = track, color = track)) +
  geom_line() + 
  theme_bw() +
  scale_y_reverse(limits = c(100, 0)) + 
  theme(legend.position = c(0.80, 0.25),
        legend.background = element_rect(fill="transparent")) +
  xlab("Week") + ylab("Rank")

jayz_bad_legend

jayz <- jayz %>% mutate(track = fct_reorder(track, rank, min)) #<<

jayz_good_legend <-
  ggplot(jayz, aes(x = week, y = rank, 
                   group = track, color = track)) +
  geom_line() + 
  theme_bw() +
  scale_y_reverse(limits = c(100, 0)) + 
  theme(legend.position = c(0.80, 0.25),
        legend.background = element_rect(fill="transparent")) +
  xlab("Week") + ylab("Rank")

jayz_good_legend

jayz_biggest <- jayz %>% 
  filter(track %in% c("I Just Wanna Love U ...", "Big Pimpin'"))
levels(jayz_biggest$track)
jayz_biggest <- jayz_biggest %>% droplevels(.)
levels(jayz_biggest$track)
