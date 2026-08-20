# ---- Rule mining front door ----

# Separator used internally to key itemsets/patterns in lookup
# environments. Never user-visible.
.DR_SEP <- "\x1f"

#' Mine Association or Sequential Rules
#'
#' @description
#' The single entry point for rule mining. `type = "cooccurrence"` mines
#' classic association rules (level-wise Apriori with full candidate
#' pruning): order within a transaction is ignored. `type = "sequential"`
#' mines order-aware rules (generalized sequential patterns): a rule
#' `plan -> discuss => reflect` states that transactions containing
#' `plan` followed (not necessarily immediately) by `discuss` tend to
#' contain `reflect` after both.
#'
#' Accepts a ready `transactions()` object, or raw data plus the event-log
#' grammar arguments, which are forwarded to [transactions()].
#'
#' @param x A `dyna_transactions` object, or raw data accepted by
#'   [transactions()] (long event log, wide data.frame, list, binary
#'   matrix).
#' @param type Character. `"cooccurrence"` (default) or `"sequential"`.
#' @param min_support Numeric, above 0 and at most 1. Minimum fraction of
#'   transactions containing the itemset/pattern. Default 0.1.
#' @param min_confidence Numeric between 0 and 1. Default 0.5.
#' @param min_lift Numeric >= 0. Default 1.
#' @param weights Optional numeric vector of transaction weights, one per
#'   transaction. Support becomes weighted support: the share of total
#'   weight rather than the share of transactions. `NULL` (default)
#'   weights every transaction equally.
#' @param gap Maximum number of events allowed between consecutive items
#'   of a sequential pattern. `NULL` (default) places no limit, i.e.
#'   ordinary non-contiguous containment; `gap = 1` requires the items to
#'   be adjacent. Sequential mining only.
#' @param min_gap Minimum number of events between consecutive items.
#'   Sequential mining only.
#' @param window_size Maximum span, in events, from the first item of a
#'   pattern to its last. Sequential mining only. (Distinct from
#'   `window`, which cuts the transactions themselves.)
#' @param min_length Integer. Minimum number of items in a rule
#'   (antecedent plus consequent). Default `2`.
#' @param appearance Optional list restricting where items may occur:
#'   `lhs` and `rhs` whitelist the items allowed on each side, and `none`
#'   drops items from the data before mining. `NULL` (default) places no
#'   restriction.
#' @param max_length Integer >= 2. Maximum itemset/pattern size. Default 5.
#' @param actor,action,time,session,unit,window,step Event-log grammar,
#'   forwarded to [transactions()] when `x` is raw data.
#'
#' @return An object of class `"dynarules"`:
#' \describe{
#'   \item{rules}{Tidy data.frame, one row per rule: antecedent,
#'     consequent, support, confidence, lift, conviction, count,
#'     n_transactions. Sequential antecedents/consequents use
#'     `" -> "` between ordered items; co-occurrence uses `", "`.}
#'   \item{frequent}{Tidy data.frame of frequent itemsets/patterns.}
#'   \item{type, items, n_transactions, params}{Metadata.}
#'   \item{transactions}{The `dyna_transactions` object mined, kept so
#'     [bootstrap_rules()] and [permute_rules()] can re-mine.}
#' }
#'
#' @details
#' Support of a sequential pattern is the fraction of transactions whose
#' ordered sequence contains the pattern as a (not necessarily contiguous)
#' subsequence. Both miners use downward closure: every sub-itemset /
#' subsequence of a frequent set is itself frequent, which the candidate
#' pruning step exploits.
#'
#' @examples
#' log <- data.frame(
#'   student = rep(c("s1", "s2", "s3", "s4"), each = 3),
#'   code = c("plan", "discuss", "reflect",
#'            "plan", "discuss", "execute",
#'            "plan", "reflect", "discuss",
#'            "discuss", "plan", "reflect"),
#'   stringsAsFactors = FALSE
#' )
#' fit <- dynarules(log, actor = "student", action = "code",
#'                  type = "sequential", min_support = 0.25)
#' fit
#'
#' @seealso [transactions()], [rules()], [as_network()],
#'   [bootstrap_rules()], [permute_rules()]
#'
#' @export
dynarules <- function(x,
                      type = c("cooccurrence", "sequential"),
                      min_support = 0.1,
                      min_confidence = 0.5,
                      min_lift = 1,
                      min_length = 2L,
                      max_length = 5L,
                      appearance = NULL,
                      actor = NULL,
                      action = NULL,
                      time = NULL,
                      session = NULL,
                      unit = c("session", "actor", "window"),
                      window = NULL,
                      step = NULL,
                      weights = NULL,
                      gap = NULL,
                      min_gap = NULL,
                      window_size = NULL) {
  type <- match.arg(type)
  stopifnot(
    is.numeric(min_support), length(min_support) == 1L,
    min_support > 0, min_support <= 1,
    is.numeric(min_confidence), length(min_confidence) == 1L,
    min_confidence >= 0, min_confidence <= 1,
    is.numeric(min_lift), length(min_lift) == 1L, min_lift >= 0,
    is.numeric(max_length), length(max_length) == 1L, max_length >= 2,
    is.numeric(min_length), length(min_length) == 1L, min_length >= 2,
    min_length <= max_length
  )
  max_length <- as.integer(max_length)
  min_length <- as.integer(min_length)
  appearance <- .dr_check_appearance(appearance)
  .dr_check_gap(gap, min_gap, window_size)
  if (type == "cooccurrence" &&
      !all(vapply(list(gap, min_gap, window_size), is.null, logical(1)))) {
    stop("`gap`, `min_gap` and `window_size` constrain the ORDER of events, ",
         "so they only apply to type = \"sequential\".", call. = FALSE)
  }

  tr <- if (inherits(x, "dyna_transactions")) x else {
    transactions(x, actor = actor, action = action, time = time,
                 session = session, unit = unit, window = window,
                 step = step, weights = weights)
  }
  if (length(appearance$none) > 0L) tr <- .dr_drop_items(tr, appearance$none)
  if (type == "sequential" && is.null(tr$sequences)) {
    stop("Sequential mining needs ordered sequences; this transaction set ",
         "was built from a binary matrix (set form only).", call. = FALSE)
  }

  params <- list(min_support = min_support, min_confidence = min_confidence,
                 min_lift = min_lift, min_length = min_length,
                 max_length = max_length, appearance = appearance,
                 gap = gap, min_gap = min_gap, window_size = window_size)

  mined <- if (type == "cooccurrence") {
    .mine_cooccurrence(tr, params)
  } else {
    .mine_sequential(tr, params)
  }

  structure(list(
    rules = mined$rules,
    frequent = mined$frequent,
    type = type,
    items = tr$items,
    n_transactions = tr$n_transactions,
    total_weight = sum(.dr_weights(tr)),
    params = params,
    transactions = tr
  ), class = "dynarules")
}


