library(xtable)
library(dplyr)

load("./benchmark/packages_times.rda")

packages_times %>%
  select(pkg_name, type, evaluation_time) %>%
  group_by(pkg_name, type) %>%
  mutate(min = min(evaluation_time),
         mean = mean(evaluation_time),
         max = max(evaluation_time)) %>%
  select(-evaluation_time) %>%
  unique() %>%
  xtable()
