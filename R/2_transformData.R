#' Transform data
#' 
#' Transform data prior to clustering
#' 
#' Flow and mass cytometry data should be transformed prior to clustering. The raw data
#' follows an approximately log-normal distribution. Transforming with a log (or similar)
#' function brings the data closer to a normal distribution, which improves clustering
#' performance and allows positive and negative populations to be distinguished more
#' clearly.
#' 
#' This function implements an inverse hyperbolic sine ('arcsinh') transform with
#' adjustable 'cofactor' parameter. The arcsinh transform is widely used for CyTOF data.
#' It behaves similarly to a log transform at high values, but is approximately linear
#' near zero; so unlike the log, it can handle zeros or small negative values. The
#' cofactor parameter controls the width of the linear region. Zero values and small
#' negatives occur in CyTOF data when no ions are detected in a given channel (negatives
#' are due to background subtraction and randomization of integer count values, which are
#' performed by default by the CyTOF instrument software).
#' 
#' Recommended values for the cofactor parameter are 5 (mass cytometry, CyTOF) or 150
#' (fluorescence flow cytometry); see Bendall et al. (2011), \emph{Science}, Supplementary
#' Figure S2.
#' 
#' The transform should be applied to protein marker columns only. The
#' \code{\link{SummarizedExperiment}} object created in the previous step
#' (\code{\link{prepareData}}) is assumed to contain a factor \code{marker_class} in the
#' column meta-data, where entries \code{"none"} indicate non-marker columns. (If this is
#' not available, all columns will be transformed instead.)
#' 
#' 
#' @param d_se Input data. Assumed to be in the form of a
#'   \code{\link{SummarizedExperiment}}, prepared with the function
#'   \code{\link{prepareData}}. Column meta-data is assumed to contain a factor
#'   \code{marker_class}, where entries \code{"none"} indicate non-marker columns.
#' 
#' @param cofactor Cofactor parameter for 'arcsinh' transform. Default = 5, which is
#'   appropriate for mass cytometry (CyTOF) data. For fluorescence flow cytometry, we
#'   recommend cofactor = 150 instead.
#' 
#' 
#' @return \code{d_se}: Data with transform applied to protein marker columns.
#' 
#' 
#' @importFrom SummarizedExperiment assay colData 'assay<-'
#' 
#' @export
#' 
#' @examples
#' # For a complete workflow example demonstrating each step in the 'diffcyt' pipeline, 
#' # see the package vignette.
#' 
#' # Function to create random data (one sample)
#' d_random <- function(n = 20000, mean = 0, sd = 1, ncol = 20, cofactor = 5) {
#'   d <- sinh(matrix(rnorm(n, mean, sd), ncol = ncol)) * cofactor
#'   colnames(d) <- paste0("marker", sprintf("%02d", 1:ncol))
#'   d
#' }
#' 
#' # Create random data (without differential signal)
#' set.seed(123)
#' d_input <- list(
#'   sample1 = d_random(), 
#'   sample2 = d_random(), 
#'   sample3 = d_random(), 
#'   sample4 = d_random()
#' )
#' 
#' experiment_info <- data.frame(
#'   sample_id = factor(paste0("sample", 1:4)), 
#'   group_id = factor(c("group1", "group1", "group2", "group2")), 
#'   stringsAsFactors = FALSE
#' )
#' 
#' marker_info <- data.frame(
#'   channel_name = paste0("channel", sprintf("%03d", 1:20)), 
#'   marker_name = paste0("marker", sprintf("%02d", 1:20)), 
#'   marker_class = factor(c(rep("type", 10), rep("state", 10)), 
#'                         levels = c("type", "state", "none")), 
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Prepare data
#' d_se <- prepareData(d_input, experiment_info, marker_info)
#' 
#' # Transform data
#' d_se <- transformData(d_se)
#' 
transformData <- function(d_se, cofactor = 5) {
  
  if (is.null(colData(d_se)$marker_class)) {
    is_marker <- rep(TRUE, ncol(assay(d_se)))
  } else {
    is_marker <- colData(d_se)$marker_class != "none"
  }
  
  # extract expression data
  d_ex <- assay(d_se)
  
  # apply transform to marker columns
  d_ex[, is_marker] <- asinh(d_ex[, is_marker] / cofactor)
  
  assay(d_se) <- d_ex
  
  d_se
}