# `appearance` restricts where items may show up: `lhs`/`rhs` whitelist the
# antecedent/consequent side, `none` drops items from the data entirely.
#' @noRd
.dr_check_appearance <- function(appearance) {
  if (is.null(appearance)) {
    return(list(lhs = NULL, rhs = NULL, none = NULL))
  }
  stopifnot(is.list(appearance))
  unknown <- setdiff(names(appearance), c("lhs", "rhs", "none"))
  if (length(unknown) > 0L) {
    stop("`appearance` accepts only lhs, rhs and none; got: ",
         paste(unknown, collapse = ", "), call. = FALSE)
  }
  stopifnot(all(vapply(appearance, is.character, logical(1))))
  list(lhs = appearance$lhs, rhs = appearance$rhs, none = appearance$none)
}

#' @noRd
.dr_check_gap <- function(gap, min_gap, window_size) {
  chk <- function(v, nm) {
    if (is.null(v)) return(invisible(NULL))
    if (!is.numeric(v) || length(v) != 1L || v < 1) {
      stop("`", nm, "` must be a single number >= 1.", call. = FALSE)
    }
  }
  chk(gap, "gap"); chk(min_gap, "min_gap"); chk(window_size, "window_size")
  if (!is.null(gap) && !is.null(min_gap) && min_gap > gap) {
    stop("`min_gap` cannot exceed `gap`.", call. = FALSE)
  }
  invisible(NULL)
}

