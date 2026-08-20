# Interest measures for mined rules.
#
# Every measure in the catalogue is a function of the same four quantities:
# the number of transactions `n` and the three supports P(A), P(B),
# P(A and B). Those fix the 2x2 contingency table, so each measure is a
# one-line closure over a shared context rather than a separate
# implementation. Four measures (improvement, boost, LIC, importance)
# additionally need the best sub-rule, which is derived on demand.

# Sub-antecedents of a rule: every proper, non-empty subset of the
# antecedent items, with the original order preserved (which matters for
# sequential rules, where the antecedent is an ordered pattern).
#' @noRd
.dr_sub_antecedents <- function(items) {
  k <- length(items)
  if (k < 2L) return(list())
  unlist(lapply(seq_len(k - 1L), function(size) {
    lapply(utils::combn(k, size, simplify = FALSE), function(idx) items[idx])
  }), recursive = FALSE)
}

# For each rule, the best confidence and lift attained by any strictly
# more general rule PRESENT IN THE MINED SET (identical consequent,
# antecedent a proper sub-antecedent). Zero when no such rule was mined.
# Maximising over the mined set rather than over all theoretically
# frequent sub-antecedents is what arules does, and it matters: a
# sub-rule pruned by min_confidence must not resurface here.
#' @noRd
.dr_sub_rule_stats <- function(x) {
  r <- x$rules
  sep_out <- if (x$type == "sequential") " -> " else ", "
  antes <- strsplit(r$antecedent, sep_out, fixed = TRUE)
  conf <- r$support / r$support_antecedent
  lift <- r$support / (r$support_antecedent * r$support_consequent)
  contained <- if (x$type == "sequential") {
    function(general, specific) .dr_contains(specific, general)
  } else {
    function(general, specific) all(general %in% specific)
  }
  by_cons <- split(seq_len(nrow(r)), r$consequent)

  out <- vapply(seq_len(nrow(r)), function(i) {
    peers <- by_cons[[r$consequent[i]]]
    gen <- Filter(function(j) {
      length(antes[[j]]) < length(antes[[i]]) &&
        contained(antes[[j]], antes[[i]])
    }, peers)
    if (length(gen) == 0L) return(c(0, 0))
    c(max(conf[gen]), max(lift[gen]))
  }, numeric(2))
  t(out)
}


# The shared contingency context every measure closes over.
#' @noRd
.dr_context <- function(x, need_sub, measure = character(0)) {
  r <- x$rules
  # Under weighting, "n" is the total weight: that is the denominator the
  # supports were computed against, so the contingency cells stay consistent.
  n <- if (is.null(x$total_weight)) x$n_transactions else x$total_weight
  sA <- r$support_antecedent
  sB <- r$support_consequent
  sAB <- r$support
  p <- list(
    n = n, sA = sA, sB = sB, sAB = sAB,
    conf = sAB / sA,
    n11 = n * sAB,
    n10 = n * (sA - sAB),
    n01 = n * (sB - sAB),
    n00 = n * (1 - sA - sB + sAB),
    nA = n * sA, nB = n * sB
  )
  # For sequential rules support(A -> B) counts ORDERED occurrences, which is
  # at most the co-occurrence P(A and B). The 2x2 table implied by the three
  # supports can therefore be inconsistent (a negative n00 cell), and the
  # measures derived from it are undefined for those rules. Say so once,
  # rather than letting NaNs leak out unexplained.
  if (x$type == "sequential" && any(measure %in% .DR_USES_N00) &&
      any(p$n00 < -1e-8)) {
    warning(sum(p$n00 < -1e-8), " of ", length(p$n00), " sequential rules ",
            "have an inconsistent contingency table (negative n00), because ",
            "ordered support is smaller than co-occurrence. Contingency-based ",
            "measures are undefined for those rules and return NA; support, ",
            "confidence and lift are unaffected.", call. = FALSE)
  }

  if (need_sub) {
    sub <- .dr_sub_rule_stats(x)
    p$sub_conf <- sub[, 1L]
    p$sub_lift <- sub[, 2L]
  }
  p$min_support <- x$params$min_support
  p$min_confidence <- x$params$min_confidence
  p
}

