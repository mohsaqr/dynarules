# Operations on a transaction set: describing it, reshaping it, sampling
# from it, and building one from a file or from scratch. Every verb takes
# or returns a `dyna_transactions` object or a tidy data.frame, so none of
# them force the caller to reach into the object.

#' Item Frequencies
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param top Optional integer; keep only the `top` most frequent items.
#' @return A tidy `data.frame`: `item`, `count`, `support`, ordered by
#'   descending support.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
#' item_frequency(tr)
#' @seealso [transactions()], [cross_table()]
#' @export
item_frequency <- function(x, top = NULL) {
  x <- .dr_as_transactions(x)
  out <- summary(x)
  out <- out[order(-out$support, out$item), , drop = FALSE]
  if (!is.null(top) && nrow(out) > top) out <- out[seq_len(top), , drop = FALSE]
  row.names(out) <- NULL
  out
}


#' Pairwise Item Co-Occurrence
#'
#' The cross table of every item pair, in tidy long form rather than as a
#' matrix.
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param measure `"count"` (default) for the number of transactions
#'   holding both items, `"support"` for that as a fraction, or `"lift"`
#'   for the ratio of joint to expected support.
#' @param diagonal Logical; keep the item-with-itself rows. Default
#'   `FALSE`. For `measure = "lift"` those rows are `NA`: an item's lift
#'   against itself is not defined.
#' @return A tidy `data.frame`: `item1`, `item2`, `value`.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
#' cross_table(tr)
#' cross_table(tr, measure = "lift")
#' @seealso [item_frequency()], [affinity()]
#' @export
cross_table <- function(x, measure = c("count", "support", "lift"),
                        diagonal = FALSE) {
  x <- .dr_as_transactions(x)
  measure <- match.arg(measure)
  mat <- x$matrix * 1L
  n <- x$n_transactions
  co <- crossprod(mat)
  items <- x$items

  grid <- expand.grid(i = seq_along(items), j = seq_along(items))
  if (!diagonal) grid <- grid[grid$i != grid$j, , drop = FALSE]
  joint <- co[cbind(grid$i, grid$j)]
  supp <- colSums(mat) / n

  value <- switch(measure,
    count = joint,
    support = joint / n,
    # An item's lift against itself is not a lift; it is NA, as in arules.
    lift = ifelse(grid$i == grid$j, NA_real_,
                  (joint / n) / (supp[grid$i] * supp[grid$j]))
  )
  out <- data.frame(item1 = items[grid$i], item2 = items[grid$j],
                    value = as.numeric(value), stringsAsFactors = FALSE)
  out <- out[order(-out$value, out$item1, out$item2), , drop = FALSE]
  row.names(out) <- NULL
  out
}


#' Item Affinity
#'
#' Jaccard similarity between every pair of items: how often they occur
#' together relative to how often either occurs at all.
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @return A tidy `data.frame`: `item1`, `item2`, `affinity`.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
#' affinity(tr)
#' @seealso [cross_table()]
#' @export
affinity <- function(x) {
  x <- .dr_as_transactions(x)
  mat <- x$matrix * 1L
  co <- crossprod(mat)
  cnt <- colSums(mat)
  items <- x$items
  grid <- expand.grid(i = seq_along(items), j = seq_along(items))
  grid <- grid[grid$i != grid$j, , drop = FALSE]
  joint <- co[cbind(grid$i, grid$j)]
  union <- cnt[grid$i] + cnt[grid$j] - joint
  out <- data.frame(item1 = items[grid$i], item2 = items[grid$j],
                    affinity = ifelse(union == 0, 0, joint / union),
                    stringsAsFactors = FALSE)
  out <- out[order(-out$affinity, out$item1, out$item2), , drop = FALSE]
  row.names(out) <- NULL
  out
}


#' Support of Arbitrary Itemsets
#'
#' Support of itemsets you name yourself, without mining. Useful for
#' checking a hypothesis against the data directly.
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param itemsets A character vector (one itemset) or a list of character
#'   vectors.
#' @param type `"cooccurrence"` (default) counts transactions containing
#'   all the items in any order; `"sequential"` requires them in the given
#'   order.
#' @return A tidy `data.frame`: `pattern`, `size`, `support`, `count`.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
#' support_of(tr, list(c("a", "b"), c("b", "c"), "a"))
#' @seealso [itemsets()], [transactions()]
#' @export
support_of <- function(x, itemsets,
                       type = c("cooccurrence", "sequential")) {
  x <- .dr_as_transactions(x)
  type <- match.arg(type)
  if (is.character(itemsets)) itemsets <- list(itemsets)
  stopifnot(is.list(itemsets),
            all(vapply(itemsets, is.character, logical(1))))
  if (type == "sequential" && is.null(x$sequences)) {
    stop("Sequential support needs ordered sequences; this transaction ",
         "set was built from a binary matrix (set form only).",
         call. = FALSE)
  }
  n <- x$n_transactions
  w <- .dr_weights(x)

  counts <- vapply(itemsets, function(its) {
    unknown <- setdiff(its, x$items)
    if (length(unknown) > 0L) return(0)
    hit <- if (type == "sequential") {
      vapply(x$sequences, .dr_contains, logical(1), p = its)
    } else {
      rowSums(x$matrix[, its, drop = FALSE]) == length(its)
    }
    sum(w[hit])
  }, numeric(1))

  sep <- if (type == "sequential") " -> " else ", "
  data.frame(
    pattern = vapply(itemsets, paste, character(1), collapse = sep),
    size = lengths(itemsets),
    support = counts / sum(w),
    count = counts,
    stringsAsFactors = FALSE, row.names = NULL
  )
}