#' @noRd
.dr_drop_items <- function(tr, none) {
  keep <- setdiff(tr$items, none)
  if (length(keep) == 0L) {
    stop("`appearance$none` removed every item.", call. = FALSE)
  }
  tr$matrix <- tr$matrix[, keep, drop = FALSE]
  tr$items <- keep
  if (!is.null(tr$sequences)) {
    tr$sequences <- lapply(tr$sequences, function(s) s[s %in% keep])
  }
  tr
}

# ---- Shared frequent-set bookkeeping ----

# One frequent itemset/pattern: character vector of items (order meaningful
# for sequential), count, support. Stored in a list per level; supports are
# also mirrored into a hashed environment for O(1) rule-time lookup.
#' @noRd
.dr_support_env <- function(levels_list) {
  env <- new.env(hash = TRUE, parent = emptyenv())
  invisible(lapply(levels_list, function(level) {
    lapply(level, function(fi) {
      env[[paste(fi$items, collapse = .DR_SEP)]] <- fi$support
    })
  }))
  env
}


#' @noRd
.dr_frequent_df <- function(levels_list, sep_out) {
  rows <- lapply(seq_along(levels_list), function(k) {
    level <- levels_list[[k]]
    if (is.null(level) || length(level) == 0L) return(NULL)
    data.frame(
      pattern = vapply(level, function(fi) {
        paste(fi$items, collapse = sep_out)
      }, character(1)),
      size = k,
      support = vapply(level, `[[`, numeric(1), "support"),
      count = vapply(level, `[[`, numeric(1), "count"),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, Filter(Negate(is.null), rows))
  if (is.null(out)) {
    out <- data.frame(pattern = character(0), size = integer(0),
                      support = numeric(0), count = numeric(0),
                      stringsAsFactors = FALSE)
  }
  row.names(out) <- NULL
  out
}


#' @noRd
.dr_empty_rules <- function() {
  data.frame(
    antecedent = character(0), consequent = character(0),
    support = numeric(0), confidence = numeric(0),
    lift = numeric(0), conviction = numeric(0),
    support_antecedent = numeric(0), support_consequent = numeric(0),
    count = integer(0), n_transactions = integer(0),
    stringsAsFactors = FALSE
  )
}


# ---- Co-occurrence miner (level-wise Apriori) ----

#' @noRd
.mine_cooccurrence <- function(tr, params) {
  set_mat <- tr$matrix
  w <- .dr_weights(tr)
  # Weighted support: the denominator is total weight, and every count is a
  # weight sum. With the default unit weights this is exactly the unweighted
  # computation, so there is one code path rather than two.
  n_trans <- sum(w)
  min_count <- params$min_support * n_trans

  item_counts <- colSums(set_mat * w)
  freq_mask <- item_counts >= min_count
  items <- tr$items[freq_mask]
  if (length(items) == 0L) {
    return(list(rules = .dr_empty_rules(),
                frequent = .dr_frequent_df(list(), ", ")))
  }
  set_mat <- set_mat[, items, drop = FALSE]
  item_counts <- item_counts[freq_mask]

  levels_list <- list()
  levels_list[[1L]] <- lapply(seq_along(items), function(i) {
    list(items = items[i], count = item_counts[[i]],
         support = item_counts[[i]] / n_trans)
  })

  # Level 2 in one matrix product.
  if (params$max_length >= 2L && length(items) >= 2L) {
    co <- crossprod(set_mat * 1L, set_mat * w)
    pair_idx <- which(upper.tri(co) & co >= min_count, arr.ind = TRUE)
    if (nrow(pair_idx) > 0L) {
      levels_list[[2L]] <- lapply(seq_len(nrow(pair_idx)), function(r) {
        i <- pair_idx[r, 1L]; j <- pair_idx[r, 2L]
        list(items = c(items[i], items[j]), count = co[i, j],
             support = co[i, j] / n_trans)
      })
    }
  }

  # Levels >= 3: join + full subset prune + count.
  k <- 3L
  while (k <= params$max_length && length(levels_list) == k - 1L &&
         length(levels_list[[k - 1L]]) >= 2L) {
    prev_items <- lapply(levels_list[[k - 1L]], `[[`, "items")
    prev_keys <- vapply(prev_items, paste, character(1), collapse = .DR_SEP)
    candidates <- .dr_join_sets(prev_items, k)
    candidates <- Filter(function(cand) {
      subs <- utils::combn(cand, k - 1L, simplify = FALSE)
      all(vapply(subs, paste, character(1), collapse = .DR_SEP)
          %in% prev_keys)
    }, candidates)
    if (length(candidates) == 0L) break

    freq_k <- Filter(Negate(is.null), lapply(candidates, function(cand) {
      cnt <- sum(w[rowSums(set_mat[, cand, drop = FALSE]) == length(cand)])
      if (cnt < min_count) return(NULL)
      list(items = cand, count = cnt, support = cnt / n_trans)
    }))
    if (length(freq_k) == 0L) break
    levels_list[[k]] <- freq_k
    k <- k + 1L
  }

  rules <- .dr_rules_from_levels(levels_list, n_trans, params,
                                 ordered = FALSE, sep_out = ", ")
  list(rules = rules, frequent = .dr_frequent_df(levels_list, ", "))
}


# Apriori join for unordered itemsets: merge two sorted (k-1)-sets sharing
# their first k-2 items.
#' @noRd
.dr_join_sets <- function(prev_items, k) {
  n <- length(prev_items)
  if (n < 2L) return(list())
  pairs <- utils::combn(n, 2L, simplify = FALSE)
  Filter(Negate(is.null), lapply(pairs, function(p) {
    a <- prev_items[[p[1L]]]
    b <- prev_items[[p[2L]]]
    if (k > 2L && !identical(a[seq_len(k - 2L)], b[seq_len(k - 2L)])) {
      return(NULL)
    }
    last <- sort(c(a[k - 1L], b[k - 1L]))
    if (last[1L] == last[2L]) return(NULL)
    c(a[seq_len(k - 2L)], last)
  }))
}


# ---- Sequential miner (generalized sequential patterns) ----

# Does ordered vector `s` contain `p` as a (not necessarily contiguous)
# subsequence, subject to the optional gap and window constraints?
#
# Unconstrained, a greedy first-match scan is exact: taking the earliest
# possible position for each item never rules out a later match. Under a
# maximum gap it is NOT exact -- committing to the first occurrence can
# strand the rest of the pattern past the gap limit when a later
# occurrence would have matched. The constrained path therefore carries
# the full set of reachable positions at each step rather than a single
# one.
#
# Gaps are counted in EVENTS, not clock time: transactions store the
# ordered actions, not their timestamps.
#' @noRd
.dr_contains <- function(s, p, gap = NULL, min_gap = NULL, window = NULL) {
  if (is.null(gap) && is.null(min_gap) && is.null(window)) {
    pos <- Reduce(function(at, item) {
      if (is.na(at) || at >= length(s)) return(NA_integer_)
      hits <- which(s[(at + 1L):length(s)] == item)
      if (length(hits) == 0L) NA_integer_ else at + hits[1L]
    }, p, init = 0L)
    return(!is.na(pos))
  }
  starts <- which(s == p[1L])
  if (length(starts) == 0L) return(FALSE)
  if (length(p) == 1L) return(TRUE)
  any(vapply(starts, function(st) {
    length(.dr_reach(s, p, st, gap, min_gap, window)) > 0L
  }, logical(1)))
}

# Positions at which the pattern can END, given it started at `start`.
# Empty means no admissible embedding from that start.
#' @noRd
.dr_reach <- function(s, p, start, gap, min_gap, window) {
  n <- length(s)
  limit <- if (is.null(window)) n else min(n, start + window)
  lo_gap <- if (is.null(min_gap)) 1L else max(1L, as.integer(min_gap))
  hi_gap <- if (is.null(gap)) n else as.integer(gap)
  Reduce(function(prev, item) {
    if (length(prev) == 0L) return(integer(0))
    cand <- which(s == item)
    cand <- cand[cand <= limit & cand > min(prev)]
    if (length(cand) == 0L) return(integer(0))
    cand[vapply(cand, function(cc) {
      d <- cc - prev
      any(d >= lo_gap & d <= hi_gap)
    }, logical(1))]
  }, p[-1L], init = start)
}


#' @noRd
.dr_count_pattern <- function(seqs, p, w, gap = NULL, min_gap = NULL,
                              window = NULL) {
  sum(w[vapply(seqs, .dr_contains, logical(1), p = p, gap = gap,
               min_gap = min_gap, window = window)])
}


#' @noRd
.mine_sequential <- function(tr, params) {
  seqs <- tr$sequences
  w <- .dr_weights(tr)
  n_trans <- sum(w)
  min_count <- params$min_support * n_trans

  # Level 1: containment of a single item == presence in the set matrix.
  item_counts <- colSums(tr$matrix * w)
  freq_mask <- item_counts >= min_count
  items <- tr$items[freq_mask]
  if (length(items) == 0L) {
    return(list(rules = .dr_empty_rules(),
                frequent = .dr_frequent_df(list(), " -> ")))
  }
  item_counts <- item_counts[freq_mask]

  levels_list <- list()
  levels_list[[1L]] <- lapply(seq_along(items), function(i) {
    list(items = items[i], count = item_counts[[i]],
         support = item_counts[[i]] / n_trans)
  })

  gap <- params$gap
  min_gap <- params$min_gap
  window_size <- params$window_size

  # Level 2: all ordered pairs, including repeats (A -> A).
  if (params$max_length >= 2L) {
    grid <- expand.grid(a = items, b = items, stringsAsFactors = FALSE)
    freq2 <- Filter(Negate(is.null),
                    lapply(seq_len(nrow(grid)), function(r) {
      p <- c(grid$a[r], grid$b[r])
      cnt <- .dr_count_pattern(seqs, p, w, gap, min_gap, window_size)
      if (cnt < min_count) return(NULL)
      list(items = p, count = cnt, support = cnt / n_trans)
    }))
    if (length(freq2) > 0L) levels_list[[2L]] <- freq2
  }

  # Levels >= 3: GSP join (drop-first of a == drop-last of b), full
  # subsequence prune, containment count.
  k <- 3L
  while (k <= params$max_length && length(levels_list) == k - 1L &&
         length(levels_list[[k - 1L]]) >= 1L) {
    prev_items <- lapply(levels_list[[k - 1L]], `[[`, "items")
    prev_keys <- vapply(prev_items, paste, character(1), collapse = .DR_SEP)
    # A maximum gap breaks the usual subsequence prune: dropping an item
    # from the MIDDLE of a pattern widens the gap between its neighbours,
    # so a frequent pattern can have an infrequent drop-one subsequence.
    # Dropping the first or last item never widens an interior gap, so the
    # GSP join itself stays valid -- only the prune has to go.
    candidates <- .dr_join_seqs(prev_items, prev_keys, k,
                                prune = is.null(gap))
    if (length(candidates) == 0L) break

    freq_k <- Filter(Negate(is.null), lapply(candidates, function(cand) {
      cnt <- .dr_count_pattern(seqs, cand, w, gap, min_gap, window_size)
      if (cnt < min_count) return(NULL)
      list(items = cand, count = cnt, support = cnt / n_trans)
    }))
    if (length(freq_k) == 0L) break
    levels_list[[k]] <- freq_k
    k <- k + 1L
  }

  rules <- .dr_rules_from_levels(levels_list, n_trans, params,
                                 ordered = TRUE, sep_out = " -> ")
  list(rules = rules, frequent = .dr_frequent_df(levels_list, " -> "))
}


# GSP join: patterns a, b of length k-1 join to c(a, last(b)) when
# a[-1] == b[-(k-1)]. Prune requires every drop-one-position subsequence
# to be frequent.
#' @noRd
.dr_join_seqs <- function(prev_items, prev_keys, k, prune = TRUE) {
  n <- length(prev_items)
  grid <- expand.grid(i = seq_len(n), j = seq_len(n))
  cands <- Filter(Negate(is.null), lapply(seq_len(nrow(grid)), function(r) {
    a <- prev_items[[grid$i[r]]]
    b <- prev_items[[grid$j[r]]]
    if (!identical(a[-1L], b[-(k - 1L)])) return(NULL)
    c(a, b[k - 1L])
  }))
  cands <- cands[!duplicated(vapply(cands, paste, character(1),
                                    collapse = .DR_SEP))]
  if (!prune) return(cands)
  Filter(function(cand) {
    subs <- lapply(seq_len(k), function(drop) cand[-drop])
    all(vapply(subs, paste, character(1), collapse = .DR_SEP)
        %in% prev_keys)
  }, cands)
}


# ---- Rule generation (shared) ----

# For every frequent set/pattern of size >= 2, emit rules by splitting.
# Unordered: every non-empty proper subset is an antecedent. Ordered:
# every prefix is an antecedent, the remaining suffix the consequent
# (order is preserved, so only the k-1 cut points are valid splits).
#' @noRd
.dr_rules_from_levels <- function(levels_list, n_trans, params, ordered,
                                  sep_out) {
  if (length(levels_list) < 2L) return(.dr_empty_rules())
  support_env <- .dr_support_env(levels_list)

  higher <- unlist(lapply(seq(2L, length(levels_list)), function(k) {
    levels_list[[k]]
  }), recursive = FALSE)

  app <- params$appearance
  min_length <- if (is.null(params$min_length)) 2L else params$min_length

  rows <- lapply(higher, function(fi) {
    itemset <- fi$items
    k <- length(itemset)
    if (k < min_length) return(NULL)
    splits <- if (ordered) {
      lapply(seq_len(k - 1L), function(j) {
        list(ante = itemset[seq_len(j)], cons = itemset[seq(j + 1L, k)])
      })
    } else {
      unlist(lapply(seq_len(k - 1L), function(size) {
        lapply(utils::combn(k, size, simplify = FALSE), function(idx) {
          list(ante = itemset[idx], cons = itemset[-idx])
        })
      }), recursive = FALSE)
    }

    if (!is.null(app$lhs) || !is.null(app$rhs)) {
      splits <- Filter(function(sp) {
        (is.null(app$lhs) || all(sp$ante %in% app$lhs)) &&
          (is.null(app$rhs) || all(sp$cons %in% app$rhs))
      }, splits)
    }

    kept <- lapply(splits, function(sp) {
      sup_a <- support_env[[paste(sp$ante, collapse = .DR_SEP)]]
      sup_b <- support_env[[paste(sp$cons, collapse = .DR_SEP)]]
      if (is.null(sup_a) || is.null(sup_b)) return(NULL)
      confidence <- fi$support / sup_a
      if (confidence < params$min_confidence) return(NULL)
      lift <- fi$support / (sup_a * sup_b)
      if (lift < params$min_lift) return(NULL)
      conviction <- if (confidence >= 1) Inf else (1 - sup_b) / (1 - confidence)
      data.frame(
        antecedent = paste(sp$ante, collapse = sep_out),
        consequent = paste(sp$cons, collapse = sep_out),
        support = fi$support,
        confidence = confidence,
        lift = lift,
        conviction = conviction,
        support_antecedent = sup_a,
        support_consequent = sup_b,
        count = if (isTRUE(all.equal(fi$count, round(fi$count)))) {
          as.integer(round(fi$count))
        } else fi$count,
        n_transactions = n_trans,
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, Filter(Negate(is.null), kept))
  })

  out <- do.call(rbind, Filter(Negate(is.null), rows))
  if (is.null(out) || nrow(out) == 0L) return(.dr_empty_rules())
  out <- out[order(-out$lift, -out$confidence), , drop = FALSE]
  row.names(out) <- NULL
  out
}
