#' dynarules: Association and Sequential Rule Mining for Temporal Event Data
#'
#' Mines co-occurrence association rules and order-aware sequential rules
#' from event data using an explicit transaction grammar (actor, action,
#' time, session, window), with tidy post-hoc verbs, network conversion,
#' bootstrap stability, and permutation significance testing.
#'
#' @keywords internal
"_PACKAGE"

# ggplot2 aes() variables used in plot methods
utils::globalVariables(c(
  "support", "confidence", "lift", "lift_mean", "lift_lower", "lift_upper",
  "lift_null", "recovery", "rule", "significant", "w"
))
