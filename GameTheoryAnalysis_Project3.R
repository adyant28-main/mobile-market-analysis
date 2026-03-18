install.packages("rlang")
install.packages("dplyr")
datax<- read.csv(file.choose())
head(datax)

# Part 1: Payoff Matrix

samsung <- matrix(c(4,2,
                    5,3), 
                  nrow = 2, byrow = TRUE)

xiaomi <- matrix(c(4,5,
                   2,3), 
                 nrow = 2, byrow = TRUE)

rownames(samsung) <- c("Low", "High")
colnames(samsung) <- c("Low", "High")

rownames(xiaomi) <- c("Low", "High")
colnames(xiaomi) <- c("Low", "High")

samsung
xiaomi


# Part 2: Results

cat("Dominant Strategy:\n")
cat("Samsung: High\n")
cat("Xiaomi: High\n")

cat("\nNash Equilibrium:\n")
cat("(High, High)\n")

cat("\nPayoff:\n")
cat("(", samsung["High","High"],
    ", ", xiaomi["High","High"], ")\n")

# Part 3: Strategy Plot


library(ggplot2)

strategy <- data.frame(
  Samsung = c("Low","Low","High","High"),
  Xiaomi = c("Low","High","Low","High"),
  Payoff = c("(4,4)","(2,5)","(5,2)","(3,3)"),
  Nash = c(FALSE, FALSE, FALSE, TRUE)
)

strategy$Samsung <- factor(strategy$Samsung, levels = c("Low","High"))
strategy$Xiaomi <- factor(strategy$Xiaomi, levels = c("Low","High"))

ggplot(strategy, aes(Samsung, Xiaomi)) +
  geom_tile(aes(fill = Nash)) +
  geom_text(aes(label = Payoff), size = 5) +
  scale_fill_manual(values = c("lightblue","orange")) +
  labs(title = "Strategy Space",
       x = "Samsung",
       y = "Xiaomi") +
  theme_minimal()


# Part 4: Data Support, Payoff Assumptions


library(dplyr)

datax %>%
  filter(Brand %in% c("SAMSUNG","XIAOMI")) %>%
  group_by(Brand, discount_group) %>%
  summarise(avg_rating = mean(avg_rating),
            avg_price = mean(avg_price),
            .groups = "drop")

#  visualsiation of their ratings by groups
datax %>%
  filter(Brand %in% c("SAMSUNG","XIAOMI")) %>%
  ggplot(aes(x = discount_group, y = avg_rating, fill = Brand)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Ratings by Discount Strategy",
    x = "Discount Level",
    y = "Average Rating"
  ) +
  theme_minimal()
  