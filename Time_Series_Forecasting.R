library(tidyverse)
library(dplyr)
library(forecast)
library(ggplot2)

walmart <- read_csv("Walmart_Sales.csv")

#Time series forecasting
walmart$Date <- as.Date(walmart$Date, format = "%d-%m-%Y")

weekly_sales <- walmart %>% 
  group_by(Date) %>% 
  summarize(Total_Sales = sum(Weekly_Sales)) %>% 
  arrange(Date) %>% 
  mutate(Date_formatted = format(Date, "%m-%d-%Y"))

ts_sales <- ts(weekly_sales$Total_Sales,
               start = c(2010, 5),
               frequency = 52)

model <- auto.arima(ts_sales)
tsf <- forecast(model, h = 52)

autoplot(tsf) +
  labs(
    title = "Walmart Weekly Sales Time Series Forecast",
    subtitle = "52 week forecast",
    x = "Year",
    y = "Total Weekly Sales"
  )+
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

accuracy(model)

#ANOVA Test on holiday and Weekly Sales  
holiday_sales <- aov(Weekly_Sales ~ Holiday_Flag, data = walmart)
summary(holiday_sales)

#Logistic Regression using Weekly Sales & Consumer Price Index to predict whether its a holiday or not
logistic <- glm(Holiday_Flag ~ Weekly_Sales + CPI, data = walmart, family = "binomial")
summary(logistic)

library(caret)
# Generate predicted classes (0 or 1) using 0.5 threshold
walmart$predicted_prob <- predict(logistic, type = "response")

walmart$predicted_class <- ifelse(walmart$predicted_prob > 0.5, 1, 0)

# Confusion matrix
conf_matrix <- confusionMatrix(
  factor(walmart$predicted_class, levels = c(0, 1)),
  factor(walmart$Holiday_Flag, levels = c(0, 1))
)
print(conf_matrix)

# Plot confusion matrix as heatmap
conf_df <- as.data.frame(conf_matrix$table)

ggplot(conf_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), size = 6, fontface = "bold") +
  scale_fill_gradient(low = "white", high = "#2c3e50") +
  labs(title = "Confusion Matrix — Holiday Prediction",
       x = "Actual",
       y = "Predicted") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

conf_overall <- as.data.frame(conf_matrix$overall)

