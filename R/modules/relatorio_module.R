# ============================================================
# relatorio_module.R — Visão consolidada + download
# ============================================================

relatorioUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "filtros-container",
      div(class = "filtro-item",
        dateRangeInput(ns("periodo"), "Período do relatório:",
          start = NULL, end = NULL,
          min = NULL,   max = NULL,
          language = "pt-BR", separator = " até "
        )
      ),
      div(class = "filtro-item",
        checkboxGroupInput(ns("acoes_sel"), "Ações:",
          choices  = NULL,
          selected = NULL,
          inline   = TRUE
        )
      )
    ),
    div(class = "botoes-relatorio",
      downloadButton(ns("download_csv"), "Exportar CSV", class = "btn-download"),
      downloadButton(ns("download_html"), "Exportar HTML", class = "btn-download")
    ),
    hr(),
    fluidRow(
      column(6, plotlyOutput(ns("g_precos"),      height = "350px")),
      column(6, plotlyOutput(ns("g_volume"),      height = "350px"))
    ),
    fluidRow(
      column(6, plotlyOutput(ns("g_correlacao"),  height = "350px")),
      column(6, plotlyOutput(ns("g_volatilidade"), height = "350px"))
    )
  )
}

relatorioServer <- function(id, dados) {
  moduleServer(id, function(input, output, session) {

    observe({
      updateDateRangeInput(session, "periodo",
        start = dados$data_inicio, end = dados$data_fim,
        min   = dados$data_inicio, max = dados$data_fim
      )
      updateCheckboxGroupInput(session, "acoes_sel",
        choices  = dados$acoes,
        selected = dados$acoes
      )
    })

    # Dados filtrados reativos
    precos_long <- reactive({
      req(input$periodo, input$acoes_sel)
      df <- dados$precos[
        dados$precos$Data >= input$periodo[1] &
          dados$precos$Data <= input$periodo[2],
        c("Data", input$acoes_sel), drop = FALSE
      ]
      tidyr::pivot_longer(df, cols = -Data, names_to = "Acao", values_to = "Preco")
    })

    volumes_long <- reactive({
      req(input$periodo, input$acoes_sel)
      df <- dados$volumes[
        dados$volumes$Data >= input$periodo[1] &
          dados$volumes$Data <= input$periodo[2],
        c("Data", input$acoes_sel), drop = FALSE
      ]
      tidyr::pivot_longer(df, cols = -Data, names_to = "Acao", values_to = "Volume")
    })

    matriz_corr <- reactive({
      req(input$periodo)
      ret <- dados$retornos[
        dados$retornos$Data >= input$periodo[1] &
          dados$retornos$Data <= input$periodo[2],
        input$acoes_sel, drop = FALSE
      ]
      cor(ret, use = "complete.obs")
    })

    vol_long <- reactive({
      req(input$periodo, input$acoes_sel)
      df <- dados$volatilidade[
        dados$volatilidade$Data >= input$periodo[1] &
          dados$volatilidade$Data <= input$periodo[2],
        c("Data", input$acoes_sel), drop = FALSE
      ]
      tidyr::pivot_longer(df, cols = -Data, names_to = "Acao", values_to = "Volatilidade")
    })

    # Tema comum — aplicado via do.call para compatibilidade com layout()
    tema_dark <- list(
      plot_bgcolor  = "#1a1a2e",
      paper_bgcolor = "#1a1a2e",
      font   = list(color = "#e0e0e0", size = 11),
      margin = list(t = 40)
    )

    layout_dark <- function(p, ...) {
      do.call(layout, c(list(p), list(...), tema_dark))
    }

    output$g_precos <- renderPlotly({
      plot_ly(precos_long(), x = ~Data, y = ~Preco, color = ~Acao,
              type = "scatter", mode = "lines", line = list(width = 1.5)) %>%
        layout_dark(title = "Preços", xaxis = list(title = ""), yaxis = list(title = "R$")) %>%
        config(displayModeBar = FALSE)
    })

    output$g_volume <- renderPlotly({
      plot_ly(volumes_long(), x = ~Data, y = ~Volume, color = ~Acao, type = "bar") %>%
        layout_dark(barmode = "group", title = "Volume",
                    xaxis = list(title = ""), yaxis = list(title = "Unid.")) %>%
        config(displayModeBar = FALSE)
    })

    output$g_correlacao <- renderPlotly({
      mc    <- matriz_corr()
      acoes <- rownames(mc)
      plot_ly(z = mc, x = acoes, y = acoes, type = "heatmap",
              colorscale = list(list(0, "#d73027"), list(0.5, "#1a1a2e"), list(1, "#00d084")),
              zmin = -1, zmax = 1) %>%
        layout_dark(title = "Correlação", xaxis = list(title = ""), yaxis = list(title = "")) %>%
        config(displayModeBar = FALSE)
    })

    output$g_volatilidade <- renderPlotly({
      df <- vol_long()
      df <- df[!is.na(df$Volatilidade), ]
      plot_ly(df, x = ~Data, y = ~Volatilidade, color = ~Acao,
              type = "scatter", mode = "lines", line = list(width = 1.5)) %>%
        layout_dark(title = "Volatilidade (%)", xaxis = list(title = ""),
                    yaxis = list(title = "%", ticksuffix = "%")) %>%
        config(displayModeBar = FALSE)
    })

    # Download CSV — preços no período
    output$download_csv <- downloadHandler(
      filename = function() {
        paste0("b3_relatorio_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(input$periodo, input$acoes_sel)
        df_export <- dados$precos[
          dados$precos$Data >= input$periodo[1] &
            dados$precos$Data <= input$periodo[2],
          c("Data", input$acoes_sel), drop = FALSE
        ]
        write.csv(df_export, file, row.names = FALSE)
      }
    )

    # Download HTML — relatório completo
    output$download_html <- downloadHandler(
      filename = function() {
        paste0("b3_relatorio_", format(Sys.Date(), "%Y%m%d"), ".html")
      },
      content = function(file) {
        p1 <- plot_ly(precos_long(), x = ~Data, y = ~Preco, color = ~Acao,
                      type = "scatter", mode = "lines") %>%
          layout(title = "Preços das Ações", xaxis = list(title = "Data"),
                 yaxis = list(title = "R$"))
        htmlwidgets::saveWidget(p1, file, selfcontained = TRUE)
      }
    )
  })
}
