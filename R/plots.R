# Rule visualisations. Six standard views of a mined rule set, all built
# on ggplot2 (already a dependency) with no layout or graph packages
# added -- the graph view lays items out on a circle analytically.

# Rules plus whatever extra measure the plot is coloured by, in one tidy
# frame. rules() already carries support/confidence/lift, so only genuinely
# new measures are joined on.
#' @noRd
.dr_plot_data <- function(x, measure, top) {
  r <- rules(x, top = top)
  if (nrow(r) == 0L) return(r)
  r$w <- if (measure %in% names(r)) r[[measure]] else {
    m <- measures(x, measure = measure)
    m[[measure]][match(paste(r$antecedent, r$consequent, sep = "\r"),
                       paste(m$antecedent, m$consequent, sep = "\r"))]
  }
  r
}

#' @noRd
.dr_sep <- function(x) if (x$type == "sequential") " -> " else ", "

# Items on each side, and the rule's order (total number of items).
#' @noRd
.dr_sides <- function(r, sep) {
  list(
    ante = strsplit(r$antecedent, sep, fixed = TRUE),
    cons = strsplit(r$consequent, sep, fixed = TRUE)
  )
}

#' @noRd
.dr_theme <- function() ggplot2::theme_minimal(base_size = 12)

#' @noRd
.dr_fill_lift <- function(what = "colour") {
  f <- if (what == "fill") ggplot2::scale_fill_gradient2 else
    ggplot2::scale_colour_gradient2
  f(low = "#D33F6A", mid = "grey85", high = "#4A6FE3", midpoint = 1)
}

#' @noRd
.dr_plot_scatter <- function(r, measure, title) {
  ggplot2::ggplot(r, ggplot2::aes(x = support, y = confidence, colour = w)) +
    ggplot2::geom_point(size = 3, alpha = 0.8) +
    .dr_fill_lift("colour") +
    ggplot2::labs(x = "Support", y = "Confidence", colour = measure,
                  title = title) +
    .dr_theme()
}

#' @noRd
.dr_plot_twokey <- function(r, sep, title) {
  sides <- .dr_sides(r, sep)
  r$order <- lengths(sides$ante) + lengths(sides$cons)
  ggplot2::ggplot(r, ggplot2::aes(x = support, y = confidence,
                                  colour = factor(order))) +
    ggplot2::geom_point(size = 3, alpha = 0.85) +
    ggplot2::labs(x = "Support", y = "Confidence", colour = "Rule order",
                  title = title,
                  subtitle = "Colour is the number of items in the rule") +
    .dr_theme()
}

#' @noRd
.dr_plot_matrix <- function(r, measure, title) {
  ggplot2::ggplot(r, ggplot2::aes(x = antecedent, y = consequent, fill = w)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
    .dr_fill_lift("fill") +
    ggplot2::labs(x = "Antecedent", y = "Consequent", fill = measure,
                  title = title) +
    .dr_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45,
                                                       hjust = 1))
}

# Grouped matrix. arulesViz clusters antecedents; here they are grouped by
# their lead item, which is deterministic, needs no clustering dependency,
# and is what the antecedent's first item means for sequential rules.
#' @noRd
.dr_plot_grouped <- function(r, sep, measure, title) {
  sides <- .dr_sides(r, sep)
  r$group <- vapply(sides$ante, `[`, character(1), 1L)
  ggplot2::ggplot(r, ggplot2::aes(x = group, y = consequent, size = support,
                                  colour = w)) +
    ggplot2::geom_point(alpha = 0.85) +
    .dr_fill_lift("colour") +
    ggplot2::scale_size_continuous(range = c(2, 9)) +
    ggplot2::labs(x = "Antecedent group (lead item)", y = "Consequent",
                  size = "Support", colour = measure, title = title,
                  subtitle = "Antecedents grouped by their lead item") +
    .dr_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45,
                                                       hjust = 1))
}

# Item-level graph: every antecedent item is linked to every consequent
# item, edge weight aggregated over the rules that produced it. Items sit
# on a circle, so no layout engine is needed.
#' @noRd
.dr_plot_graph <- function(r, sep, measure, title) {
  sides <- .dr_sides(r, sep)
  reps <- lengths(sides$ante) * lengths(sides$cons)
  edges <- data.frame(
    from = unlist(lapply(seq_len(nrow(r)), function(i) {
      rep(sides$ante[[i]], each = length(sides$cons[[i]]))
    })),
    to = unlist(lapply(seq_len(nrow(r)), function(i) {
      rep(sides$cons[[i]], times = length(sides$ante[[i]]))
    })),
    w = rep(r$w, reps),
    stringsAsFactors = FALSE
  )
  edges <- stats::aggregate(w ~ from + to, data = edges, FUN = mean)

  items <- sort(unique(c(edges$from, edges$to)))
  ang <- stats::setNames(
    seq(0, 2 * pi, length.out = length(items) + 1L)[seq_along(items)], items)
  nodes <- data.frame(item = items, x = cos(ang), y = sin(ang),
                      stringsAsFactors = FALSE)
  edges$x <- cos(ang[edges$from]);    edges$y <- sin(ang[edges$from])
  edges$xend <- cos(ang[edges$to]);   edges$yend <- sin(ang[edges$to])

  ggplot2::ggplot() +
    ggplot2::geom_curve(
      data = edges,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend, colour = w),
      curvature = 0.2, alpha = 0.7, linewidth = 0.7,
      arrow = grid::arrow(length = grid::unit(6, "pt"), type = "closed")) +
    .dr_fill_lift("colour") +
    ggplot2::geom_point(data = nodes, ggplot2::aes(x = x, y = y),
                        size = 5, colour = "grey30") +
    ggplot2::geom_text(data = nodes,
                       ggplot2::aes(x = x * 1.15, y = y * 1.15, label = item),
                       size = 4) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::labs(colour = measure, title = title,
                  subtitle = "Items linked antecedent to consequent") +
    ggplot2::theme_void(base_size = 12)
}

# Parallel coordinates: each rule is a path across item positions, ending
# at its consequent.
#' @noRd
.dr_plot_paracoord <- function(r, sep, measure, title) {
  sides <- .dr_sides(r, sep)
  paths <- lapply(seq_len(nrow(r)), function(i) {
    chain <- c(sides$ante[[i]], sides$cons[[i]])
    data.frame(rule = i, position = seq_along(chain), item = chain,
               w = r$w[i], stringsAsFactors = FALSE)
  })
  df <- do.call(rbind, paths)

  ggplot2::ggplot(df, ggplot2::aes(x = position, y = item, group = rule,
                                   colour = w)) +
    ggplot2::geom_line(alpha = 0.6, linewidth = 0.8) +
    ggplot2::geom_point(size = 2, alpha = 0.8) +
    .dr_fill_lift("colour") +
    ggplot2::scale_x_continuous(breaks = seq_len(max(df$position))) +
    ggplot2::labs(x = "Position in rule (last = consequent)", y = "Item",
                  colour = measure, title = title) +
    .dr_theme()
}