# Measures whose formula reads the n00 cell. That cell is the only one that
# can go inconsistent for sequential rules, so it decides whether the
# approximation warning is relevant to what the caller actually asked for.
#' @noRd
.DR_USES_N00 <- c("collectiveStrength", "oddsRatio", "yuleQ", "yuleY",
                  "kappa", "lambda", "mutualInformation", "gini", "RLD")

# Odds ratio reused by the Yule coefficients.
#' @noRd
.dr_odds <- function(p) (p$n11 * p$n00) / (p$n10 * p$n01)

# Entropy helper for the information-theoretic measures; 0 log 0 = 0.
# The guard has to mask rather than use ifelse(): ifelse() evaluates both
# branches, so log(0) would still warn even where the result is discarded.
#' @noRd
.dr_xlogx <- function(a, b) {
  n <- max(length(a), length(b))
  a <- rep_len(a, n)
  b <- rep_len(b, n)
  out <- numeric(n)
  ok <- a > 0 & b > 0
  out[ok] <- a[ok] * log(a[ok] / b[ok])
  out
}

# ---- The catalogue ----------------------------------------------------
#
# Definitions follow Hahsler's "A Probabilistic Comparison of Commonly
# Used Interest Measures for Association Rules" and match
# arules::interestMeasure(); the equivalence suite pins them numerically.

