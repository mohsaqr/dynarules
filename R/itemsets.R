# Frequent-itemset targets: the closed / maximal / generator restrictions
# of the mined frequent sets.

# Pairwise containment over the mined patterns. For co-occurrence a
# pattern is a set, so containment is subset; for sequential it is an
# ordered subsequence.
#' @noRd
.dr_pattern_items <- function(x) {
  sep_out <- if (x$type == "sequential") " -> " else ", "
  strsplit(x$frequent$pattern, sep_out, fixed = TRUE)
}

#' @noRd
.dr_contained_in <- function(type) {
  if (type == "sequential") {
    function(inner, outer) .dr_contains(outer, inner)
  } else {
    function(inner, outer) all(inner %in% outer)
  }
}

#' Frequent Itemsets and Their Closed, Maximal and Generator Subsets
#'
#' Returns the frequent itemsets (co-occurrence) or frequent sequential
#' patterns behind a mined rule set, optionally restricted to one of the
#' standard condensed representations.
#'
#' * `"frequent"` — every pattern meeting `min_support`.
#' * `"closed"` — no proper superpattern has the same support. The
#'   loss-less summary: supports of all frequent patterns are recoverable.
#' * `"maximal"` — no proper superpattern is frequent at all. The
#'   smallest summary, but supports of sub-patterns are lost.
#' * `"generator"` — no proper subpattern has the same support; the
#'   minimal patterns of each equivalence class.
#'
#' @param x A `dynarules` object.
#' @param target One of `"frequent"`, `"closed"`, `"maximal"`,
#'   `"generator"`.
#' @param min_size,max_size Optional integer bounds on the number of items
#'   in a pattern.
#' @param top Optional integer; keep only the `top` patterns by support.
#' @return A tidy `data.frame` with one row per pattern: `pattern`,
#'   `size`, `support`, `count`.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' itemsets(fit)
#' itemsets(fit, target = "closed")
#' itemsets(fit, target = "maximal")
#' @seealso [rules()], [measures()]
#' @export
itemsets <- function(x, target = c("frequent", "closed", "maximal",
                                   "generator"),
                     min_size = NULL, max_size = NULL, top = NULL) {
  stopifnot(inherits(x, "dynarules"))
  target <- match.arg(target)
  fr <- x$frequent
  if (nrow(fr) == 0L) return(fr)

  if (target != "frequent") {
    items <- .dr_pattern_items(x)
    inside <- .dr_contained_in(x$type)
    n <- nrow(fr)
    keep <- vapply(seq_len(n), function(i) {
      others <- setdiff(seq_len(n), i)
      supersets <- Filter(function(j) {
        fr$size[j] > fr$size[i] && inside(items[[i]], items[[j]])
      }, others)
      switch(target,
        maximal = length(supersets) == 0L,
        closed = !any(vapply(supersets, function(j) {
          isTRUE(all.equal(fr$support[j], fr$support[i]))
        }, logical(1))),
        generator = {
          subsets <- Filter(function(j) {
            fr$size[j] < fr$size[i] && inside(items[[j]], items[[i]])
          }, others)
          !any(vapply(subsets, function(j) {
            isTRUE(all.equal(fr$support[j], fr$support[i]))
          }, logical(1)))
        }
      )
    }, logical(1))
    fr <- fr[keep, , drop = FALSE]
  }

  if (!is.null(min_size)) fr <- fr[fr$size >= min_size, , drop = FALSE]
  if (!is.null(max_size)) fr <- fr[fr$size <= max_size, , drop = FALSE]
  fr <- fr[order(-fr$support, fr$size), , drop = FALSE]
  if (!is.null(top) && nrow(fr) > top) fr <- fr[seq_len(top), , drop = FALSE]
  row.names(fr) <- NULL
  fr
}
