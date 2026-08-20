# Re-deriving rules from patterns that have already been mined.

# Rebuild the level-wise structure the rule generator expects from the
# tidy frequent table carried on the fitted object.
#' @noRd
.dr_levels_from_frequent <- function(x) {
  fr <- x$frequent
  sep <- if (x$type == "sequential") " -> " else ", "
  n <- if (is.null(x$total_weight)) x$n_transactions else x$total_weight
  items <- strsplit(fr$pattern, sep, fixed = TRUE)
  by_size <- split(seq_len(nrow(fr)), fr$size)
  sizes <- as.integer(names(by_size))
  out <- vector("list", max(sizes))
  invisible(lapply(seq_along(by_size), function(i) {
    idx <- by_size[[i]]
    out[[sizes[i]]] <<- lapply(idx, function(j) {
      list(items = items[[j]], count = fr$count[j], support = fr$support[j])
    })
  }))
  lapply(out, function(z) if (is.null(z)) list() else z)
}


#' Induce Rules From Already-Mined Patterns
#'
#' Regenerates the rule set from the frequent patterns of a fitted model,
#' at different thresholds, without re-mining the transactions.
#'
#' Mining is the expensive half; rule generation is a cheap split of each
#' frequent pattern. So exploring confidence or lift cut-offs, or
#' restricting which items may appear on each side, should not mean
#' running the miner again. `min_support` cannot be lowered here -- the
#' patterns below the original support threshold were never counted, so
#' recovering them does require re-mining.
#'
#' @param x A `dynarules` object.
#' @param min_confidence,min_lift Thresholds for the induced rules.
#' @param min_length,max_length Optional bounds on the number of items in
#'   a rule. Default: those of the fitted model.
#' @param appearance Optional list restricting where items may occur, as
#'   in [dynarules()]. `lhs` and `rhs` whitelist each side.
#' @return A `dynarules` object carrying the induced rules. Everything
#'   that works on a mined model -- [rules()], [measures()], [plot()],
#'   [as_network()] -- works on it.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.9)
#' nrow(rules(fit))
#' loose <- rule_induction(fit, min_confidence = 0.3)
#' nrow(rules(loose))
#' @seealso [dynarules()], [rules()]
#' @export
rule_induction <- function(x, min_confidence = 0.5, min_lift = 1,
                           min_length = NULL, max_length = NULL,
                           appearance = NULL) {
  stopifnot(inherits(x, "dynarules"),
            is.numeric(min_confidence), length(min_confidence) == 1L,
            min_confidence >= 0, min_confidence <= 1,
            is.numeric(min_lift), length(min_lift) == 1L, min_lift >= 0)
  params <- x$params
  params$min_confidence <- min_confidence
  params$min_lift <- min_lift
  if (!is.null(min_length)) params$min_length <- as.integer(min_length)
  if (!is.null(max_length)) params$max_length <- as.integer(max_length)
  if (!is.null(appearance)) {
    params$appearance <- .dr_check_appearance(appearance)
  }

  levels_list <- .dr_levels_from_frequent(x)
  n <- if (is.null(x$total_weight)) x$n_transactions else x$total_weight
  ordered <- x$type == "sequential"
  sep_out <- if (ordered) " -> " else ", "

  out <- x
  out$rules <- .dr_rules_from_levels(levels_list, n, params, ordered, sep_out)
  out$params <- params
  out
}
