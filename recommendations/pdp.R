library(gridExtra)
library(ggplot2)

data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., 
                               data = titanic_imputed, 
                               classification = TRUE,
                               probability = TRUE)

library("DALEX")
explainer_dalex <- explain(ranger_model,
                           data = titanic_imputed, 
                           y = titanic_imputed$survived,
                           label = "Ranger Model", 
                           verbose = FALSE)
pdp_dalex <- model_profile(explainer_dalex,
                           variables = "fare", 
                           type = "partial",
                           N = 1000, 
                           grid_points = 101,
                           variable_splits_type = "uniform")
plot_dalex <- plot(pdp_dalex)


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
pdp_flashlight <-light_profile(explainer_flashlight,
                               v = "fare", 
                               type = "partial dependence",
                               pd_n_max = 1000, 
                               n_bins = 101,
                               cut_type = "equal")
plot_flashlight <- plot(pdp_flashlight)



library("iml")
custom_predict <- function(X.model, newdata){
  predict(X.model, newdata)$predictions[,2]
  }
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
explainer_iml <- Predictor$new(ranger_model,
                               data = X, 
                               y = titanic_imputed$survived,
                               predict.function = custom_predict)
pdp_iml <- FeatureEffect$new(explainer_iml,
                             feature = "fare",
                             method = "pdp", 
                             grid.size = 101)
plot_iml <- plot(pdp_iml)




p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_pdp.png", p, width = 4, height = 10)