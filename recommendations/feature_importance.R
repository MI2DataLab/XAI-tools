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

### Feature importance ###

#DALEX
fi_dalex <- model_parts(exp_dalex, 
                        B = 10,
                        loss_function = loss_one_minus_auc)
plot_dalex <- plot(fi_dalex)

#flashlight
fi_flashlight <- light_importance(exp_flashlight,
                                  m_repetitions = 10)
plot_flashlight <- plot(fi_flashlight, fill = "darkred")


# iml
fi_iml <- FeatureImp$new(exp_iml,
                         loss = "logLoss",
                         n.repetitions = 10)
plot_iml <- plot(fi_iml)



p <- gridExtra::grid.arrange(plot_dalex, 
                             plot_flashlight, 
                             plot_iml, 
                             ncol = 1)
ggsave("figures/rec_variable_importance.png", p, width = 4, height = 10)