#' Sample Transactions
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param size Number of transactions to draw. Defaults to all of them.
#' @param replace Sample with replacement? Default `FALSE`.
#' @param prob Optional sampling probabilities, one per transaction.
#' @return A `dyna_transactions` object holding the sampled transactions.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a", "c"), c("a", "b", "c")))
#' sample_transactions(tr, size = 2)
#' @seealso [transactions()], [bootstrap_rules()]
#' @export
sample_transactions <- function(x, size = NULL, replace = FALSE,
                                prob = NULL) {
  x <- .dr_as_transactions(x)
  n <- x$n_transactions
  if (is.null(size)) size <- n
  stopifnot(is.numeric(size), length(size) == 1L, size >= 1)
  if (!replace && size > n) {
    stop("`size` exceeds the number of transactions; use replace = TRUE.",
         call. = FALSE)
  }
  idx <- sample.int(n, as.integer(size), replace = replace, prob = prob)
  .dr_subset_transactions(x, idx)
}


#' Generate Random Transactions
#'
#' Synthetic transaction data for testing and for calibrating thresholds
#' against what mining finds in noise.
#'
#' @param n_transactions Number of transactions.
#' @param n_items Number of distinct items.
#' @param density Probability that any given item appears in any given
#'   transaction. Default `0.2`.
#' @param item_prefix Prefix for generated item labels. Default `"item"`.
#' @param prob Optional per-item probability vector overriding `density`.
#' @return A `dyna_transactions` object.
#' @examples
#' set.seed(1)
#' random_transactions(20, 5, density = 0.4)
#' @seealso [transactions()]
#' @export
random_transactions <- function(n_transactions, n_items, density = 0.2,
                                item_prefix = "item", prob = NULL) {
  stopifnot(is.numeric(n_transactions), n_transactions >= 1,
            is.numeric(n_items), n_items >= 1,
            is.numeric(density), density > 0, density <= 1)
  n_transactions <- as.integer(n_transactions)
  n_items <- as.integer(n_items)
  items <- paste0(item_prefix, seq_len(n_items))
  p <- if (is.null(prob)) rep(density, n_items) else {
    stopifnot(length(prob) == n_items, all(prob >= 0), all(prob <= 1))
    prob
  }
  mat <- matrix(stats::runif(n_transactions * n_items) <
                  rep(p, each = n_transactions),
                nrow = n_transactions, dimnames = list(NULL, items))
  transactions(mat)
}


