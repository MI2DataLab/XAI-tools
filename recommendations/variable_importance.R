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
fi_dalex <- model_parts(explainer_dalex, 
                        B = 10,
                        loss_function = loss_one_minus_auc)
plot_dalex <- plot(fi_dalex)




library("flashlight")
custom_predict <- function(X.model, new_data) {
  predict(X.model, new_data)$predictions[,2]
}
explainer_flashlight <- flashlight(model = ranger_model,
                                   data = titanic_imputed,
                                   y = "survived",
                                   label = "Titanic Ranger",
                                   metrics = list(auc = MetricsWeighted::AUC),
                                   predict_function = custom_predict)
fi_flashlight <- light_importance(explainer_flashlight,
                                  m_repetitions = 10)
plot_flashlight <- plot(fi_flashlight, fill = "darkred")



library("iml")
custom_predict <- function(X.model, newdata) {
  predict(X.model, newdata)$predictions[,2]
}
X <- titanic_imputed[which(names(titanic_imputed) != "survived")]
explainer_iml <-Predictor$new(ranger_model,
                              data = X,
                              y = titanic_imputed$survived,
                              predict.function = custom_predict)
fi_iml <- FeatureImp$new(explainer_iml,
                         loss = "logLoss",
                         n.repetitions = 10)
plot_iml <- plot(fi_iml)



p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_variable_importance.png", p, width = 4, height = 10)

