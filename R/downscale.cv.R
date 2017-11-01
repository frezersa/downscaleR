##############################################################################################################
#                     GENERAL DOWNSCALING                                                                    #
##############################################################################################################
##     downscale.train.R Downscale climate data.
##
##     Copyright (C) 2017 Santander Meteorology Group (http://www.meteo.unican.es)
##
##     This program is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
## 
##     This program is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
## 
##     You should have received a copy of the GNU General Public License
##     along with this program.  If not, see <http://www.gnu.org/licenses/>.

#' @title Downscale climate data.
#' @description Downscale data to local scales by statistical methods: analogs, generalized linear models (GLM), multiple linear regression (MLR), Extreme Learning Machine (ELM) and Neural Networks (NN). 
#' @param predictands The observations dataset. It should be an object as returned by \pkg{loadeR}.
#' @param predictors The input grid as returned by \code{\link[downscaleR]{prepare_predictors}}.
#' @param method Type of transer function. Options are: GLM, MLR, ELM and NN. The default is MLR.
#' @param singlesite Perform the study singlesite. Default is FALSE.
#' @param filt A logical expression (i.e. = ">0"). This will filter all values that do not accomplish that logical statement. Default is NULL.
#' @param ... Optional parameters. These parameters are different depending on the method selected. Every parameter has a default value set in the atomic functions in case that no selection is wanted. Everything concerning these parameters is explained in the section \code{Details}. However, if wanted, the atomic functions can be seen here: \code{\link[downscaleR]{glm.train}}, \code{\link[downscaleR]{mlr.train}}, \code{\link[downscaleR]{elm.train}} and \code{\link[deepnet]{nn.train}}.  

