# ============================================================
# volatilidade_module.R — Volatilidade histórica rolante
# ============================================================

volatilidadeUI <- function(id) {
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
        sliderInput(ns("janela"), "Janela rolante (dias):",
          min = 5, max = 60, value = 21, step = 1
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
    plotlyOutput(ns("grafico"), height = "480px"),
    div(class = "info-box",
      p("Volatilidade anualizada calculada como desvio padrão dos retornos logarítmicos ",
        "na janela selecionada, multiplicado por √252.")
    )
  )
}

volatilidadeServer <- function(id, dados) {
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

    # Recalcular volatilidade com janela dinâmica
    dados_vol <- reactive({
      req(input$periodo, input$acoes_sel, input$janela)
      janela  <- input$janela
      precos  <- dados$precos

      df_vol <- data.frame(Data = precos$Data)
      for (acao in input$acoes_sel) {
        ret <- c(NA, diff(log(precos[[acao]])))
        vol <- sapply(seq_along(ret), function(i) {
          if (i < janela) return(NA)
          sd(ret[(i - janela + 1):i], na.rm = TRUE) * sqrt(252) * 100
        })
        df_vol[[acao]] <- vol
      }

      df_filtrado <- df_vol[
        df_vol$Data >= input$periodo[1] &
          df_vol$Data <= input$periodo[2], ,
        drop = FALSE
      ]
      tidyr::pivot_longer(df_filtrado, cols = -Data, names_to = "Acao", values_to = "Volatilidade")
    })

    output$grafico <- renderPlotly({
      df <- dados_vol()
      validate(need(nrow(df) > 0, "Nenhum dado para o período selecionado."))

      plot_ly(df, x = ~Data, y = ~Volatilidade, color = ~Acao,
              type = "scatter", mode = "lines",
              line = list(width = 2)) %>%
        layout(
          title  = list(
            text = paste0("Volatilidade Histórica Rolante (", input$janela, " dias)"),
            font = list(size = 16)
          ),
          xaxis  = list(title = "Data", gridcolor = "#2a2a2a"),
          yaxis  = list(title = "Volatilidade Anualizada (%)", ticksuffix = "%", gridcolor = "#2a2a2a"),
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
