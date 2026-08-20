# ---- Post-hoc rule verbs ----

#' Extract, Filter, and Rank Mined Rules
#'
#' @description
#' The tidy accessor for a mined rule set. All narrowing and ordering is
#' done through arguments; the returned data.frame is printed directly.
#'
#' @param x A `dynarules` object.
#' @param min_support,min_confidence,min_lift Numeric. Tighten the
#'   corresponding threshold post hoc (defaults keep everything mined).
#' @param items Character or NULL. Keep only rules mentioning at least one
#'   of these items on the chosen `side`.
#' @param side Character. Where `items` must appear: `"any"` (default),
#'   `"antecedent"`, or `"consequent"`.
#' @param significant Keep only rules that beat independence; see
#'   [is_significant()]. Default `FALSE`.
#' @param maximal Keep only rules built on a maximal pattern; see
#'   [is_maximal()]. Default `FALSE`.
#' @param alpha,adjust Passed to [is_significant()] when
#'   `significant = TRUE`.
#' @param redundant Logical. `TRUE` (default) keeps all rules. `FALSE`
#'   drops rules dominated by a more general rule: same consequent, the
#'   general antecedent contained in the specific one, and confidence at
#'   least as high.
#' @param top Integer or NULL. Keep the top N rules after sorting.
#' @param by Character. Sort key: `"lift"` (default), `"confidence"`, or
#'   `"support"`. Descending, confidence as tie-break.
#'
#' @return A tidy data.frame, one row per rule (same columns as
#'   `x$rules`).
#'
#' @examples
#' trans <- list(c("plan", "discuss", "reflect"),
#'               c("plan", "discuss", "execute"),
#'               c("plan", "reflect"),
#'               c("discuss", "reflect"))
#' fit <- dynarules(trans, min_support = 0.25, min_lift = 0)
#' rules(fit, min_lift = 1, top = 5)
#'
#' @export
rules <- function(x,
                  min_support = 0,
                  min_confidence = 0,
                  min_lift = 0,
                  items = NULL,
                  side = c("any", "antecedent", "consequent"),
                  redundant = TRUE,
                  significant = FALSE,
                  maximal = FALSE,
                  alpha = 0.05,
                  adjust = "BH",
                  top = NULL,
                  by = c("lift", "confidence", "support")) {
  stopifnot(inherits(x, "dynarules"))
  side <- match.arg(side)
  by <- match.arg(by)

  r <- x$rules
  keep <- r$support >= min_support &
    r$confidence >= min_confidence &
    r$lift >= min_lift

  if (!is.null(items)) {
    stopifnot(is.character(items))
    sep <- if (x$type == "sequential") " -> " else ", "
    ante_hit <- vapply(strsplit(r$antecedent, sep, fixed = TRUE),
                       function(v) any(items %in% v), logical(1))
    cons_hit <- vapply(strsplit(r$consequent, sep, fixed = TRUE),
                       function(v) any(items %in% v), logical(1))
    keep <- keep & switch(side,
      any = ante_hit | cons_hit,
      antecedent = ante_hit,
      consequent = cons_hit
    )
  }

  if (significant) keep <- keep & is_significant(x, alpha = alpha,
                                                 adjust = adjust)
  if (maximal) keep <- keep & is_maximal(x)

  r <- r[keep, , drop = FALSE]
  if (!redundant && nrow(r) > 1L) {
    r <- r[!.dr_redundant(r, x$type), , drop = FALSE]
  }

  r <- r[order(-r[[by]], -r$confidence), , drop = FALSE]
  if (!is.null(top) && nrow(r) > top) {
    r <- r[seq_len(top), , drop = FALSE]
  }
  row.names(r) <- NULL
  r
}


# A rule is redundant when a more general rule (same consequent,
# antecedent contained in this rule's antecedent -- as a subset for
# co-occurrence, as an ordered subsequence for sequential) reaches at
# least the same confidence.
#' @noRd
.dr_redundant <- function(r, type) {
  sep <- if (type == "sequential") " -> " else ", "
  antes <- strsplit(r$antecedent, sep, fixed = TRUE)
  n <- nrow(r)
  contained <- if (type == "sequential") {
    function(general, specific) .dr_contains(specific, general)
  } else {
    function(general, specific) all(general %in% specific)
  }
  vapply(seq_len(n), function(i) {
    others <- setdiff(seq_len(n), i)
    any(vapply(others, function(j) {
      r$consequent[j] == r$consequent[i] &&
        length(antes[[j]]) < length(antes[[i]]) &&
        contained(antes[[j]], antes[[i]]) &&
        r$confidence[j] >= r$confidence[i]
    }, logical(1)))
  }, logical(1))
}


#' Coerce Mined Rules to a Data Frame
#'
#' @param x A `dynarules` object.
#' @param ... Ignored.
#' @return The tidy rules data.frame.
#' @export
as.data.frame.dynarules <- function(x, ...) {
  r <- .subset2(x, "rules")
  row.names(r) <- NULL
  r
}
