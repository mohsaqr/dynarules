# ---- Inference: bootstrap stability and permutation significance ----

#' Bootstrap Stability of Mined Rules
#'
#' @description
#' Assesses how reproducible each mined rule is under resampling.
#' Transactions are resampled with replacement `iter` times; each resample
#' is re-mined with the original thresholds. A rule's `recovery` is the
#' fraction of resamples in which it is rediscovered; its metric intervals
#' are percentile bootstrap CIs over the resamples that recovered it.
#'
#' @param x A `dynarules` object.
#' @param iter Integer. Number of bootstrap resamples. Default 200.
#' @param conf Numeric. CI coverage. Default 0.95.
#' @param seed Integer or NULL. Seed for reproducibility.
#'
#' @return An object of class `"dynarules_boot"` with `$stability`, a tidy
#'   data.frame (one row per original rule): antecedent, consequent,
#'   recovery, and mean / lower / upper for support, confidence, and lift.
#'
#' @examples
#' trans <- list(c("plan", "discuss", "reflect"),
#'               c("plan", "discuss", "execute"),
#'               c("plan", "reflect"),
#'               c("discuss", "reflect"),
#'               c("plan", "discuss", "reflect"))
#' fit <- dynarules(trans, min_support = 0.3, min_lift = 0)
#' bs <- bootstrap_rules(fit, iter = 50, seed = 1)
#' bs
#'
#' @references
#' Epskamp, S., Borsboom, D., & Fried, E. I. (2018). Estimating
#' psychological networks and their accuracy. \emph{Behavior Research
#' Methods}, 50, 195--212.
#'
#' @export
bootstrap_rules <- function(x, iter = 200L, conf = 0.95, seed = NULL) {
  stopifnot(inherits(x, "dynarules"),
            is.numeric(iter), length(iter) == 1L, iter >= 2,
            is.numeric(conf), length(conf) == 1L, conf > 0, conf < 1)
  iter <- as.integer(iter)
  if (!is.null(seed)) set.seed(seed)
  if (nrow(x$rules) == 0L) {
    stop("No rules to bootstrap; relax the mining thresholds.",
         call. = FALSE)
  }

  tr <- x$transactions
  obs_keys <- paste(x$rules$antecedent, x$rules$consequent, sep = " => ")

  draws <- lapply(seq_len(iter), function(b) {
    idx <- sample.int(tr$n_transactions, replace = TRUE)
    fit_b <- dynarules(.dr_resample(tr, idx), type = x$type,
                       min_support = x$params$min_support,
                       min_confidence = x$params$min_confidence,
                       min_lift = x$params$min_lift,
                       max_length = x$params$max_length)
    r_b <- fit_b$rules
    r_b$key <- paste(r_b$antecedent, r_b$consequent, sep = " => ")
    r_b[r_b$key %in% obs_keys,
        c("key", "support", "confidence", "lift"), drop = FALSE]
  })
  all_draws <- do.call(rbind, draws)

  probs <- c((1 - conf) / 2, 1 - (1 - conf) / 2)
  stat_rows <- lapply(seq_along(obs_keys), function(i) {
    hits <- all_draws[all_draws$key == obs_keys[i], , drop = FALSE]
    ci <- function(v) {
      if (nrow(hits) == 0L) return(c(NA_real_, NA_real_, NA_real_))
      c(mean(v), stats::quantile(v, probs, names = FALSE))
    }
    s <- ci(hits$support); cf <- ci(hits$confidence); lf <- ci(hits$lift)
    data.frame(
      antecedent = x$rules$antecedent[i],
      consequent = x$rules$consequent[i],
      recovery = nrow(hits) / iter,
      support_mean = s[1L], support_lower = s[2L], support_upper = s[3L],
      confidence_mean = cf[1L], confidence_lower = cf[2L],
      confidence_upper = cf[3L],
      lift_mean = lf[1L], lift_lower = lf[2L], lift_upper = lf[3L],
      stringsAsFactors = FALSE
    )
  })
  stability <- do.call(rbind, stat_rows)
  stability <- stability[order(-stability$recovery, -stability$lift_mean), ,
                         drop = FALSE]
  row.names(stability) <- NULL

  structure(list(
    stability = stability,
    observed = x$rules,
    type = x$type,
    iter = iter,
    conf = conf,
    params = x$params,
    n_transactions = tr$n_transactions
  ), class = "dynarules_boot")
}


# Rebuild a dyna_transactions object from a resampled index vector,
# preserving whichever forms (sequences / set matrix) the original had.
#' @noRd
.dr_resample <- function(tr, idx) {
  if (!is.null(tr$sequences)) {
    return(.tr_from_sequences(tr$sequences[idx],
                              ids = if (is.null(tr$ids)) NULL else {
                                tr$ids[idx, , drop = FALSE]
                              },
                              unit = tr$unit, source = tr$source))
  }
  structure(list(
    sequences = NULL,
    matrix = tr$matrix[idx, , drop = FALSE],
    items = tr$items,
    ids = NULL,
    n_transactions = length(idx),
    unit = tr$unit,
    source = tr$source
  ), class = "dyna_transactions")
}


