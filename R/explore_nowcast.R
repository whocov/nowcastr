#' Explore Nowcast Results with Shiny
#'
#' @param nc_obj A `nowcast_results` S7 object.
#' @export
explore_nowcast <- function(nc_obj) {
  if (!requireNamespace("shiny", quietly = TRUE)) stop("Package 'shiny' required.")
  if (!requireNamespace("DT", quietly = TRUE)) stop("Package 'DT' required.")
  if (!requireNamespace("bslib", quietly = TRUE)) stop("Package 'bslib' required.")

  # 1. Prepare the summary table data
  stats_df <-
    tbl_models_stats(nc_obj) %>%
    select(-c("data", "pred", "fit")) %>%
    select(eval, everything())
  ## we could keep data and pred to make sparklines in the table


  # # Model count summary
  # model_counts <-
  #   stats_df %>%
  #   # count(modelname)
  #   summarise(
  #     .by = modelname,
  #     count = n(),
  #     R2_median = median(R2, na.rm = T),
  #   ) %>%
  #   arrange(desc(count))


  # Define UI
  ui <- bslib::page_fluid(
    theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
    shiny::titlePanel(paste("Nowcast Results")),
    # bslib::layout_column_wrap(
    #   width = 1 / 3, # 3 columns
    #   # height = "500px",
    #   bslib::card(),
    #   bslib::card(
    #     bslib::card_header("Selected Group Spotlight"),
    #     # shiny::uiOutput("selected_stats")
    #   ),
    #   bslib::card(
    #     bslib::card_header("Model Types"),
    #     shiny::tableOutput("model_summary")
    #   )
    # ),
    shiny::div(
      style = "margin-bottom: 20px;",
      bslib::card(
        height = "45vh",
        bslib::card_header("Models (Select a row to update plots)"),
        DT::DTOutput("tbl_summary")
      )
    ),
    bslib::layout_column_wrap(
      width = 1 / 3, # 3 columns
      height = "45vh",
      bslib::card(
        bslib::card_header("Input Data"),
        shiny::plotOutput("plot_data")
      ),
      bslib::card(
        bslib::card_header("Completeness Model (Delays)"),
        shiny::plotOutput("plot_delays")
      ),
      bslib::card(
        bslib::card_header("Final Nowcast"),
        shiny::plotOutput("plot_results")
      )
    )
  )

  # Define Server
  server <- function(input, output, session) {
    # # Model summary output
    # output$model_summary <- renderTable({
    #   model_counts
    # })


    # shiny::Reactive for selected group
    selected_group <- shiny::reactive({
      idx <- input$tbl_summary_rows_selected
      if (is.null(idx)) {
        return(NULL)
      }

      # Extract the group identifiers (country, metric, etc.)
      group_vals <- stats_df[idx, nc_obj@params$group_cols, drop = FALSE]
      return(group_vals)
    })

    output$tbl_summary <- DT::renderDT({
      DT::datatable(
        stats_df,
        selection = list(mode = "single", selected = 1),
        options = list(pageLength = 50, scrollX = TRUE),
        rownames = FALSE
      )
    })

    # Helper function to filter the S7 object for plotting
    filter_nc <- function(nc_ptr, grp) {
      if (is.null(grp)) {
        return(nc_ptr)
      }

      # We create a temporary copy of the S7 object with filtered data
      tmp <- nc_ptr

      # Filter @data, @delays, @results based on group values
      # Using a simple inner_join to keep only relevant rows
      tmp@data <- inner_join(nc_ptr@data, grp, by = names(grp))
      tmp@delays <- inner_join(nc_ptr@delays, grp, by = names(grp))
      tmp@results <- inner_join(nc_ptr@results, grp, by = names(grp))
      tmp@models <- inner_join(nc_ptr@models, grp, by = names(grp))
      tmp@n_groups <- 1

      return(tmp)
    }

    output$plot_data <- shiny::renderPlot({
      shiny::req(selected_group())
      filtered_obj <- filter_nc(nc_obj, selected_group())
      plot(filtered_obj, which = "data", option = "millipede") +
        theme(legend.position = "none")
    })

    output$plot_delays <- shiny::renderPlot({
      shiny::req(selected_group())
      filtered_obj <- filter_nc(nc_obj, selected_group())
      plot(filtered_obj, which = "delays")
    })

    output$plot_results <- shiny::renderPlot({
      shiny::req(selected_group())
      filtered_obj <- filter_nc(nc_obj, selected_group())
      plot(filtered_obj, which = "results")
    })
  }

  shiny::shinyApp(ui, server)
}