#' Add Complement Items
#'
#' Adds a negated item for each named item, so rules can be mined about
#' the *absence* of a behaviour as well as its presence.
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param items Character vector of items to complement. Defaults to all
#'   items.
#' @param prefix Prefix for the complement labels. Default `"!"`.
#' @return A `dyna_transactions` object with the complement items added.
#'   Sequences are dropped, because the absence of an item has no position
#'   in a sequence.
#' @examples
#' tr <- transactions(list(c("a", "b"), c("a"), c("b")))
#' add_complement(tr, items = "a")
#' @seealso [transactions()]
#' @export
add_complement <- function(x, items = NULL, prefix = "!") {
  x <- .dr_as_transactions(x)
  if (is.null(items)) items <- x$items
  stopifnot(is.character(items), is.character(prefix), length(prefix) == 1L)
  unknown <- setdiff(items, x$items)
  if (length(unknown) > 0L) {
    stop("Unknown item(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  comp <- !x$matrix[, items, drop = FALSE]
  colnames(comp) <- paste0(prefix, items)
  mat <- cbind(x$matrix, comp)
  ord <- order(colnames(mat))
  x$matrix <- mat[, ord, drop = FALSE]
  x$items <- colnames(mat)[ord]
  x$sequences <- NULL
  x$source <- paste0(x$source, "+complement")
  x
}


#' Roll Items Up a Hierarchy
#'
#' Replaces items by the group they belong to, so mining runs at a coarser
#' level of description (individual actions to action categories, say).
#'
#' @param x A `dyna_transactions` object, or anything [transactions()]
#'   accepts.
#' @param hierarchy A named character vector mapping item to group, or a
#'   two-column `data.frame` (`item`, `group`). Items absent from the map
#'   keep their own label.
#' @return A `dyna_transactions` object at the group level. Sequence order
#'   is preserved; runs of the same group collapse to a single event.
#' @examples
#' tr <- transactions(list(c("read", "quiz"), c("video", "quiz")))
#' aggregate_items(tr, c(read = "study", video = "study", quiz = "assess"))
#' @seealso [transactions()]
#' @export
aggregate_items <- function(x, hierarchy) {
  x <- .dr_as_transactions(x)
  if (is.data.frame(hierarchy)) {
    stopifnot(ncol(hierarchy) >= 2L)
    hierarchy <- stats::setNames(as.character(hierarchy[[2L]]),
                                 as.character(hierarchy[[1L]]))
  }
  stopifnot(is.character(hierarchy), !is.null(names(hierarchy)))

  remap <- function(v) {
    hit <- match(v, names(hierarchy))
    ifelse(is.na(hit), v, hierarchy[hit])
  }

  if (!is.null(x$sequences)) {
    seqs <- lapply(x$sequences, function(s) {
      g <- unname(remap(s))
      g[c(TRUE, g[-1L] != g[-length(g)])]   # collapse consecutive repeats
    })
    return(.tr_from_sequences(seqs, ids = x$ids, unit = x$unit,
                              source = paste0(x$source, "+aggregated")))
  }

  groups <- unname(remap(x$items))
  mat <- vapply(sort(unique(groups)), function(g) {
    rowSums(x$matrix[, groups == g, drop = FALSE]) > 0
  }, logical(x$n_transactions))
  if (!is.matrix(mat)) mat <- matrix(mat, nrow = x$n_transactions,
                                     dimnames = list(NULL, sort(unique(groups))))
  x$matrix <- mat
  x$items <- colnames(mat)
  x$source <- paste0(x$source, "+aggregated")
  x
}


#' Read Transactions From a File
#'
#' @param file Path to a text file.
#' @param format `"basket"` (default): one transaction per line, items
#'   separated by `sep`. `"single"`: one item per line, with columns
#'   identifying the transaction and the item.
#' @param sep Field separator. Default `","`.
#' @param header Does the file have a header line? Default `FALSE`.
#' @param cols For `format = "single"`, the transaction-id and item column
#'   positions or names. Default `c(1, 2)`.
#' @return A `dyna_transactions` object.
#' @examples
#' f <- tempfile()
#' writeLines(c("a,b,c", "a,b", "b,c"), f)
#' read_transactions(f)
#' unlink(f)
#' @seealso [transactions()]
#' @export
read_transactions <- function(file, format = c("basket", "single"),
                              sep = ",", header = FALSE, cols = c(1, 2)) {
  format <- match.arg(format)
  if (format == "basket") {
    lines <- readLines(file, warn = FALSE)
    if (header) lines <- lines[-1L]
    seqs <- lapply(strsplit(lines, sep, fixed = TRUE), function(v) {
      v <- trimws(v)
      v[nzchar(v)]
    })
    seqs <- seqs[lengths(seqs) > 0L]
    return(.tr_from_sequences(seqs, ids = NULL, unit = "row",
                              source = "file:basket"))
  }
  df <- utils::read.table(file, sep = sep, header = header,
                          stringsAsFactors = FALSE)
  stopifnot(length(cols) == 2L)
  id <- as.character(df[[cols[[1L]]]])
  item <- as.character(df[[cols[[2L]]]])
  seqs <- unname(split(item, factor(id, levels = unique(id))))
  .tr_from_sequences(seqs, ids = NULL, unit = "row", source = "file:single")
}


# ---- shared internals -------------------------------------------------

#' @noRd
.dr_as_transactions <- function(x) {
  if (inherits(x, "dyna_transactions")) x else transactions(x)
}

#' @noRd
.dr_weights <- function(x) {
  if (is.null(x$weights)) rep(1, x$n_transactions) else x$weights
}

#' @noRd
.dr_subset_transactions <- function(x, idx) {
  x$matrix <- x$matrix[idx, , drop = FALSE]
  if (!is.null(x$sequences)) x$sequences <- x$sequences[idx]
  if (!is.null(x$ids)) x$ids <- x$ids[idx, , drop = FALSE]
  if (!is.null(x$weights)) x$weights <- x$weights[idx]
  x$n_transactions <- length(idx)
  x
}
