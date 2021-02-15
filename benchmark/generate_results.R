library(xtable)
library(dplyr)
library(tidyr)

load("./benchmark/packages_times.rda")

summary_time <- packages_times %>%
  select(pkg_name, evaluation_time) %>%
  group_by(pkg_name) %>%
  add_count(pkg_name) %>%
  mutate(sum = round(sum(evaluation_time),2)) %>%
  select(pkg_name, n, sum) %>%
  unique()


packages_times %>%
  select(pkg_name, type, evaluation_time) %>%
  group_by(pkg_name, type) %>%
  mutate(evaluation_time = round(median(evaluation_time), 2)) %>%
  unique() %>%
  pivot_wider(names_from = type, values_from = evaluation_time)  %>%
  mutate_all(~replace(., is.na(.), "-")) %>%
  bind_cols(summary_time[, c("sum", "n")]) %>% 
  select("pkg_name", "Model parts", "Model profile", "Model diagnostics", 
           "Predict parts", "Predict profile", "Predict diagnostics", "Report", 
           "sum", "n") %>%
  xtable() %>%
  print(include.rownames=FALSE)
