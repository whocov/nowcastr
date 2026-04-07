#' Fit one model to data
#'
#' @param data A data.frame with columns `x` and `y`.
#' @param modelname Character. Name of the model to fit.
#' @return An `nls` or `lm` object if successful, otherwise `NULL`.
#' @examples
#' data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
#' fit_model(data, modelname = "linear")
#' @importFrom stats nls lm
#' @noRd
fit_model <- function(data, modelname = "monomolecular") {
  stopifnot(data$x %>% is.numeric())
  stopifnot(data$y %>% is.numeric())

  ## if 2 points, do not try to fit except linear
  if (nrow(data) <= 2 && modelname != "linear") {
    return(NULL)
  }

  tryCatch(
    {
      if (modelname == "monomolecular") {
        # convergence error can often be resolved by using the "port" algorithm.
        fit <- stats::nls(y ~ a * (1 - exp(-b * x)),
          data = data, start = list(a = 1, b = 1), algorithm = "port"
        )
      } else if (modelname == "monomolecular_with_offset") { # same as asymptotic.
        fit <- stats::nls(y ~ c + a * (1 - exp(-b * x)),
          data = data, start = list(a = 1, b = 1, c = .5), algorithm = "port"
        )
      } else if (modelname == "vonbertalanffy") {
        fit <- stats::nls(y ~ a * (1 - exp(-b * (x - c)))^3,
          data = data, start = list(a = 100, b = 0.1, c = 0), algorithm = "port"
        )
      } else if (modelname == "logistic") {
        fit <- withCallingHandlers(
          stats::nls(y ~ SSlogis(x, phi1, phi2, phi3), data = data),
          warning = function(w) invokeRestart("muffleWarning")
        )
      } else if (modelname == "gompertz") {
        fit <- withCallingHandlers(
          stats::nls(y ~ SSgompertz(x, phi1, phi2, phi3), data = data),
          warning = function(w) invokeRestart("muffleWarning")
        )
      } else if (modelname == "asymptotic") { # same as y ~ c + a * (1 - exp(-b * x)) (=monomolecular + a vertical offset)
        fit <- withCallingHandlers(
          stats::nls(y ~ SSasymp(x, phi1, phi2, phi3), data = data),
          warning = function(w) invokeRestart("muffleWarning")
        )
      } else if (modelname == "linear") {
        fit <- stats::lm(y ~ x, data = data)
      }

      ## check with plot:
      # plot(y ~ x, data = data); lines(data$x, fitted(fit), col = "red")

      return(fit)
    },
    error = function(e) {
      return(NULL)
    }
  )
}



#' Select the best fitted model
#'
#' @param data A data.frame with columns `x` and `y`.
#' @param modelnames Character vector. Names of models to try.
#' @return The fitted model object (`nls` or `lm`) with the lowest sum of squared residuals, or `NULL`.
#' @examples
#' data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
#' fit_models(data)
#' @importFrom stats residuals
#' @noRd
fit_models <- function(
  data,
  modelnames = c("monomolecular", "vonbertalanffy", "logistic", "gompertz", "asymptotic", "linear")
  #
) {
  ## verify valid modelnames
  accepted_modelnames <- c(
    "monomolecular",
    "monomolecular_with_offset",
    "vonbertalanffy",
    "logistic",
    "gompertz",
    "asymptotic",
    "linear"
  )
  if (!all(modelnames %in% accepted_modelnames)) {
    rlang::abort("Invalid model(s) specified. Valid modelnames are: ", paste(accepted_modelnames, collapse = ", "))
  }

  ## validate data and fit only linear models if data is too small
  if (nrow(data) == 0) {
    return(NULL)
  } else if (nrow(data) <= 2) {
    modelnames <- c("linear")
  } else if (length(unique(data$y)) == 1) { ## only 1 constant value
    modelnames <- c("linear")
  }

  fits <- lapply(modelnames, function(modelname) {
    tryCatch(
      fit_model(data, modelname = modelname),
      error = function(e) NULL
    )
  })
  names(fits) <- modelnames

  # Evaluate fits
  fits_info <- lapply(fits, function(fit) {
    if (!is.null(fit) && inherits(fit, c("nls", "lm"))) {
      ssr <- sum(stats::residuals(fit)^2)
      list(fit = fit, ssr = ssr)
    } else {
      list(fit = NULL, ssr = Inf)
    }
  })

  # Select the best fit based on the sum of squared residuals
  best_fit <- fits_info[[which.min(sapply(fits_info, function(f) f$ssr))]]$fit
  return(best_fit)
}



