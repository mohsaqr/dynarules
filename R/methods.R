# ---- S3 methods: print / summary / plot ----

.okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                "#0072B2", "#D55E00", "#CC79A7", "#999999")

#' Print Method for dynarules
#'
#' @param x A `dynarules` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules <- function(x, ...) {
  arrow <- "=>"
  cat(sprintf("<dynarules> %s rules  [%d rules | %d items | %d transactions]\n",
              x$type, nrow(x$rules), length(x$items), x$n_transactions))
  cat(sprintf("  support >= %.2f | confidence >= %.2f | lift >= %.2f | max length %d\n",
              x$params$min_support, x$params$min_confidence,
              x$params$min_lift, x$params$max_length))
  if (nrow(x$rules) > 0L) {
    top <- utils::head(x$rules, 10L)
    cat("\n  Top rules (by lift):\n")
    invisible(lapply(seq_len(nrow(top)), function(i) {
      cat(sprintf("    %2d. {%s} %s {%s}  (sup=%.3f conf=%.3f lift=%.2f)\n",
                  i, top$antecedent[i], arrow, top$consequent[i],
                  top$support[i], top$confidence[i], top$lift[i]))
    }))
    if (nrow(x$rules) > 10L) {
      cat(sprintf("    ... and %d more rules (see rules(x))\n",
                  nrow(x$rules) - 10L))
    }
  }
  invisible(x)
}


#' Summary Method for dynarules
#'
#' @param object A `dynarules` object.
#' @param ... Ignored.
#' @return The tidy rules data.frame.
#' @export
summary.dynarules <- function(object, ...) {
  as.data.frame(object)
}


#' Plot Mined Rules
#'
#' Six standard views of a rule set. `"scatter"` and `"two-key"` show the
#' whole set at a glance; `"matrix"` and `"grouped"` show which items pair
#' with which; `"graph"` and `"paracoord"` show the item-level structure.
#'
#' @param x A `dynarules` object.
#' @param type The view to draw: `"scatter"` (default) plots support
#'   against confidence coloured by `measure`; `"two-key"` colours the
#'   same scatter by rule order instead; `"matrix"` tiles antecedent
#'   against consequent; `"grouped"` collapses antecedents to their lead
#'   item; `"graph"` hands the rule network to [cograph::splot()];
#'   `"paracoord"` draws each rule as a path across item positions.
#' @param measure Measure to colour by; any name from [list_measures()].
#'   Default `"lift"`. Ignored by `"two-key"`.
#' @param top Integer or NULL. Plot only the top N rules by lift.
#' @param level For `type = "graph"`: `"item"` (default) draws the
#'   item-to-item network, `"rule"` draws one node per rule between the
#'   items it links -- the standard association-rule graph.
#' @param key For `type = "graph", level = "rule"`: draw the size and
#'   colour key. Default `TRUE`.
#' @param ... For `type = "graph"`, passed on to [cograph::splot()] (layout,
#'   node and edge styling); ignored otherwise.
#' @return For `type = "graph"`, the plotted network object, invisibly --
#'   cograph draws with base graphics. For every other type, the `ggplot`
#'   object, invisibly.
#' @examples
#' fit <- dynarules(list(c("a", "b", "c"), c("a", "b"), c("a", "c")),
#'                  min_support = 0.3, min_confidence = 0.3)
#' plot(fit)
#' plot(fit, type = "matrix", measure = "confidence")
#' if (requireNamespace("cograph", quietly = TRUE)) {
#'   plot(fit, type = "graph")
#' }
#' @seealso [measures()], [rules()], [as_network()]
#' @export
plot.dynarules <- function(x, type = c("scatter", "two-key", "matrix",
                                       "grouped", "graph", "paracoord"),
                           measure = "lift", top = NULL,
                           level = c("item", "rule"), key = TRUE, ...) {
  stopifnot(inherits(x, "dynarules"))
  type <- match.arg(type)
  level <- match.arg(level)
  if (!measure %in% names(.DR_MEASURES)) {
    stop("Unknown measure: ", measure, ". See list_measures().",
         call. = FALSE)
  }
  if (nrow(x$rules) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  if (type == "graph") {
    return(invisible(.dr_plot_graph(x, measure, top, level = level,
                                    key = key, ...)))
  }

  r <- .dr_plot_data(x, measure, top)
  sep <- .dr_sep(x)
  title <- sprintf("%s rules (%d)",
                   if (x$type == "sequential") "Sequential" else
                     "Co-occurrence", nrow(r))
  p <- switch(type,
    scatter   = .dr_plot_scatter(r, measure, title),
    "two-key" = .dr_plot_twokey(r, sep, title),
    matrix    = .dr_plot_matrix(r, measure, title),
    grouped   = .dr_plot_grouped(r, sep, measure, title),
    paracoord = .dr_plot_paracoord(r, sep, measure, title)
  )
  print(p)
  invisible(p)
}


#' Print Method for Bootstrapped Rules
#'
#' @param x A `dynarules_boot` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_boot <- function(x, ...) {
  cat(sprintf("<dynarules_boot> %d resamples | %d rules | %.0f%% CIs\n",
              x$iter, nrow(x$stability), 100 * x$conf))
  st <- utils::head(x$stability, 10L)
  cat("\n  Rule stability (by recovery):\n")
  invisible(lapply(seq_len(nrow(st)), function(i) {
    cat(sprintf("    %2d. {%s} => {%s}  recovery=%.2f  lift=%.2f [%.2f, %.2f]\n",
                i, st$antecedent[i], st$consequent[i], st$recovery[i],
                st$lift_mean[i], st$lift_lower[i], st$lift_upper[i]))
  }))
  if (nrow(x$stability) > 10L) {
    cat(sprintf("    ... and %d more rules\n", nrow(x$stability) - 10L))
  }
  invisible(x)
}


