#' Nowcastr ggplot2 Theme
#'
#' A clean, ggplot2 theme. Derived from ggplot2::theme_minimal(),
#' with a few bold elements and softer colors, and bigger texts by default.
#'
#'
#' @param base_size Base font size, in pts.
#' @param base_family Base font family.
#' @param color_bg Colour for plot.background.
#' @param color_grid Colour for major grid lines.
#' @param color_title1 Darkest text colour (titles, axis texts).
#' @param color_title2 Secondary text colour (legend text, strips, axis titles).
#' @param color_title3 Tertiary text colour (legend titles).
#' @param color_title4 Lightest text colour (subtitles).
#'
#' @return A \code{theme} object applied to the current ggplot.
#' @export
#' @family theme nowcastr
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(mpg, wt)) +
#'   geom_point() +
#'   theme_nowcastr() +
#'   labs(
#'     title = "Fuel efficiency vs. weight",
#'     subtitle = "Source: Motor Trend US magazine",
#'     caption = "Data: mtcars"
#'   )
theme_nowcastr <- function(base_size = 12,
                           base_family = "sans",
                           color_bg = "#fbfbfb",
                           color_grid = "#EEEEEE",
                           color_title1 = "#444444",
                           color_title2 = "#555555",
                           color_title3 = "#666666",
                           color_title4 = "#777777") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      ## LEGEND
      # legend.position = "top",
      # legend.direction = "horizontal",
      # legend.justification = "left",
      # legend.key.width = unit(1.5, "cm"),
      # legend.spacing.x = unit(0.3, "cm"),

      ## SPACING
      plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"),

      ## COLORS & TEXT
      plot.title = element_text(color = color_title1, face = "bold", size = base_size * 1.2),
      plot.subtitle = element_text(color = color_title4),
      plot.caption = element_text(size = base_size / 2 + 3, color = "grey"),
      legend.title = element_text(
        colour = color_title3, face = "bold",
        size = round(base_size / 1.2)
      ),
      legend.text = element_text(colour = color_title2),
      strip.text = element_text(color = color_title2, face = "bold"),
      axis.title = element_text(colour = color_title2, face = "bold"),
      axis.text = element_text(colour = color_title1),
      # axis.text.x = element_text(size = round(base_size / 1.4), lineheight = 0.85),

      ## BACKGROUND & GRID
      plot.background = element_rect(fill = color_bg, color = NA),
      panel.grid.major = element_line(color = color_grid),
      panel.grid.minor = element_blank(),
    )
}
