# Classification based on associations (CBA; Liu, Hsu & Ma 1998).
#
# Association rules become a classifier when their consequent is
# restricted to class labels. The rules are then sorted by precedence and
# reduced to an ordered decision list: the first rule matching a case
# assigns its class, and anything matched by no rule falls through to a
# default. What makes it a classifier rather than a pile of rules is the
# M1 pass below, which keeps a rule only if it correctly classifies at
# least one case not already covered.

# Precedence: higher confidence wins; ties go to higher support; ties
# again go to the shorter (earlier-generated) antecedent.
#' @noRd
.dr_cba_order <- function(r, sep) {
  order(-r$confidence, -r$support,
        lengths(strsplit(r$antecedent, sep, fixed = TRUE)))
}

# M1: walk the sorted rules, keeping those that classify something new.
# After each kept rule, the default is the majority class among the cases
# still uncovered, and the running error is (misclassified so far) plus
# (cases the default would then get wrong). The classifier is the prefix
# with the lowest total error.
#' @noRd
.dr_cba_m1 <- function(match_mat, rule_class, truth, classes) {
  n <- length(truth)
  step <- Reduce(function(state, i) {
    live <- state$live
    hits <- live & match_mat[, i]
    correct <- hits & truth == rule_class[i]
    if (!any(correct)) return(state)
    live_next <- live & !hits
    errs <- state$errors + sum(hits & !correct)
    remaining <- truth[live_next]
    default <- if (length(remaining) == 0L) state$default else {
      names(which.max(table(factor(remaining, levels = classes))))
    }
    default_err <- sum(remaining != default)
    list(live = live_next, errors = errs, default = default,
         kept = c(state$kept, i),
         total = c(state$total, errs + default_err),
         defaults = c(state$defaults, default))
  },
  seq_len(ncol(match_mat)),
  init = list(live = rep(TRUE, n), errors = 0L,
              default = names(which.max(table(factor(truth,
                                                     levels = classes)))),
              kept = integer(0), total = numeric(0), defaults = character(0)))

  if (length(step$kept) == 0L) {
    return(list(kept = integer(0),
                default = names(which.max(table(factor(truth,
                                                       levels = classes))))))
  }
  best <- which.min(step$total)
  list(kept = step$kept[seq_len(best)], default = step$defaults[best])
}


#' Build a Classifier From Association Rules
#'
#' Mines rules whose consequent is a class label, then reduces them to an
#' ordered decision list with the CBA M1 algorithm.
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param class Character vector naming the items that are class labels,
#'   e.g. `c("pass", "fail")`. Every transaction must contain exactly one
#'   of them.
#' @param min_support,min_confidence,max_length Passed to [dynarules()]
#'   for the rule-mining step.
#' @param ... Further arguments for [dynarules()].
#' @return An object of class `dynarules_cba`: the ordered `rules`, the
#'   `default` class, and the training `accuracy`.
#' @references Liu, B., Hsu, W. and Ma, Y. (1998). Integrating
#'   classification and association rule mining. *KDD-98*, 80--86.
#' @examples
#' tx <- list(c("hot", "humid", "no"), c("hot", "windy", "no"),
#'            c("mild", "humid", "yes"), c("cool", "windy", "yes"),
#'            c("cool", "humid", "yes"), c("mild", "windy", "no"))
#' fit <- cba(tx, class = c("yes", "no"), min_support = 0.2,
#'            min_confidence = 0.5)
#' fit
#' predict(fit, tx)
#' @seealso [dynarules()], [rules()]
#' @export
cba <- function(x, class, min_support = 0.05, min_confidence = 0.5,
                max_length = 5L, ...) {
  tr <- .dr_as_transactions(x)
  stopifnot(is.character(class), length(class) >= 2L)
  missing_cls <- setdiff(class, tr$items)
  if (length(missing_cls) > 0L) {
    stop("Class item(s) not present in the data: ",
         paste(missing_cls, collapse = ", "), call. = FALSE)
  }
  cls_mat <- tr$matrix[, class, drop = FALSE]
  if (any(rowSums(cls_mat) != 1L)) {
    stop("Every transaction must carry exactly one class item; ",
         sum(rowSums(cls_mat) != 1L), " do not.", call. = FALSE)
  }
  truth <- class[max.col(cls_mat, ties.method = "first")]

  fit <- dynarules(tr, type = "cooccurrence", min_support = min_support,
                   min_confidence = min_confidence, min_lift = 0,
                   max_length = max_length,
                   appearance = list(rhs = class), ...)
  r <- fit$rules
  r <- r[!grepl(", ", r$consequent, fixed = TRUE), , drop = FALSE]
  if (nrow(r) == 0L) {
    out <- list(rules = r, default = names(which.max(table(truth))),
                classes = class, accuracy = NA_real_, n = tr$n_transactions,
                fit = fit)
    return(structure(out, class = "dynarules_cba"))
  }
  r <- r[.dr_cba_order(r, ", "), , drop = FALSE]
  row.names(r) <- NULL

  match_mat <- .dr_cba_matches(r, tr)
  sel <- .dr_cba_m1(match_mat, r$consequent, truth, class)
  kept <- r[sel$kept, , drop = FALSE]
  row.names(kept) <- NULL

  out <- list(rules = kept, default = sel$default, classes = class,
              n = tr$n_transactions, fit = fit)
  out$accuracy <- mean(.dr_cba_assign(kept, sel$default, tr) == truth)
  structure(out, class = "dynarules_cba")
}


