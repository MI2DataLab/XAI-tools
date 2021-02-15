library(gridExtra)

############# DALEX

library(DALEX)
code_to_eval_DALEX <- 'data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)

explainer_ranger <- DALEX::explain(ranger_model, data = titanic_imputed, y = titanic_imputed$survived, label = "Ranger Model", verbose = FALSE)

shap_ranger <- predict_parts(explainer_ranger, new_observation = titanic_imputed[1,], type = "shap", B = 50)
plot(shap_ranger)'

system.time(eval(expr = parse(text=code_to_eval_DALEX)))[3]

############# fastshap

library(fastshap)
code_to_eval_fastshap <- 'data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)
pred_fun <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}

shap <- explain(ranger_model, X = titanic_imputed, pred_wrapper = pred_fun, nsim = 50)
library(ggplot2)
autoplot(shap, type = "contribution", row_num = 1)'

system.time(eval(expr = parse(text=code_to_eval_fastshap)))[3]


############# iml
library(iml)
code_to_eval_iml <- 'data(titanic_imputed, package = "DALEX")
rf_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
pred_fun <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}
predictor <- Predictor$new(rf_model, data = X, y = titanic_imputed$survived, predict.function = pred_fun)
shapley <- Shapley$new(predictor, x.interest = X[1, ], sample.size = 50)
plot(shapley)'

system.time(eval(expr = parse(text=code_to_eval_iml)))[3]


############# shapper
library(randomForest)
library(shapper)

code_to_eval_shapper <- 'data(titanic_imputed, package = "DALEX")
rf_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)
pred_fun <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}
ive_rf <- individual_variable_effect(rf_model, 
                                     predict_function = pred_fun,
                                     data = titanic_imputed[,-8],
                                     new_observation = titanic_imputed[1, -8],
                                     nsamples = 50)

plot(ive_rf)'

system.time(eval(expr = parse(text=code_to_eval_shapper)))[3]



#### generate figure

plot_DALEX <- eval(expr = parse(text=code_to_eval_DALEX))
plot_fastshap <- eval(expr = parse(text=code_to_eval_fastshap))
plot_iml <- eval(expr = parse(text=code_to_eval_iml))
plot_shapper <- eval(expr = parse(text=code_to_eval_shapper))

png("figures/pdps2.png", height = 900, width = 1200, units="px")
grid.arrange(plot_DALEX, plot_flashlight, plot_iml, plot_pdp, ncol = 2) 
dev.off()