#' Permutation Significance of Mined Rules
#'
#' @description
#' Tests each rule's lift against an explicit null. For co-occurrence
#' rules the null is item independence: each item column of the
#' transaction matrix is permuted independently, preserving every item's
#' frequency while destroying co-occurrence. For sequential rules the
#' null is order-irrelevance: the events \emph{within} each transaction
#' are shuffled, preserving exactly which items co-occur while destroying
#' their order -- so a significant sequential rule is informative
#' \emph{beyond} co-occurrence.
#'
#' P-values are `(sum(lift_perm >= lift_obs) + 1) / (iter + 1)`.
#'
#' @param x A `dynarules` object.
#' @param iter Integer. Number of permutations. Default 200.
#' @param correction Character. Multiple-comparison correction passed to
#'   [stats::p.adjust()]. Default `"BH"`.
#' @param seed Integer or NULL. Seed for reproducibility.
#'
#' @return An object of class `"dynarules_perm"` with `$tests`, a tidy
#'   data.frame (one row per rule): antecedent, consequent, lift,
#'   lift_null (mean permuted lift), p, p_adj, significant.
#'
#' @examples
#' trans <- list(c("plan", "discuss", "reflect"),
#'               c("plan", "discuss", "execute"),
#'               c("plan", "discuss", "reflect"),
#'               c("discuss", "reflect"))
#' fit <- dynarules(trans, min_support = 0.3, min_lift = 0)
#' pt <- permute_rules(fit, iter = 100, seed = 1)
#' pt
#'
#' @export
permute_rules <- function(x, iter = 200L, correction = "BH", seed = NULL) {
  stopifnot(inherits(x, "dynarules"),
            is.numeric(iter), length(iter) == 1L, iter >= 10)
  iter <- as.integer(iter)
  correction <- match.arg(correction, stats::p.adjust.methods)
  if (!is.null(seed)) set.seed(seed)
  if (nrow(x$rules) == 0L) {
    stop("No rules to test; relax the mining thresholds.", call. = FALSE)
  }

  tr <- x$transactions
  sep <- if (x$type == "sequential") " -> " else ", "
  antes <- strsplit(x$rules$antecedent, sep, fixed = TRUE)
  conss <- strsplit(x$rules$consequent, sep, fixed = TRUE)

  lift_fn <- if (x$type == "sequential") {
    function(seqs, set_mat) {
      vapply(seq_along(antes), function(i) {
        full <- c(antes[[i]], conss[[i]])
        sup_ab <- .dr_count_pattern(seqs, full)
        sup_a <- .dr_count_pattern(seqs, antes[[i]])
        sup_b <- .dr_count_pattern(seqs, conss[[i]])
        n <- length(seqs)
        if (sup_a == 0L || sup_b == 0L) return(0)
        (sup_ab / n) / ((sup_a / n) * (sup_b / n))
      }, numeric(1))
    }
  } else {
    function(seqs, set_mat) {
      n <- nrow(set_mat)
      vapply(seq_along(antes), function(i) {
        a_mask <- rowSums(set_mat[, antes[[i]], drop = FALSE]) ==
          length(antes[[i]])
        b_mask <- rowSums(set_mat[, conss[[i]], drop = FALSE]) ==
          length(conss[[i]])
        sup_a <- sum(a_mask); sup_b <- sum(b_mask)
        if (sup_a == 0L || sup_b == 0L) return(0)
        (sum(a_mask & b_mask) / n) / ((sup_a / n) * (sup_b / n))
      }, numeric(1))
    }
  }

  obs_lift <- lift_fn(tr$sequences, tr$matrix)

  perm_mat <- vapply(seq_len(iter), function(b) {
    if (x$type == "sequential") {
      seqs_p <- lapply(tr$sequences, function(s) s[sample.int(length(s))])
      lift_fn(seqs_p, NULL)
    } else {
      set_p <- apply(tr$matrix, 2L, function(col) {
        col[sample.int(length(col))]
      })
      lift_fn(NULL, set_p)
    }
  }, numeric(nrow(x$rules)))
  perm_mat <- matrix(perm_mat, nrow = nrow(x$rules))

  p <- (rowSums(perm_mat >= obs_lift) + 1) / (iter + 1)
  p_adj <- stats::p.adjust(p, method = correction)

  tests <- data.frame(
    antecedent = x$rules$antecedent,
    consequent = x$rules$consequent,
    lift = obs_lift,
    lift_null = rowMeans(perm_mat),
    p = p,
    p_adj = p_adj,
    significant = p_adj < 0.05,
    stringsAsFactors = FALSE
  )
  tests <- tests[order(tests$p_adj, -tests$lift), , drop = FALSE]
  row.names(tests) <- NULL

  structure(list(
    tests = tests,
    type = x$type,
    iter = iter,
    correction = correction,
    null = if (x$type == "sequential") "within-transaction order shuffle"
           else "independent item-column permutation",
    n_transactions = tr$n_transactions
  ), class = "dynarules_perm")
}
