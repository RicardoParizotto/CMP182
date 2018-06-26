library(gdata)
library(stargazer)
library(relaimpo)
library(rpart)
library(readxl)
library(tree)
library(rattle)
library(rpart.plot)
library(RColorBrewer)
library(plotmo)

#Read data
my.data <- read.table("LOGR1112_quality.txt", header=TRUE, sep="_", dec=".")
summary(my.data)

## % of the sample size (for the training stage)
smp_size <- floor(0.70 * nrow(my.data))

## seed
set.seed(123)
my.data_training <- sample(seq_len(nrow(my.data)), size = smp_size)

# split - train & test
train <- my.data[my.data_training, ]
test <- my.data[-my.data_training, ]

n_train <- 1000
n_folds <- 10
folds_i <- sample(rep(1:n_folds, length.out = n_train))
for (k in 1:n_folds) {
  test_i <- which(folds_i == k)
  train_xy <- xy[-my.data_training, ]
  test_xy <- xy[my.data_training, ]
  x <- train_xy$x
  y <- train_xy$y
}

#Startup delay
myFormulaStall <- STARTUPTIME ~ DELAY + TCPTP + TILE
my.data_rpart <- rpart(myFormulaStall, data = train, method = "anova", control=rpart.control(cp=0.00001, minsplit = 2))

barres=my.data[,"STALL", drop=FALSE]
barres=test[,"STALL", drop=FALSE]
rsq.rpart(my.data_rpart) # visualize cross-validation results 

opt <- which.min(my.data_rpart$cptable[,"xerror"])
cp <- my.data_rpart$cptable[opt, "CP"]
my.data_prune <- prune(my.data_rpart, cp = 7.9786e-04 )
print(my.data_prune)
plot(my.data_prune)
text(my.data_prune, cex=0.75)

# TEST is a fraction of the entire data
DEXfat_pred <- predict(my.data_prune, newdata = test)


compare_data=merge(barres, DEXfat_pred, by="row.names",all.x = TRUE)

write.csv2(compare_data, "mergeR1112.txt")
write.csv2(DEXfat_pred, "startpredictedR1112.txt")
write.csv2(test$STARTUPTIME, "Desktop/starttestR1112.txt")

DEXfat_pred 

prp(my.data_prune, faclen = 0, cex = 1.3)

fancyRpartPlot(my.data_prune, extra=1)

rpart.plot(my.data_prune)
rpart.plot(my.data_prune, # middle graph
           extra=0, box.palette="GnBu",
           faclen = 0,
           type=0,
           cex = 1.3)

prp(my.data_prune, cex = 0.8)
plotmo(my.data_prune)