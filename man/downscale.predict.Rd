% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/downscale.predict.R
\name{downscale.predict}
\alias{downscale.predict}
\title{Downscale climate data for a given statistical model.}
\usage{
downscale.predict(newdata, model)
}
\arguments{
\item{newdata}{The grid data. It should be an object as returned by  \code{\link[downscaleR]{prepare_newdata}}.}

\item{model}{An object containing the statistical model as returned from  \code{\link[downscaleR]{downscale.train}}.}
}
\value{
A list of predictions for each member.
}
\description{
Downscale data to local scales by statistical models previously obtained by \code{\link[downscaleR]{downscale.train}}.
}
\details{
The function can downscale in both global and local mode, though not simultaneously.
}
\examples{
# Loading predictors
x <- makeMultiGrid(NCEP_Iberia_hus850, NCEP_Iberia_ta850)
x <- subsetGrid(x, years = 1985:1995)
# Loading predictands
y <- VALUE_Iberia_pr
y <- getTemporalIntersection(obs = y,prd = x, "obs" )
x <- getTemporalIntersection(obs = y,prd = x, "prd" )
ybin <- convert2bin(y, threshold = 1)
x <- localScaling(x, base = x, scale = TRUE)
# Prepare predictors and predictands
xyT     <- prepare_predictors(x = x, y = y)
xyT.bin <- prepare_predictors(x = x, y = ybin)
xyt     <- prepare_newdata(newdata = x, predictor = xyT)
xyt.bin <- prepare_newdata(newdata = x, predictor = xyT.bin)
# Downscaling PRECIPITATION
# ... via analogs ...
model <- downscale.train(xyT, method = "analogs", sel.fun = "mean", site = "multi")
pred <- downscale.predict(xyt, model)
# ... via a logistic regression (ocurrence of precipitation) 
# and gaussian regression (amount of precipitation) ...
model.ocu <- downscale.train(xyT.bin, method = "GLM", family = binomial(link = "logit"))
model.reg <- downscale.train(xyT,     method = "GLM", family = "gaussian", filt = ">0")
pred.ocu <- downscale.predict(xyt.bin, model.ocu)
pred.reg <- downscale.predict(xyt    , model.reg)
# ... via a neural network ...
model.ocu <- downscale.train(xyT.bin, method = "NN",, site = "multi", 
                 learningrate = 0.1, numepochs = 10, hidden = 5, output = 'linear')
model.reg <- downscale.train(xyT    , method = "NN", site = "multi", 
                 learningrate = 0.1, numepochs = 10, hidden = 5, output = 'linear')
pred.ocu <- downscale.predict(xyT.bin, model.ocu)
pred.reg <- downscale.predict(xyT    , model.reg)
# Downscaling PRECIPITATION - Local model with the closest 4 grid points.
xyT.local     <- prepare_predictors(x = x,y = y,
                     local.predictors = list(neigh.vars = "shum@850",n.neighs = 4))
xyT.local.bin <- prepare_predictors(x = x,y = ybin,
                     local.predictors = list(neigh.vars = "shum@850",n.neighs = 4))
xyt.local     <- prepare_newdata(newdata = x, predictor = xyT.local)
xyt.local.bin <- prepare_newdata(newdata = x, predictor = xyT.local.bin)
model.ocu <- downscale.train(xyT.local.bin, method = "GLM", fitting = 'MP')
model.reg <- downscale.train(xyT.local    , method = "GLM", fitting = 'MP')
pred.ocu <- downscale.predict(xyt.local.bin, model.ocu)
pred.reg <- downscale.predict(xyt.local    , model.reg)
# Downscaling PRECIPITATION - Principal Components (PCs) 
# and gamma regression for the amount of precipitation
xyT.pc     <- prepare_predictors(x = x,y = y, 
                 PCA = list(which.combine = getVarNames(x),v.exp = 0.9))
xyT.pc.bin <- prepare_predictors(x = x,y = ybin, 
                 PCA = list(which.combine = getVarNames(x),v.exp = 0.9))
xyt.pc     <- prepare_newdata(newdata = x, predictor = xyT.pc)
xyt.pc.bin <- prepare_newdata(newdata = x, predictor = xyT.pc.bin)
model.ocu <- downscale.train(xyT.pc.bin, method = "GLM" , 
                             family = binomial(link = "logit"))
model.reg <- downscale.train(xyT.pc    , method = "GLM" , 
                             family = Gamma(link = "log"), filt = ">0")
pred.ocu <- downscale.predict(xyt.pc.bin, model.ocu)
pred.reg <- downscale.predict(xyt.pc, model.reg)
}
\author{
J. Bano-Medina
}
