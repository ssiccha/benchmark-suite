standard <- read.csv("data/norm_prims.gapws_1_24095")
socle.of.normalizer <- read.csv("data/NormalizerOfPrimitiveGroup_prims.gapws_1_24095")
plot( standard[ c("Degree", "Mean") ] )
plot( socle.of.normalizer[ c("Degree", "Mean") ] )
slow   <- df[ df$Mean > 300. | df$Mean < 0., ]
