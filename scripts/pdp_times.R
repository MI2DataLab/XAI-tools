library(gridExtra)

############# DALEX

library(DALEX)
code_to_eval_DALEX <- 'data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)

explainer_ranger <- explain(ranger_model, 
                  data = titanic_imputed, y = titanic_imputed$survived, 
                  label = "Ranger Model", verbose = FALSE)
pdp_ranger <- model_profile(explainer_ranger, variables = "fare", type = "partial")
plot(pdp_ranger)'

system.time(eval(expr = parse(text=code_to_eval_DALEX)))[3]

############# flashlight

library(flashlight)
library(MetricsWeighted)
code_to_eval_flashlight <- 'data(titanic_imputed, package = "DALEX")
ranger_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)
custom_predict <- function(X.model, new_data) {
  predict(X.model, new_data)$predictions[,2]
}
fl <- flashlight(model = ranger_model, data = titanic_imputed, y = "survived", label = "Titanic Ranger",
                 metrics = list(auc = AUC), predict_function = custom_predict)

pdp <- light_profile(fl, v = "fare", type = "partial dependence")
plot(pdp)'

system.time(eval(expr = parse(text=code_to_eval_flashlight)))[3]


############# iml
library(iml)
code_to_eval_iml <- 'data(titanic_imputed, package = "DALEX")
rf_model <- ranger::ranger(survived~., data = titanic_imputed, classification = TRUE, probability = TRUE)
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
pred_fun <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}
predictor <- Predictor$new(rf_model, data = X, y = titanic_imputed$survived, predict.function = pred_fun)
pdp <- FeatureEffect$new(predictor, feature = "fare", method = "pdp")
plot(pdp)'

system.time(eval(expr = parse(text=code_to_eval_iml)))[3]


############# pdp
library(pdp)
library(randomForest)

code_to_eval_pdp <- 'data(titanic_imputed, package = "DALEX")
rf_model <- randomForest(factor(survived)~., data = titanic_imputed[1:10,])
pred_fun <- function(object, newdata) predict(object, newdata, type = "prob")[,2]
rf_pdp <- partial(rf_model, pred.var = c("fare"), pred.fun = pred_fun )
plotPartial(rf_pdp)'

system.time(eval(expr = parse(text=code_to_eval_pdp)))[3]



#### generate figure

plot_DALEX <- eval(expr = parse(text=code_to_eval_DALEX))
plot_flashlight <- eval(expr = parse(text=code_to_eval_flashlight))
plot_iml <- eval(expr = parse(text=code_to_eval_iml))
plot_pdp <- eval(expr = parse(text=code_to_eval_pdp))

png("figures/pdps2.png", height = 900, width = 1200, units="px")
grid.arrange(plot_DALEX, plot_flashlight, plot_iml, plot_pdp, ncol = 2) 
dev.off()

