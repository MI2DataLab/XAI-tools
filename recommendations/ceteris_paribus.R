library(gridExtra)
library(ggplot2)

data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., 
                               data = titanic_imputed, 
                               classification = TRUE,
                               probability = TRUE)

library("DALEX")
explainer_dalex <-explain(ranger_model,
                          data = titanic_imputed, 
                          y = titanic_imputed$survived,
                          label = "Ranger Model", 
                          verbose = FALSE)
cp_dalex <- predict_profile(explainer_dalex,
                            new_observation = titanic_imputed[11,],
                            variables = "fare", 
                            grid_points = 101)
plot_dalex <- plot(cp_dalex, variables = "fare")



library("flashlight")
library("MetricsWeighted")

custom_predict <- function(X.model, new_data) {
  predict(X.model, new_data)$predictions[,2]
}
explainer_flashlight <- flashlight(model = ranger_model,
                                   data = titanic_imputed, 
                                   y = "survived",
                                   label = "Titanic Ranger",
                                   metrics = list(auc = AUC),
                                   predict_function = custom_predict)
cp_flashlight <- light_ice(explainer_flashlight,
                           v = "fare",
                           indices = 11,
                           n_bins = 101)
plot_flashlight <- plot(cp_flashlight)



library("iml")
custom_predict <- function(X.model, newdata){
  predict(X.model, newdata)$predictions[,2]
}
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
explainer_iml <-Predictor$new(ranger_model,
                              data = X, 
                              y = titanic_imputed$survived,
                              predict.function = custom_predict)
cp_iml <- FeatureEffect$new(explainer_iml,
                            feature = "fare",
                            method = "ice",
                            grid.size = 101)
plot_iml <- plot(cp_iml)



p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_ceteris_paribus.png", p, width = 4, height = 10)
