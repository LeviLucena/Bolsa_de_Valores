# ============================================================
# volume_module.R — Gráfico de volume de negociação
# ============================================================

volumeUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "filtros-container",
      div(class = "filtro-item",
        dateRangeInput(ns("periodo"), "Período:",
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
    plotlyOutput(ns("grafico"), height = "480px")
  )
}

volumeServer <- function(id, dados) {
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

    dados_filtrados <- reactive({
      req(input$periodo, input$acoes_sel)
      colunas <- c("Data", input$acoes_sel)
      df <- dados$volumes[
        dados$volumes$Data >= input$periodo[1] &
          dados$volumes$Data <= input$periodo[2],
        colunas,
        drop = FALSE
      ]
      tidyr::pivot_longer(df, cols = -Data, names_to = "Acao", values_to = "Volume")
    })

    output$grafico <- renderPlotly({
      df <- dados_filtrados()
      validate(need(nrow(df) > 0, "Nenhum dado para o período selecionado."))

      plot_ly(df, x = ~Data, y = ~Volume, color = ~Acao,
              type = "bar") %>%
        layout(
          barmode = "group",
          title   = list(text = "Volume de Negociação Diário", font = list(size = 16)),
          xaxis   = list(title = "Data", gridcolor = "#2a2a2a"),
          yaxis   = list(title = "Volume (unidades)", gridcolor = "#2a2a2a"),
          legend  = list(title = list(text = "Ação")),
          hovermode = "x unified",
          plot_bgcolor  = "#1a1a2e",
          paper_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0")
        ) %>%
        config(displayModeBar = TRUE, locale = "pt-BR")
    })
  })
}
