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
shap_dalex <- predict_parts(explainer_dalex,
                            new_observation = titanic_imputed[1,],
                            type = "shap", 
                            B = 50)
plot_dalex <- plot(shap_dalex)


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
shap_flashlight <- light_breakdown(explainer_flashlight, 
                                   new_obs = titanic_imputed[1, ], 
                                   n_max = 1000, 
                                   n_perm = 50,
                                   visit_strategy = "permutation")
plot_flashlight <- plot(shap_flashlight)



library("iml")
custom_predict <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
explainer_iml <- Predictor$new(ranger_model,
                               data = X, 
                               y = titanic_imputed$survived,
                               predict.function = custom_predict)
shap_iml <- Shapley$new(explainer_iml,
                        x.interest = X[1, ],
                        sample.size = 50)
plot_iml <- plot(shap_iml)





p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_shap.png", p, width = 4, height = 10)







