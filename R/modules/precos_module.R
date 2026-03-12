# ============================================================
# precos_module.R — Gráfico de preços das ações
# ============================================================

precosUI <- function(id) {
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

precosServer <- function(id, dados) {
  moduleServer(id, function(input, output, session) {

    # Inicializar filtros com valores dos dados
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
      df <- dados$precos[
        dados$precos$Data >= input$periodo[1] &
          dados$precos$Data <= input$periodo[2],
        colunas,
        drop = FALSE
      ]
      tidyr::pivot_longer(df, cols = -Data, names_to = "Acao", values_to = "Preco")
    })

    output$grafico <- renderPlotly({
      df <- dados_filtrados()
      validate(need(nrow(df) > 0, "Nenhum dado para o período selecionado."))

      plot_ly(df, x = ~Data, y = ~Preco, color = ~Acao,
              type = "scatter", mode = "lines",
              line = list(width = 2)) %>%
        layout(
          title  = list(text = "Preços das Ações ao Longo do Tempo", font = list(size = 16)),
          xaxis  = list(title = "Data", gridcolor = "#2a2a2a"),
          yaxis  = list(title = "Preço (R$)", tickprefix = "R$ ", gridcolor = "#2a2a2a"),
          legend = list(title = list(text = "Ação")),
          hovermode = "x unified",
          plot_bgcolor  = "#1a1a2e",
          paper_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0")
        ) %>%
        config(displayModeBar = TRUE, locale = "pt-BR")
    })
  })
}
