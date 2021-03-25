# This file includes the R code used in the article, entitled
# "Landscape of R packages for eXplainable Artificial Intelligence".
# Szymon Maksymiuk, Alicja Gosiewska, Przemysław Biecek
# The R Journal

# Section: Recommendations for a gentle introduction to XAI

data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed,
                               classification = TRUE, probability = TRUE)

flashlight_predict <- function(X.model, new_data)
  predict(X.model, new_data)$predictions[,2]
iml_predict <- function(X.model, newdata)
  predict(X.model, newdata)$predictions[,2]

### Feature importance ###

library("DALEX")
exp_dalex <- explain(ranger_model,
                     data = titanic_imputed,
                     y = titanic_imputed$survived,
                     label = "Ranger Model")
fi_dalex <- model_parts(exp_dalex, 
                        B = 10,
                        loss_function = loss_one_minus_auc)
plot(fi_dalex)


library("flashlight")
library("MetricsWeighted")
exp_flashlight <-flashlight(model = ranger_model,
                            data = titanic_imputed,
                            y = "survived",
                            label   = "Titanic Ranger",
                            metrics = list(auc = MetricsWeighted::AUC),
                            predict_function = flashlight_predict)
fi_flashlight <- light_importance(exp_flashlight,
                                  m_repetitions = 10)
plot(fi_flashlight, fill = "darkred")


library("iml")
X <- titanic_imputed[
  which(names(titanic_imputed) != "survived")
  ]
exp_iml <-Predictor$new(ranger_model,
                        data = X,
                        y = titanic_imputed$survived,
                        predict.function = iml_predict)
fi_iml <- FeatureImp$new(exp_iml,
                         loss = "logLoss",
                         n.repetitions = 10)
plot(fi_iml)


### SHAP ###

# DALEX
shap_dalex <-predict_parts(exp_dalex,
                           new_observation = titanic_imputed[1,],
                           type = "shap",
                           N = 50,
                           B = 50)
plot(shap_dalex)


# flashlight
shap_flashlight <-light_breakdown(exp_flashlight,
                                  new_obs = titanic_imputed[1, ],
                                  n_max = 50,
                                  n_perm = 50,
                                  visit_strategy = "permutation")
plot(shap_flashlight)


# iml
shap_iml <-Shapley$new(exp_iml,
                       x.interest = X[1, ],
                       sample.size = 50)
plot(shap_iml)


### Ceteris Paribus Profiles ###

# DALEX
cp_dalex <- predict_profile(exp_dalex,
                            new_observation = titanic_imputed[1,],
                            variables = "fare",
                            grid_points = 101)
plot(cp_dalex, variables = "fare")

# flashlight
cp_flashlight <- light_ice(exp_flashlight,
                           v = "fare",
                           indices = 1,
                           n_bins = 101)
plot(cp_flashlight)

# iml
cp_iml <- FeatureEffect$new(exp_iml,feature = "fare",
                           method = "ice",
                           grid.size = 101)
plot(cp_iml)



### Partal Dependence Profile ###

# DALEX
pdp_dalex <- model_profile(exp_dalex,
                           variables = "fare",
                           type = "partial",
                           N = 1000,
                           grid_points = 101,
                           variable_splits_type = "uniform")
plot(pdp_dalex)

# flashlight
pdp_flashlight <- light_profile(exp_flashlight,
                                v = "fare",
                                type = "partial dependence",
                                pd_n_max = 1000,
                                n_bins = 101,
                                cut_type = "equal")
plot(pdp_flashlight)

# iml 
pdp_iml <- FeatureEffect$new(exp_iml,
                             feature = "fare",
                             method = "pdp",
                             grid.size = 101)
plot(pdp_iml)

