library(gridExtra)
library(ggplot2)

library(DALEX)
library(flashlight)
library(iml)

data(titanic_imputed, package = "DALEX")
titanic_imputed[["embarked"]] <- factor(substr(titanic_imputed[["embarked"]], 1, 1))
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

### SHAP ###

# DALEX
shap_dalex <- predict_parts(exp_dalex,
                           new_observation = titanic_imputed[1,],
                           type = "shap",
                           N = 50,
                           B = 50)
plot_dalex <- plot(shap_dalex)


# flashlight
shap_flashlight <-light_breakdown(exp_flashlight,
                                  new_obs = titanic_imputed[1, ],
                                  n_max = 50,
                                  n_perm = 50,
                                  visit_strategy = "permutation")
plot_flashlight<- plot(shap_flashlight)


# iml
shap_iml <-Shapley$new(exp_iml,
                       x.interest = X[1, ],
                       sample.size = 50)
plot_iml <- plot(shap_iml)




p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_shap.png", p, width = 4, height = 10)







