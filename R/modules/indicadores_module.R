# ============================================================
# indicadores_module.R — Cards de KPIs por ação
# ============================================================

indicadoresUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "section-title", h3("Resumo do Mercado")),
    uiOutput(ns("cards_acoes")),
    hr(),
    div(class = "section-title", h3("Tabela de Cotações")),
    div(class = "table-container",
      tableOutput(ns("tabela_resumo"))
    )
  )
}

indicadoresServer <- function(id, dados) {
  moduleServer(id, function(input, output, session) {

    # Calcular métricas de hoje vs ontem
    resumo <- reactive({
      precos <- dados$precos
      n <- nrow(precos)
      sapply(dados$acoes, function(acao) {
        ultimo   <- precos[[acao]][n]
        anterior <- precos[[acao]][n - 1]
        variacao <- (ultimo - anterior) / anterior * 100
        list(
          acao     = acao,
          ultimo   = ultimo,
          variacao = variacao,
          min_ano  = min(precos[[acao]]),
          max_ano  = max(precos[[acao]])
        )
      }, simplify = FALSE)
    })

    output$cards_acoes <- renderUI({
      res <- resumo()
      cards <- lapply(dados$acoes, function(acao) {
        r       <- res[[acao]]
        classe  <- if (r$variacao >= 0) "card-alta" else "card-baixa"
        seta    <- if (r$variacao >= 0) "\u25b2" else "\u25bc"
        cor_var <- if (r$variacao >= 0) "#00d084" else "#ff4b4b"

        div(class = paste("kpi-card", classe),
          div(class = "kpi-ticker", acao),
          div(class = "kpi-preco", sprintf("R$ %.2f", r$ultimo)),
          div(class = "kpi-variacao",
            style = paste0("color:", cor_var),
            sprintf("%s %.2f%%", seta, abs(r$variacao))
          ),
          div(class = "kpi-range",
            sprintf("Min: R$ %.2f | Max: R$ %.2f", r$min_ano, r$max_ano)
          )
        )
      })
      div(class = "cards-container", do.call(tagList, cards))
    })

    output$tabela_resumo <- renderTable({
      res       <- resumo()   # reutiliza o reactive já computado
      setor_map <- setNames(dados$metadados$Setor, dados$metadados$Ticker)
      tabela <- do.call(rbind, lapply(dados$acoes, function(acao) {
        r <- res[[acao]]
        data.frame(
          Ticker          = acao,
          Setor           = setor_map[[acao]],
          `Último (R$)`   = round(r$ultimo,   2),
          `Variação (%)`  = round(r$variacao, 2),
          `Mín. Ano (R$)` = round(r$min_ano,  2),
          `Máx. Ano (R$)` = round(r$max_ano,  2),
          check.names = FALSE
        )
      }))
      tabela
    }, striped = TRUE, hover = TRUE, bordered = TRUE)
  })
}
