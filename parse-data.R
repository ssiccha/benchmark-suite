standard <- read.csv("data/results/partitionBacktrack_almost-simple-small-base_1_945.csv")
backtrack <- read.csv("data/results/_NORM_PRIM_backtrack_almost-simple-small-base_1_945.csv")
comparison <- standard[ c("i", "Degree", "ONanScottType", "Socle") ]
comparison <- comparison[1:nrow(backtrack), ]
comparison$finished.standard <- standard$Finished[1:nrow(comparison)]
comparison$finished.backtrack <- backtrack$Finished[1:nrow(comparison)]
comparison$mean.backtrack <- backtrack$Mean[1:nrow(comparison)]
comparison$mean.standard <- standard$Mean[1:nrow(comparison)]

# Stuff
plot( standard[ c("Degree", "Mean") ] )
plot( socle.of.normalizer[ c("Degree", "Mean") ] )
slow   <- df[ df$Mean > 300. | df$Mean < 0., ]

quicker <- comparison[comparison$mean.backtrack < comparison$mean.standard,]