#' @noRd
.DR_MEASURES <- list(
  support = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "P(A and B): fraction of transactions holding the whole rule.",
    fun = function(p) p$sAB),
  confidence = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "P(B | A): how often the consequent follows the antecedent.",
    fun = function(p) p$conf),
  lift = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Confidence over the consequent's own support; 1 = independence.",
    fun = function(p) p$sAB / (p$sA * p$sB)),
  count = list(
    needs_sub = FALSE, range = "[0, n]",
    description = "Transactions containing the whole rule.",
    fun = function(p) p$n11),
  coverage = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "P(A): antecedent support, the rule's applicability.",
    fun = function(p) p$sA),
  rhsSupport = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "P(B): consequent support.",
    fun = function(p) p$sB),
  addedValue = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Confidence minus consequent support (Piatetsky-Shapiro change of support).",
    fun = function(p) p$conf - p$sB),
  centeredConfidence = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Confidence centred on independence; identical to added value.",
    fun = function(p) p$conf - p$sB),
  casualConfidence = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Mean of the rule's confidence and its negated counterpart.",
    fun = function(p) 1 - p$n10 / p$n * (1 / p$nA + 1 / p$nB)),
  casualSupport = list(
    needs_sub = FALSE, range = "[0, 2]",
    description = "Support of the rule plus support of its negated counterpart.",
    fun = function(p) (p$nA + p$nB - 2 * p$n10) / p$n),
  certainty = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Certainty factor (Loevinger): confidence gain relative to the room available.",
    fun = function(p) (p$conf - p$sB) / (1 - p$sB)),
  chiSquared = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Chi-squared statistic for independence on the 2x2 table (1 df).",
    fun = function(p) {
      p$n * (p$sAB - p$sA * p$sB)^2 /
        (p$sA * p$sB * (1 - p$sA) * (1 - p$sB))
    }),
  collectiveStrength = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Ratio of observed to expected co-occurrence and co-absence.",
    fun = function(p) {
      n0x <- p$n - p$nA
      nx0 <- p$n - p$nB
      p$n11 * p$n00 / (p$nA * p$nB + n0x + nx0) *
        (p$n^2 - p$nA * p$nB - n0x * nx0) / (p$n - p$n11 - p$n00)
    }),
  confirmedConfidence = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Confidence minus the confidence of the same antecedent against not-B.",
    fun = function(p) 2 * p$conf - 1),
  conviction = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Expected-to-observed ratio of the rule being wrong; Inf when confidence is 1.",
    fun = function(p) ifelse(p$conf >= 1, Inf, (1 - p$sB) / (1 - p$conf))),
  cosine = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Geometric-mean-normalised co-occurrence (Ochiai coefficient).",
    fun = function(p) p$sAB / sqrt(p$sA * p$sB)),
  counterexample = list(
    needs_sub = FALSE, range = "(-Inf, 1]",
    description = "Rate of supporting versus contradicting transactions.",
    fun = function(p) (2 * p$sAB - p$sA) / p$sAB),
  doc = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Difference of confidence: P(B|A) minus P(B|not A).",
    fun = function(p) p$conf - (p$sB - p$sAB) / (1 - p$sA)),
  fishersExactTest = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "One-sided Fisher p-value for the rule occurring more often than chance.",
    fun = function(p) {
      stats::phyper(p$n11 - 1, p$nB, p$n - p$nB, p$nA, lower.tail = FALSE)
    }),
  gini = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Gini index: impurity of B explained by splitting on A.",
    fun = function(p) {
      cf <- p$conf
      cn <- (p$sB - p$sAB) / (1 - p$sA)
      p$sA * (cf^2 + (1 - cf)^2) +
        (1 - p$sA) * (cn^2 + (1 - cn)^2) - p$sB^2 - (1 - p$sB)^2
    }),
  hyperConfidence = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "1 minus the Fisher p-value: confidence that the rule beats independence.",
    fun = function(p) {
      1 - stats::phyper(p$n11 - 1, p$nB, p$n - p$nB, p$nA, lower.tail = FALSE)
    }),
  hyperLift = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Count over the 99th percentile of its hypergeometric null; a robust lift.",
    fun = function(p) {
      p$n11 / stats::qhyper(0.99, m = p$nB, n = p$n - p$nB, k = p$nA)
    }),
  imbalance = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Imbalance ratio: how unequal the two sides' supports are.",
    fun = function(p) abs(p$sA - p$sB) / (p$sA + p$sB - p$sAB)),
  implicationIndex = list(
    needs_sub = FALSE, range = "(-Inf, Inf)",
    description = "Standardised deficit of counter-examples (Lerman's implication index).",
    fun = function(p) {
      (p$n10 - p$n * p$sA * (1 - p$sB)) / sqrt(p$n * p$sA * (1 - p$sB))
    }),
  improvement = list(
    needs_sub = TRUE, range = "(-Inf, 1]",
    description = "Confidence gain over the best more general rule in the set (0 if none).",
    fun = function(p) p$conf - p$sub_conf),
  importance = list(
    needs_sub = FALSE, range = "(-Inf, Inf)",
    description = "Log-odds weight of evidence that the antecedent brings to the consequent.",
    fun = function(p) {
      log10(((p$n11 + 1) * (p$n - p$nA + 2)) / ((p$n01 + 1) * (p$nA + 2)))
    }),
  jaccard = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Intersection over union of the two item sets.",
    fun = function(p) p$sAB / (p$sA + p$sB - p$sAB)),
  jMeasure = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Cross-entropy: information the antecedent carries about the consequent.",
    fun = function(p) {
      .dr_xlogx(p$sAB, p$sA * p$sB) +
        .dr_xlogx(p$sA - p$sAB, p$sA * (1 - p$sB))
    }),
  kappa = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Cohen's kappa: agreement beyond chance between antecedent and consequent.",
    fun = function(p) {
      obs <- p$sAB + (1 - p$sA - p$sB + p$sAB)
      exp <- p$sA * p$sB + (1 - p$sA) * (1 - p$sB)
      (obs - exp) / (1 - exp)
    }),
  kulczynski = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Mean of the two conditional probabilities, P(B|A) and P(A|B).",
    fun = function(p) 0.5 * (p$sAB / p$sA + p$sAB / p$sB)),
  lambda = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Goodman-Kruskal lambda: proportional reduction in prediction error.",
    fun = function(p) {
      max_row <- pmax(p$n11, p$n10) + pmax(p$n01, p$n00)
      max_col <- pmax(p$n11 + p$n01, p$n10 + p$n00)
      (max_row - max_col) / (p$n - max_col)
    }),
  laplace = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Laplace-corrected confidence; shrinks rules resting on few transactions.",
    fun = function(p) (p$n11 + 1) / (p$nA + 2)),
  leastContradiction = list(
    needs_sub = FALSE, range = "(-Inf, 1]",
    description = "Supporting minus contradicting transactions, scaled by consequent support.",
    fun = function(p) p$n11 / p$nB),
  lerman = list(
    needs_sub = FALSE, range = "(-Inf, Inf)",
    description = "Lerman similarity: standardised excess co-occurrence.",
    fun = function(p) sqrt(p$n) * (p$sAB - p$sA * p$sB) / sqrt(p$sA * p$sB)),
  leverage = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Piatetsky-Shapiro: observed minus expected support.",
    fun = function(p) p$sAB - p$sA * p$sB),
  LIC = list(
    needs_sub = TRUE, range = "(-Inf, Inf)",
    description = "Lift increase over the best more general rule.",
    fun = function(p) (p$sAB / (p$sA * p$sB)) / p$sub_lift),
  maxconfidence = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "The larger of the two directions' confidences.",
    fun = function(p) pmax(p$sAB / p$sA, p$sAB / p$sB)),
  mutualInformation = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Mutual information of the 2x2 table, normalised by the smaller entropy.",
    fun = function(p) {
      mi <- .dr_xlogx(p$sAB, p$sA * p$sB) +
        .dr_xlogx(p$sA - p$sAB, p$sA * (1 - p$sB)) +
        .dr_xlogx(p$sB - p$sAB, (1 - p$sA) * p$sB) +
        .dr_xlogx(1 - p$sA - p$sB + p$sAB, (1 - p$sA) * (1 - p$sB))
      hA <- -(.dr_xlogx(p$sA, 1) + .dr_xlogx(1 - p$sA, 1))
      hB <- -(.dr_xlogx(p$sB, 1) + .dr_xlogx(1 - p$sB, 1))
      mi / pmin(hA, hB)
    }),
  oddsRatio = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Odds of the consequent with the antecedent versus without it.",
    fun = function(p) .dr_odds(p)),
  phi = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Phi coefficient: Pearson correlation of the two binary indicators.",
    fun = function(p) {
      (p$sAB - p$sA * p$sB) / sqrt(p$sA * p$sB * (1 - p$sA) * (1 - p$sB))
    }),
  ralambondrainy = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Support of the counter-examples, P(A and not B); lower is better.",
    fun = function(p) p$sA - p$sAB),
  relativeRisk = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Risk of the consequent given the antecedent versus given its absence.",
    fun = function(p) p$conf / ((p$sB - p$sAB) / (1 - p$sA))),
  RLD = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Relative linkage disequilibrium: deviation from independence, scaled.",
    fun = function(p) {
      d <- p$sAB * (1 - p$sA - p$sB + p$sAB) -
        (p$sA - p$sAB) * (p$sB - p$sAB)
      ifelse(d > 0,
             ifelse(p$sB - p$sAB < p$sA - p$sAB,
                    d / (d + (p$sB - p$sAB)), d / (d + (p$sA - p$sAB))),
             ifelse(p$sAB < 1 - p$sA - p$sB + p$sAB,
                    d / (d - p$sAB), d / (d - (1 - p$sA - p$sB + p$sAB))))
    }),
  rulePowerFactor = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Support weighted by confidence; favours rules that are both frequent and reliable.",
    fun = function(p) p$sAB * p$conf),
  sebag = list(
    needs_sub = FALSE, range = "[0, Inf)",
    description = "Sebag-Schoenauer: supporting over contradicting transactions.",
    fun = function(p) p$sAB / (p$sA - p$sAB)),
  stdLift = list(
    needs_sub = FALSE, range = "[0, 1]",
    description = "Lift rescaled onto the range attainable at these supports.",
    fun = function(p) {
      s <- p$min_support
      cf <- p$min_confidence
      lambda <- pmax(pmax(p$sA + p$sB - 1, 1 / p$n) / (p$sA * p$sB),
                     4 * s / (1 + s)^2, s / (p$sA * p$sB), cf / p$sB)
      upsilon <- 1 / pmax(p$sA, p$sB)
      out <- (p$sAB / (p$sA * p$sB) - lambda) / (upsilon - lambda)
      out[is.nan(out)] <- 1
      out
    }),
  varyingLiaison = list(
    needs_sub = FALSE, range = "[-1, Inf)",
    description = "Lift minus one; deviation from independence.",
    fun = function(p) p$sAB / (p$sA * p$sB) - 1),
  yuleQ = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Yule's Q: odds ratio mapped onto [-1, 1].",
    fun = function(p) {
      o <- .dr_odds(p)
      (o - 1) / (o + 1)
    }),
  yuleY = list(
    needs_sub = FALSE, range = "[-1, 1]",
    description = "Yule's Y: square-root odds ratio mapped onto [-1, 1].",
    fun = function(p) {
      or <- .dr_odds(p)
      o <- rep(NA_real_, length(or))
      ok <- !is.na(or) & or >= 0
      o[ok] <- sqrt(or[ok])
      (o - 1) / (o + 1)
    }),
  boost = list(
    needs_sub = TRUE, range = "[0, Inf)",
    description = "Confidence boost: confidence relative to the best more general rule.",
    fun = function(p) p$conf / p$sub_conf)
)