# Which transactions satisfy each rule's antecedent: one row per
# transaction, one column per rule. vapply() drops to a vector when there
# is a single transaction, so the result is reshaped explicitly --
# classifying one new case is ordinary use, not an edge case.
#' @noRd
.dr_cba_matches <- function(r, tr) {
  n <- nrow(tr$matrix)
  antes <- strsplit(r$antecedent, ", ", fixed = TRUE)
  out <- vapply(antes, function(a) {
    known <- intersect(a, colnames(tr$matrix))
    if (length(known) < length(a)) return(rep(FALSE, n))
    rowSums(tr$matrix[, known, drop = FALSE]) == length(known)
  }, logical(n))
  matrix(out, nrow = n, ncol = length(antes))
}

# First column index that is TRUE in each row; NA for an all-FALSE row.
# Written as a row loop over a known-shape matrix rather than apply(), which
# also mishandles the single-row case.
#' @noRd
.dr_first_hit <- function(mm) {
  vapply(seq_len(nrow(mm)), function(i) {
    hit <- which(mm[i, ])
    if (length(hit) == 0L) NA_integer_ else hit[1L]
  }, integer(1))
}


# First matching rule wins; anything unmatched takes the default.
#' @noRd
.dr_cba_assign <- function(rules_df, default, tr) {
  n <- nrow(tr$matrix)
  if (nrow(rules_df) == 0L) return(rep(default, n))
  first <- .dr_first_hit(.dr_cba_matches(rules_df, tr))
  ifelse(is.na(first), default, rules_df$consequent[first])
}


#' Classify New Transactions
#'
#' @param object A `dynarules_cba` classifier.
#' @param newdata Transactions to classify: a `dyna_transactions` object
#'   or anything [transactions()] accepts. Defaults to the training data.
#' @param type `"class"` (default) returns the predicted labels;
#'   `"rule"` returns the index of the rule that fired, `NA` where the
#'   default was used.
#' @param ... Ignored.
#' @return A character vector of predictions, or an integer vector of rule
#'   indices.
#' @examples
#' tx <- list(c("hot", "humid", "no"), c("mild", "humid", "yes"),
#'            c("cool", "windy", "yes"), c("mild", "windy", "no"))
#' fit <- cba(tx, class = c("yes", "no"), min_support = 0.2,
#'            min_confidence = 0.5)
#' predict(fit, tx)
#' @seealso [cba()]
#' @export
predict.dynarules_cba <- function(object, newdata = NULL,
                                  type = c("class", "rule"), ...) {
  type <- match.arg(type)
  tr <- if (is.null(newdata)) object$fit$transactions else {
    .dr_as_transactions(newdata)
  }
  if (type == "class") return(.dr_cba_assign(object$rules, object$default, tr))
  if (nrow(object$rules) == 0L) return(rep(NA_integer_, tr$n_transactions))
  .dr_first_hit(.dr_cba_matches(object$rules, tr))
}


#' Print Method for a CBA Classifier
#'
#' @param x A `dynarules_cba` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_cba <- function(x, ...) {
  cat(sprintf("<dynarules_cba>  %d rules | default: %s | classes: %s\n",
              nrow(x$rules), x$default, paste(x$classes, collapse = ", ")))
  cat(sprintf("  training accuracy: %.3f on %d transactions\n",
              x$accuracy, x$n))
  if (nrow(x$rules) > 0L) {
    show <- utils::head(x$rules, 5L)
    cat("\n  Decision list (first match wins):\n")
    invisible(lapply(seq_len(nrow(show)), function(i) {
      cat(sprintf("    %2d. {%s} => %s   conf=%.2f  supp=%.2f\n", i,
                  show$antecedent[i], show$consequent[i],
                  show$confidence[i], show$support[i]))
    }))
    if (nrow(x$rules) > 5L) {
      cat(sprintf("    ... %d more\n", nrow(x$rules) - 5L))
    }
  }
  cat(sprintf("    --. otherwise => %s\n", x$default))
  invisible(x)
}


#' Summary Method for a CBA Classifier
#'
#' @param object A `dynarules_cba` object.
#' @param ... Ignored.
#' @return A tidy `data.frame`, one row per rule in the decision list plus
#'   a final row for the default: `position`, `antecedent`, `consequent`,
#'   `support`, `confidence`, `lift`.
#' @export
summary.dynarules_cba <- function(object, ...) {
  r <- object$rules
  data.frame(
    position = c(seq_len(nrow(r)), NA_integer_),
    antecedent = c(r$antecedent, "(default)"),
    consequent = c(r$consequent, object$default),
    support = c(r$support, NA_real_),
    confidence = c(r$confidence, NA_real_),
    lift = c(r$lift, NA_real_),
    stringsAsFactors = FALSE, row.names = NULL
  )
}