#' @details The function can downscale in both global and local mode, though not simultaneously. 
#' If there is perfect collinearity among predictors, then the matrix will not be invertible and the downscaling will fail.
#' 
#' \strong{Analogs}
#' The optional parameters of this method are the number of analogs, (n.analogs = 4 (DEFAULT), the function applied to the analogs values, (sel.fun = c("mean","max","min","median","prcXX") and the temporal window, (window = 0).
#' 
#' \strong{Generalized Linear Models (GLM)}
#' 
#' This function uses \code{\link[stats]{glm}}. The unique optional parameter is \code{family} with default \code{gaussian}. The possible family options are: gaussian, binomial, Gamma, inverse.gaussian, poisson, quasi, quasibinomial, quasipoisson. Indeed, family is a function itself of the form
#' family(object,...) where you can specified a link (i.e., a specification for the model link function), see \code{\link[stats]{family}}. For example for a logistic regression the optional parameter would be family = binomial(link = "logit"). The optional parameters of each method are axplained here:
#' 
#' \strong{Multiple Linear Regression (MLR)}
#' 
#' If you want to downscale by multiple linear regression there is only one optional parameter called, \code{fitting}, with options: fitting = c("LS","MP","MP+L2"). This options refers to Least Squares (LS), Moore-Penrose (MP) and L2 penalty Moore-Penrose (MP+L2). LS uses the \code{\link[stats]{lm}} R function, whereas MP and MP+L2 downscales via an internal function \code{\link[downscaleR]{mlr.train}}. "LS" is the default option.
#' 
#' \strong{Extreme Learning Machine (ELM)}
#' 
#' If you want to downscale via an Extreme Learning Machine there are 5 optional parameters: \code{fitting}, \code{neurons}, \code{Act.F}, \code{area.region} and \code{area.module}.
#' The parameter \code{fitting} refers to Moore-Penrose (MP) or Moore-Penrose L2 penalty (MP+L2). "MP" is the default option.
#' The parameter \code{neurons} refers to the number of hidden neurons, default is 100. The paramter \code{Act.F} refers to the activation function of the hidden neurons being a sigmoidal neuron the default and only option: Act.F = 'sig'.
#' The parameters \code{area.region} and \code{area.module} are necessary if you want to downscale with a variant of ELM, called Receptive Fields ELM (RF-ELM). The parameter \code{area.region} is a vector with two parameters (i.e. c(a,b)), meaning the number of consecutive points of x in latitude (a) and in longitude (b). Default is NULL. The parameter \code{area.module}, is the size of the area within the grid region that is masked and fed to the hidden neurons. Default is NULL.
#' 
#' \strong{Neural Networks}
#' 
#' Neural network is based on the library \pkg{deepnet}. The optional parameters corresponds to those in \code{\link[deepnet]{nn.train}} and are: \code{initW} = NULL, \code{initB} = NULL, \code{hidden} = c(10), \code{activationfun} = "sigm", \code{learningrate} = 0.8, \code{momentum} = 0.5, \code{learningrate_scale} = 1, \code{output} = "sigm", \code{numepochs} = 3, \code{batchsize} = 100, \code{hidden_dropout} = 0, \code{visible_dropout} = 0. The values indicated are the default values.
#' 
#' \strong{Help}
#' 
#' If there are still doubts about the optional parameters despite the description here, we encourage to look for further details in the atomic functions: \code{\link[downscaleR]{analogs.train}}, \code{\link[downscaleR]{glm.train}}, \code{\link[downscaleR]{mlr.train}}, \code{\link[downscaleR]{elm.train}} and \code{\link[deepnet]{nn.train}}.
#' 
#' @return A list of objects that contains the prediction on the train dataset, the model, the predictors and predictands used.
#' \itemize{
#'    \item \code{pred}: An object with the same structure as the predictands input parameter, but with pred$Data being the predictions and not the observations.
#'    \item \code{model}: A list with the information of the model: method, coefficients, fitting technique...
#'    \item \code{predictors}: Same as the predictors input parameter.
#'    \item \code{predictands}: Same as the predictands input parameter.}
#'    
#' @author J. Bano-Medina
#' @export
#' @importFrom MASS ginv
#' @importFrom matlab reshape repmat
#' @import deepnet 
#' @examples 
#' # Loading predictors
#' x <- makeMultiGrid(NCEP_Iberia_hus850, NCEP_Iberia_ta850)
#' x <- subsetGrid(x, years = 1985:1995)
#' # Loading predictands
#' y <- VALUE_Iberia_pr
#' y <- getTemporalIntersection(obs = y,prd = x, "obs" )
#' ybin <- convert2bin(y, threshold = 1)
#' # Prepare predictors
#' xT <- prepare_predictors(x = x, y = y)
#' # Downscaling PRECIPITATION
#' # ... via analogs ...
#' model.ocu <- downscale.train(ybin, xT, method = "analogs", sel.fun = "mean")
#' model.reg <- downscale.train(y, xT, method = "analogs", sel.fun = "mean")
#' # ... via a linear model ...
#' model.ocu <- downscale.train(ybin, xT, method = "GLM" ,family = binomial(link = "logit"))
#' model.reg <- downscale.train(y, xT, method = "MLR", fitting = "MP")
#' # ... via a extreme learning machine ...
#' model.ocu <- downscale.train(ybin, xT, method = "ELM", neurons = 200)
#' model.reg <- downscale.train(y, xT, method = "ELM", neurons = 200)
#' # ... via a extreme learning machine ...
#' model.ocu <- downscale.train(ybin, xT, method = "NN", learningrate = 0.1, numepochs = 10, hidden = 5, output = 'linear') 
#' model.reg <- downscale.train(y, xT, method = "NN", learningrate = 0.1, numepochs = 10, hidden = 5, output = 'linear') 
#' # Downscaling PRECIPITATION - Local model with the closest 4 grid points.
#' xT <- prepare_predictors(x = x,y = y,local.predictors = list(neigh.vars = "shum850",n.neighs = 4))
#' model.ocu <- downscale.train(ybin, xT, method = "MLR", fitting = 'MP')
#' model.reg <- downscale.train(y, xT, method = "MLR", fitting = 'MP')
#' # Downscaling PRECIPITATION - Principal Components (PCs)
#' xT <- prepare_predictors(x = x,y = y, PCA = list(which.combine = getVarNames(x),v.exp = 0.9))
#' model.ocu <- downscale.train(ybin, xT, method = "MLR" ,fitting = 'MP')
#' model.reg <- downscale.train(y, xT, method = "MLR" ,fitting = 'MP')
downscale.cv <- function(x, y, folds = 4, method, singlesite = FALSE, filt = NULL, global.vars = NULL, PCA = NULL, combined.only = TRUE, local.predictors = NULL, ...) {
  y <- filterNA(y)
  x <- getTemporalIntersection(y,x,which.return = 'prd')
  y <- getTemporalIntersection(y,x,which.return = 'obs')
  dimNames <- getDim(y)
  pred <- y
  pred$Data <- lapply(1:folds, FUN = function(xx) {
    data <- data_split(x,y, f = folds, type = "chronological", test.pos = (1:folds)[xx])
    xT <- prepare_predictors(x = data$xT, y = data$yT, global.vars, PCA, combined.only, local.predictors)
    xt <- prepare_newdata(newdata = data$xt, predictor = xT)
    model <- downscale.train(data$yT, xT, method = method, singlesite, filt, ...)
    downscale.predict(xt, model)$Data})
  pred$Data <- do.call(rbind,pred$Data)
  attr(pred$Data, "dimensions") <- dimNames
  return(pred)}