#' Detect the model type and return a model name
#'
#' @param fit A fitted model object (`nls` or `lm`).
#' @return Character string of the model name.
#' @importFrom stats formula
#' @noRd
detect_model_type <- function(fit) {
  formula_str <- paste(as.character(stats::formula(fit)), collapse = " ")
  if (inherits(fit, "lm")) {
    return("linear")
  } else if (grepl("SSlogis", formula_str)) {
    return("logistic")
  } else if (grepl("SSgompertz", formula_str)) {
    return("gompertz")
  } else if (grepl("SSasymp", formula_str)) {
    return("asymptotic")
  } else if (formula_str == "~ y a * (1 - exp(-b * x))") {
    return("monomolecular")
  } else if (formula_str == "~ y a * (1 - exp(-b * (x - c)))^3") {
    return("vonbertalanffy")
  } else {
    return(formula_str)
  }
}



#' Extract model parameters (coefficients)
#'
#' @param fit A fitted model object (`nls` or `lm`).
#' @return Named numeric vector of coefficients.
#' @importFrom stats coef
#' @noRd
extract_model_params <- function(fit) {
  if (inherits(fit, "lm")) {
    return(stats::coef(fit))
  } else if (inherits(fit, "nls")) {
    return(stats::coef(fit))
  } else {
    return(NULL) # Or appropriate error/handling
  }
}



#' Predict values from a fitted model
#'
#' @param fit A fitted model object (`nls` or `lm`).
#' @param alldelays Numeric vector of x values to predict for.
#' @return A data.frame with columns `x` and `y`, or a single numeric value for constant linear models.
#' @importFrom stats coef
#' @noRd
predict_values_from_fit <- function(fit, alldelays) {
  if (is.null(fit)) {
    return(NULL)
  }
  # lots of linear models have x=NA (=flat line)
  if (detect_model_type(fit) == "linear" && is.na(extract_model_params(fit)[["x"]])) {
    # return(NULL)
    return(unname(stats::coef(fit)[1])) ## constant value
  } else {
    tryCatch(
      {
        data.frame(x = alldelays) %>%
          mutate(y = as.numeric(stats::predict(fit, .)))
      },
      warning = function(w) {
        print(w)
      }
    )
  }
}


#' Extract the first time to reach band 0.95-1.05 from discrete data
#'
#' @param data_x_y A data.frame with columns `x` and `y`.
#' @return Numeric time value or `NA`.
#' @noRd
get_time_to_95_105_discrete <- function(data_x_y) {
  if (is.null(data_x_y)) {
    return(NA)
  }
  reached_95 <- data_x_y %>% filter(.data$y >= 0.95 & .data$y <= 1.05)
  if (nrow(reached_95) == 0) {
    return(NA)
  }
  time_to_95 <- min(reached_95$x)
  return(time_to_95)
}


#' Find precise time to reach band 0.95 - 1.05
#'
#' Uses grid search for robustness (local minima) and uniroot for precision.
#'
#' @param fit A fitted model object (`nls` or `lm`).
#' @param step Numeric. Step size for the grid search.
#' @param max_delay Numeric. Maximum x value to search.
#' @return Numeric time value or `NA_real_`.
#' @importFrom stats uniroot predict
#' @noRd
get_time_to_95_105_precise <- function(fit, step = 1, max_delay = 1000) {
  if (is.null(fit) || inherits(fit, "try-error")) {
    return(NA_real_)
  }

  # 1. Coarse Grid Search (vectorized for speed)
  # We assume the curve is smooth enough that it won't jump in/out within a single step
  grid_x <- seq(0, max_delay, by = step)

  # Predict all at once (faster than loop)
  grid_y <- tryCatch(
    stats::predict(fit, newdata = list(x = grid_x)),
    error = function(e) NULL
  )

  if (is.null(grid_y)) {
    return(NA_real_)
  }

  # Find indices where y is inside the band
  in_band_idx <- which(grid_y >= 0.95 & grid_y <= 1.05)

  if (length(in_band_idx) == 0) {
    return(NA_real_)
  } # Never enters band in range

  first_idx <- in_band_idx[1]

  # Case A: Started inside the band at x=0
  if (first_idx == 1) {
    return(grid_x[1])
  }

  # Case B: Entered the band between (index - 1) and (index)
  x_lower <- grid_x[first_idx - 1]
  x_upper <- grid_x[first_idx]
  y_prev <- grid_y[first_idx - 1]

  # Determine if we are entering from BELOW (target 0.95) or ABOVE (target 1.05)
  target_y <- if (y_prev < 0.95) 0.95 else 1.05

  # 2. Refine with uniroot for decimal precision
  # We only solve f(x) - target = 0 inside this specific step
  tryCatch(
    {
      stats::uniroot(function(x) stats::predict(fit, list(x = x)) - target_y,
        interval = c(x_lower, x_upper)
      )$root
    },
    error = function(e) NA_real_
  )
}
