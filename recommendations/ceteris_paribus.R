library(gridExtra)
library(ggplot2)

library(DALEX)
library(flashlight)
library(iml)

data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed,
                               classification = TRUE, probability = TRUE)

flashlight_predict <- function(X.model, new_data)
  predict(X.model, new_data)$predictions[,2]
iml_predict <- function(X.model, newdata)
  predict(X.model, newdata)$predictions[,2]


exp_dalex <- explain(ranger_model,
                     data = titanic_imputed,
                     y = titanic_imputed$survived,
                     label = "Ranger Model")
exp_flashlight <-flashlight(model = ranger_model,
                            data = titanic_imputed,
                            y = "survived",
                            label   = "Titanic Ranger",
                            metrics = list(auc = MetricsWeighted::AUC),
                            predict_function = flashlight_predict)
X <- titanic_imputed[
  which(names(titanic_imputed) != "survived")
  ]
exp_iml <-Predictor$new(ranger_model,
                        data = X,
                        y = titanic_imputed$survived,
                        predict.function = iml_predict)



# DALEX
cp_dalex <- predict_profile(exp_dalex,
                            new_observation = titanic_imputed[1,],
                            variables = "fare",
                            grid_points = 101)
plot_dalex <- plot(cp_dalex, variables = "fare")

# flashlight
cp_flashlight <- light_ice(exp_flashlight,
                           v = "fare",
                           indices = 1,
                           n_bins = 101)
plot_flashlight <- plot(cp_flashlight)

# iml
cp_iml <- FeatureEffect$new(exp_iml,feature = "fare",
                            method = "ice",
                            grid.size = 101)
plot_iml <- plot(cp_iml)






p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_ceteris_paribus.png", p, width = 4, height = 10)