#' Interest Measures for Mined Rules
#'
#' Computes any of the 51 association-rule interest measures for a mined
#' rule set. Call [list_measures()] for the catalogue.
#'
#' All measures are functions of the number of transactions and the three
#' supports P(A), P(B) and P(A and B), which together fix the rule's 2x2
#' contingency table. `improvement`, `boost`, `LIC` and `importance`
#' additionally compare each rule against the most favourable more
#' general rule (same consequent, a proper sub-antecedent); they are `NA`
#' -free by falling back to the independence baseline when the antecedent
#' is a single item.
#'
#' For sequential rules the 2x2 table is an approximation: the support of
#' `A -> B` counts only occurrences in the right order, so it can fall
#' below the co-occurrence of `A` and `B` and leave the implied table
#' inconsistent. When that happens `measures()` warns once and the
#' affected contingency measures return `NA`; support, confidence and
#' lift are unaffected.
#'
#' @param x A `dynarules` object.
#' @param measure Character vector of measure names, or `NULL` (the
#'   default) for the four headline measures: support, confidence, lift
#'   and count. Use `"all"` for the entire catalogue.
#' @param counts Logical; when `TRUE`, also return the four contingency
#'   counts (`n11`, `n10`, `n01`, `n00`) — the equivalent of the `table`
#'   measure in other implementations. Defaults to `FALSE`.
#' @return A tidy `data.frame` with one row per rule: `antecedent`,
#'   `consequent`, then one column per requested measure.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' measures(fit)
#' measures(fit, measure = c("kappa", "phi", "jaccard"))
#' @seealso [list_measures()], [rules()]
#' @export
measures <- function(x, measure = NULL, counts = FALSE) {
  stopifnot(inherits(x, "dynarules"), is.logical(counts), length(counts) == 1L)
  known <- names(.DR_MEASURES)

  if (is.null(measure)) {
    measure <- c("support", "confidence", "lift", "count")
  } else {
    stopifnot(is.character(measure), length(measure) >= 1L)
    if (identical(measure, "all")) measure <- known
    bad <- setdiff(measure, known)
    if (length(bad) > 0L) {
      stop("Unknown measure(s): ", paste(bad, collapse = ", "),
           ". See list_measures().", call. = FALSE)
    }
  }

  r <- x$rules
  out <- data.frame(antecedent = r$antecedent, consequent = r$consequent,
                    stringsAsFactors = FALSE)
  if (nrow(r) == 0L) {
    out[measure] <- rep(list(numeric(0)), length(measure))
    if (counts) out[c("n11", "n10", "n01", "n00")] <- rep(list(numeric(0)), 4L)
    return(out)
  }

  need_sub <- any(vapply(.DR_MEASURES[measure], `[[`, logical(1), "needs_sub"))
  p <- .dr_context(x, need_sub, measure)

  out[measure] <- lapply(measure, function(m) .DR_MEASURES[[m]]$fun(p))
  if (counts) out[c("n11", "n10", "n01", "n00")] <- p[c("n11", "n10", "n01",
                                                        "n00")]
  row.names(out) <- NULL
  out
}


#' Catalogue of Available Interest Measures
#'
#' @return A tidy `data.frame` with one row per measure: its `measure`
#'   name, the theoretical `range`, whether it compares against more
#'   general rules (`uses_subrules`), and a one-line `description`.
#' @examples
#' list_measures()
#' @seealso [measures()]
#' @export
list_measures <- function() {
  data.frame(
    measure = names(.DR_MEASURES),
    range = vapply(.DR_MEASURES, `[[`, character(1), "range"),
    uses_subrules = vapply(.DR_MEASURES, `[[`, logical(1), "needs_sub"),
    description = vapply(.DR_MEASURES, `[[`, character(1), "description"),
    stringsAsFactors = FALSE, row.names = NULL
  )
}