#' Summary Method for dynarules_boot
#'
#' @param object A `dynarules_boot` object.
#' @param ... Ignored.
#' @return The tidy stability data.frame.
#' @export
summary.dynarules_boot <- function(object, ...) {
  st <- .subset2(object, "stability")
  row.names(st) <- NULL
  st
}


#' Plot Method for dynarules_boot
#'
#' @description
#' Rules ordered by recovery, showing the bootstrap lift interval per rule
#' and each rule's recovery proportion.
#'
#' @param x A `dynarules_boot` object.
#' @param top Integer. Plot the top N rules by recovery. Default 20.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.dynarules_boot <- function(x, top = 20L, ...) {
  st <- utils::head(x$stability, top)
  if (nrow(st) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  st$rule <- factor(paste0("{", st$antecedent, "} => {", st$consequent, "}"),
                    levels = rev(paste0("{", st$antecedent, "} => {",
                                        st$consequent, "}")))
  p <- ggplot2::ggplot(st, ggplot2::aes(x = lift_mean, y = rule)) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed",
                        color = "grey60", linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = lift_lower,
                                         xmax = lift_upper),
                            height = 0.25, color = "#0072B2") +
    ggplot2::geom_point(ggplot2::aes(size = recovery), color = "#0072B2") +
    ggplot2::scale_size_continuous(range = c(1.5, 4), limits = c(0, 1)) +
    ggplot2::labs(x = "Lift (bootstrap mean and CI)", y = NULL,
                  size = "Recovery",
                  title = sprintf("Rule stability (%d resamples)", x$iter)) +
    ggplot2::theme_minimal(base_size = 12)
  print(p)
  invisible(p)
}


#' Print Method for dynarules_perm
#'
#' @param x A `dynarules_perm` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.dynarules_perm <- function(x, ...) {
  cat(sprintf("<dynarules_perm> %d permutations | null: %s | %s correction\n",
              x$iter, x$null, x$correction))
  cat(sprintf("  %d of %d rules significant at adjusted p < .05\n",
              sum(x$tests$significant), nrow(x$tests)))
  tst <- utils::head(x$tests, 10L)
  cat("\n  Rules (by adjusted p):\n")
  invisible(lapply(seq_len(nrow(tst)), function(i) {
    cat(sprintf("    %2d. {%s} => {%s}  lift=%.2f (null %.2f)  p_adj=%.4f%s\n",
                i, tst$antecedent[i], tst$consequent[i], tst$lift[i],
                tst$lift_null[i], tst$p_adj[i],
                if (tst$significant[i]) " *" else ""))
  }))
  if (nrow(x$tests) > 10L) {
    cat(sprintf("    ... and %d more rules\n", nrow(x$tests) - 10L))
  }
  invisible(x)
}


#' Summary Method for dynarules_perm
#'
#' @param object A `dynarules_perm` object.
#' @param ... Ignored.
#' @return The tidy tests data.frame.
#' @export
summary.dynarules_perm <- function(object, ...) {
  tst <- .subset2(object, "tests")
  row.names(tst) <- NULL
  tst
}


#' Plot Method for dynarules_perm
#'
#' @description
#' Observed lift against the permutation-null mean per rule; significant
#' rules (adjusted p < .05) are highlighted.
#'
#' @param x A `dynarules_perm` object.
#' @param top Integer. Plot the top N rules by adjusted p. Default 20.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.dynarules_perm <- function(x, top = 20L, ...) {
  tst <- utils::head(x$tests, top)
  if (nrow(tst) == 0L) {
    message("No rules to plot.")
    return(invisible(NULL))
  }
  tst$rule <- factor(paste0("{", tst$antecedent, "} => {",
                            tst$consequent, "}"),
                     levels = rev(paste0("{", tst$antecedent, "} => {",
                                         tst$consequent, "}")))
  p <- ggplot2::ggplot(tst, ggplot2::aes(y = rule)) +
    ggplot2::geom_segment(ggplot2::aes(x = lift_null, xend = lift,
                                       yend = rule),
                          color = "grey70", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(x = lift_null), color = "grey60",
                        size = 2) +
    ggplot2::geom_point(ggplot2::aes(x = lift, color = significant),
                        size = 3) +
    ggplot2::scale_color_manual(values = c(`TRUE` = "#009E73",
                                           `FALSE` = "#D55E00"),
                                labels = c(`TRUE` = "significant",
                                           `FALSE` = "not significant")) +
    ggplot2::labs(x = "Lift (grey = permutation-null mean)", y = NULL,
                  color = NULL,
                  title = sprintf("Permutation test (%d permutations, %s)",
                                  x$iter, x$correction)) +
    ggplot2::theme_minimal(base_size = 12)
  print(p)
  invisible(p)
}
