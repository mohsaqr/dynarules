# Turning numeric variables into items. Rule mining needs categorical
# input, so a continuous measure has to be cut before it can be an item;
# how it is cut is a modelling choice, which is why the method is an
# argument rather than a default buried in the pipeline.

#' Discretize a Numeric Variable Into Items
#'
#' @param x A numeric vector, or a `data.frame` whose numeric columns are
#'   all to be discretized.
#' @param method How to place the cut points:
#'   * `"frequency"` (default) — equal-frequency bins (quantiles), so each
#'     bin holds roughly the same number of observations.
#'   * `"interval"` — equal-width bins across the observed range.
#'   * `"cluster"` — k-means on the values, cutting midway between
#'     adjacent cluster centres; bins follow where the data actually
#'     clumps.
#'   * `"fixed"` — cut points you supply yourself in `breaks`.
#' @param breaks Number of bins, or for `method = "fixed"` the vector of
#'   cut points. Default `3`.
#' @param labels Optional character vector of bin labels.
#' @param include_lowest Include the lowest value in the first bin.
#'   Default `TRUE`.
#' @param right Are intervals closed on the right? Default `FALSE`, i.e.
#'   `[a, b)`, matching the convention used for rule mining.
#' @param ordered Return an ordered factor? Default `FALSE`.
#' @param infinity Extend the outer breaks to `-Inf` and `Inf`, so values
#'   outside the training range still fall in a bin. Default `FALSE`.
#' @param ... Passed to [base::cut()].
#' @return A factor of the same length as `x`, or for a `data.frame` a
#'   `data.frame` with its numeric columns replaced by factors.
#' @examples
#' discretize(c(1, 3, 5, 7, 9, 11), breaks = 3)
#' discretize(c(1, 3, 5, 7, 9, 11), method = "interval", breaks = 2)
#' discretize(c(1, 2, 3, 10, 11, 12), method = "cluster", breaks = 2)
#' @seealso [transactions()]
#' @export
discretize <- function(x, method = c("frequency", "interval", "cluster",
                                     "fixed"),
                       breaks = 3, labels = NULL, include_lowest = TRUE,
                       right = FALSE, ordered = FALSE, infinity = FALSE,
                       ...) {
  method <- match.arg(method)
  if (is.data.frame(x)) {
    return(.dr_discretize_df(x, method = method, breaks = breaks,
                             labels = labels, include_lowest = include_lowest,
                             right = right, ordered = ordered,
                             infinity = infinity, ...))
  }
  stopifnot(is.numeric(x))

  cuts <- switch(method,
    fixed = {
      stopifnot(is.numeric(breaks), length(breaks) >= 2L)
      breaks
    },
    frequency = {
      stopifnot(length(breaks) == 1L, breaks >= 1)
      unname(stats::quantile(x, seq(0, 1, length.out = breaks + 1L),
                             na.rm = TRUE))
    },
    interval = {
      stopifnot(length(breaks) == 1L, breaks >= 1)
      seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE),
          length.out = breaks + 1L)
    },
    cluster = {
      stopifnot(length(breaks) == 1L, breaks >= 1)
      .dr_cluster_breaks(x, breaks)
    }
  )

  if (infinity) {
    cuts[1L] <- -Inf
    cuts[length(cuts)] <- Inf
  }
  if (anyDuplicated(cuts)) {
    cuts <- unique(cuts)
    if (length(cuts) < 2L) {
      stop("Cannot discretize: `x` takes only one distinct value, so there ",
           "is no cut point to place.", call. = FALSE)
    }
    warning("Duplicated cut points collapsed; fewer bins than requested.",
            call. = FALSE)
  }
  cut(x, breaks = cuts, labels = labels, include.lowest = include_lowest,
      right = right, ordered_result = ordered, ...)
}


# k-means on the values, then cut midway between adjacent centres. The
# centres are sorted first: kmeans returns them in arbitrary order, and
# unsorted centres would produce non-monotone breaks.
#' @noRd
.dr_cluster_breaks <- function(x, breaks) {
  ok <- !is.na(x)
  km <- stats::kmeans(x[ok], centers = breaks)
  centres <- sort(km$centers[, 1L])
  mids <- (centres[-1L] + centres[-length(centres)]) / 2
  c(min(x, na.rm = TRUE), mids, max(x, na.rm = TRUE))
}


#' @noRd
.dr_discretize_df <- function(df, ...) {
  numeric_cols <- vapply(df, is.numeric, logical(1))
  if (!any(numeric_cols)) {
    warning("No numeric columns to discretize.", call. = FALSE)
    return(df)
  }
  df[numeric_cols] <- lapply(df[numeric_cols], discretize, ...)
  df
}
