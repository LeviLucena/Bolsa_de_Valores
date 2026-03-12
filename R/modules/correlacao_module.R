# ============================================================
# correlacao_module.R — Mapa de calor de correlação
# ============================================================

correlacaoUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "filtros-container",
      div(class = "filtro-item",
        dateRangeInput(ns("periodo"), "Período:",
          start = NULL, end = NULL,
          min = NULL,   max = NULL,
          language = "pt-BR", separator = " até "
        )
      )
    ),
    plotlyOutput(ns("grafico"), height = "500px"),
    div(class = "info-box",
      p("A correlação varia de -1 (correlação negativa perfeita) a +1 (correlação positiva perfeita). ",
        "Valores próximos a 0 indicam ausência de correlação linear.")
    )
  )
}

correlacaoServer <- function(id, dados) {
  moduleServer(id, function(input, output, session) {

    observe({
      updateDateRangeInput(session, "periodo",
        start = dados$data_inicio, end = dados$data_fim,
        min   = dados$data_inicio, max = dados$data_fim
      )
    })

    matriz_corr <- reactive({
      req(input$periodo)
      ret <- dados$retornos[
        dados$retornos$Data >= input$periodo[1] &
          dados$retornos$Data <= input$periodo[2],
        dados$acoes,
        drop = FALSE
      ]
      validate(need(nrow(ret) >= 5, "Selecione ao menos 5 dias para calcular correlação."))
      cor(ret, use = "complete.obs")
    })

    output$grafico <- renderPlotly({
      mc     <- matriz_corr()
      acoes  <- rownames(mc)
      z_text <- matrix(sprintf("%.3f", mc), nrow = nrow(mc))

      plot_ly(
        z          = mc,
        x          = acoes,
        y          = acoes,
        type       = "heatmap",
        colorscale = list(
          list(0, "#d73027"),
          list(0.5, "#1a1a2e"),
          list(1, "#00d084")
        ),
        zmin = -1, zmax = 1,
        text = z_text,
        hovertemplate = "%{y} × %{x}: %{text}<extra></extra>"
      ) %>%
        layout(
          title  = list(text = "Matriz de Correlação entre Retornos", font = list(size = 16)),
          xaxis  = list(title = ""),
          yaxis  = list(title = ""),
          plot_bgcolor  = "#1a1a2e",
          paper_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0")
        ) %>%
        config(displayModeBar = TRUE, locale = "pt-BR")
    })
  })
}
