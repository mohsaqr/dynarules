# Rule algebra: the predicates that say which mined rules are worth
# keeping. Each returns a logical vector aligned with the rule table, so
# they compose as arguments to rules() rather than forcing the caller to
# subset by hand.

#' Which Rules Are Redundant?
#'
#' A rule is redundant when a more general rule -- same consequent, an
#' antecedent contained in this one's (a subset for co-occurrence rules,
#' an ordered subsequence for sequential ones) -- reaches at least the
#' same confidence. The extra items in the antecedent buy nothing.
#'
#' @param x A `dynarules` object.
#' @return A logical vector with one entry per mined rule.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' is_redundant(fit)
#' rules(fit, redundant = FALSE)
#' @seealso [rules()], [is_significant()], [is_maximal()]
#' @export
is_redundant <- function(x) {
  stopifnot(inherits(x, "dynarules"))
  if (nrow(x$rules) < 2L) return(rep(FALSE, nrow(x$rules)))
  .dr_redundant(x$rules, x$type)
}


#' Which Rules Beat Independence?
#'
#' Tests each rule against the null that antecedent and consequent are
#' independent, using a one-sided Fisher's exact test on the rule's 2x2
#' contingency table, with multiplicity control across the rule set.
#'
#' This is a test against *chance co-occurrence given the item margins*.
#' It is not the same question as [permute_rules()], which asks whether a
#' rule survives destroying the structure of the transactions themselves;
#' use that one when the transaction structure is what you are arguing
#' about.
#'
#' @param x A `dynarules` object.
#' @param alpha Significance level. Default `0.05`.
#' @param adjust Multiplicity correction, any method accepted by
#'   [stats::p.adjust()]. Default `"BH"`; use `"none"` to switch it off.
#' @return A logical vector with one entry per mined rule.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' is_significant(fit)
#' @seealso [rules()], [permute_rules()], [measures()]
#' @export
is_significant <- function(x, alpha = 0.05, adjust = "BH") {
  stopifnot(inherits(x, "dynarules"),
            is.numeric(alpha), length(alpha) == 1L, alpha > 0, alpha < 1)
  adjust <- match.arg(adjust, stats::p.adjust.methods)
  if (nrow(x$rules) == 0L) return(logical(0))
  p <- measures(x, measure = "fishersExactTest")$fishersExactTest
  stats::p.adjust(p, method = adjust) < alpha
}


#' Which Rules Rest on a Maximal Itemset?
#'
#' A rule is maximal when no other mined rule is built on a strictly
#' larger pattern containing this rule's items. Maximal rules are the
#' most specific ones the mining produced.
#'
#' @param x A `dynarules` object.
#' @return A logical vector with one entry per mined rule.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' is_maximal(fit)
#' @seealso [itemsets()], [rules()]
#' @export
is_maximal <- function(x) {
  stopifnot(inherits(x, "dynarules"))
  r <- x$rules
  if (nrow(r) == 0L) return(logical(0))
  sep_out <- if (x$type == "sequential") " -> " else ", "
  full <- .dr_rule_items(r, sep_out)
  inside <- .dr_contained_in(x$type)
  sizes <- lengths(full)
  vapply(seq_along(full), function(i) {
    !any(vapply(seq_along(full), function(j) {
      sizes[j] > sizes[i] && inside(full[[i]], full[[j]])
    }, logical(1)))
  }, logical(1))
}


# The full item pattern behind each rule (antecedent then consequent).
#' @noRd
.dr_rule_items <- function(r, sep_out) {
  lapply(seq_len(nrow(r)), function(i) {
    c(strsplit(r$antecedent[i], sep_out, fixed = TRUE)[[1]],
      strsplit(r$consequent[i], sep_out, fixed = TRUE)[[1]])
  })
}
