# ============================================================
# indicadores_module.R — Dashboard melhorado com KPIs avançados
# ============================================================

indicadoresUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "section-title", h3("Resumo do Mercado")),
    
    # Linha 1: KPIs principais
    uiOutput(ns("kpis_resumo")),
    
    # Linha 2: Cards por ação com sparkline
    uiOutput(ns("cards_acoes")),
    
    div(class = "row charts-row",
      div(class = "col-md-6",
        div(class = "chart-card",
          h4("Participação por Setor", class = "chart-title"),
          plotlyOutput(ns("grafico_setor"), height = "300px")
        )
      ),
      div(class = "col-md-6",
        div(class = "chart-card",
          h4("Desempenho Relativo (%)", class = "chart-title"),
          plotlyOutput(ns("grafico_desempenho"), height = "300px")
        )
      )
    ),
    
    div(class = "row charts-row",
      div(class = "col-md-12",
        div(class = "chart-card",
          h4(" heatmap de Correlação", class = "chart-title"),
          plotlyOutput(ns("grafico_correlacao"), height = "350px")
        )
      )
    ),
    
    hr(),
    div(class = "section-title", h3("Tabela de Cotações Detalhada")),
    div(class = "table-container",
      DT::dataTableOutput(ns("tabela_resumo"))
    )
  )
}

indicadoresServer <- function(id, dados) {
  moduleServer(id, function(input, output, session) {
    
    # Calcular métricas completas
    resumo <- reactive({
      precos <- dados$precos
      volumes <- dados$volumes
      retornos <- dados$retornos
      n <- nrow(precos)
      
      lapply(dados$acoes, function(acao) {
        ultimo <- precos[[acao]][n]
        anterior <- precos[[acao]][n - 1]
        variacao <- (ultimo - anterior) / anterior * 100
        
        # Últimos 30 dias para sparkline
        ultimos_30 <- precos[[acao]][(n-29):n]
        
        # Volume médio últimos 30 dias
        vol_med <- mean(volumes[[acao]][(n-29):n])
        
        # Volatilidade (desvio padrão dos retornos últimos 30 dias)
        ret_30 <- diff(log(ultimos_30))
        vol_30 <- sd(ret_30) * sqrt(252) * 100
        
        # Retorno no mês
        ret_mes <- (ultimos_30[30] - ultimos_30[1]) / ultimos_30[1] * 100
        
        # Retorno no ano
        ret_ano <- (ultimo - precos[[acao]][1]) / precos[[acao]][1] * 100
        
        list(
          acao = acao,
          ultimo = ultimo,
          anterior = anterior,
          variacao = variacao,
          min_ano = min(precos[[acao]]),
          max_ano = max(precos[[acao]]),
          vol_med = vol_med,
          vol_30 = vol_30,
          ret_mes = ret_mes,
          ret_ano = ret_ano,
          sparkline = ultimos_30,
          setor = dados$metadados$Setor[which(dados$metadados$Ticker == acao)[1]]
        )
      })
    })
    
    # KPIs de resumo do mercado
    output$kpis_resumo <- renderUI({
      res <- resumo()
      
      precos <- dados$precos
      n <- nrow(precos)
      
      ultimos_vals <- sapply(res, function(r) as.numeric(r$ultimo))
      anteriores_vals <- sapply(res, function(r) as.numeric(r$anterior))
      
      idx_atual <- mean(ultimos_vals, na.rm = TRUE)
      idx_anterior <- mean(anteriores_vals, na.rm = TRUE)
      idx_var <- ifelse(idx_anterior == 0 || is.na(idx_anterior), 0, (idx_atual - idx_anterior) / idx_anterior * 100)
      
      vol_hj <- sum(sapply(dados$acoes, function(a) as.numeric(dados$volumes[[a]][n])), na.rm = TRUE)
      
      variacoes <- sapply(res, function(r) as.numeric(r$variacao))
      best <- which.max(variacoes)
      worst <- which.min(variacoes)
      
      div(class = "kpi-resumo-row",
        div(class = "kpi-resumo-card principal",
          div(class = "kpi-label", "Índice BVMF"),
          div(class = "kpi-value", sprintf("%.2f", idx_atual)),
          div(class = paste0("kpi-var ", if(idx_var >= 0) "alta" else "baixa"),
            sprintf("%s %.2f%%", if(idx_var >= 0) "\u25b2" else "\u25bc", abs(idx_var))
          )
        ),
        div(class = "kpi-resumo-card",
          div(class = "kpi-label", "Volume Hoje"),
          div(class = "kpi-value", sprintf("%.1fM", vol_hj / 1e6)),
          div(class = "kpi-sub", "Ações negociadas")
        ),
        div(class = "kpi-resumo-card alta",
          div(class = "kpi-label", "Melhor Alta"),
          div(class = "kpi-value", res[[best]]$acao),
          div(class = "kpi-var alta", sprintf("+%.2f%%", res[[best]]$variacao))
        ),
        div(class = "kpi-resumo-card baixa",
          div(class = "kpi-label", "Maior Queda"),
          div(class = "kpi-value", res[[worst]]$acao),
          div(class = "kpi-var baixa", sprintf("%.2f%%", res[[worst]]$variacao))
        ),
        div(class = "kpi-resumo-card",
          div(class = "kpi-label", "Vol. Médio 30d"),
          div(class = "kpi-value", sprintf("%.1fM", mean(sapply(res, `[[`, "vol_med")) / 1e6)),
          div(class = "kpi-sub", "por ação")
        )
      )
    })
    
    # Cards por ação com sparkline
    output$cards_acoes <- renderUI({
      res <- resumo()
      acoes_list <- dados$acoes
      cards <- lapply(seq_along(acoes_list), function(i) {
        acao <- acoes_list[[i]]
        r <- res[[i]]
        classe <- if (r$variacao >= 0) "card-alta" else "card-baixa"
        seta <- if (r$variacao >= 0) "\u25b2" else "\u25bc"
        cor_var <- if (r$variacao >= 0) "#00d084" else "#ff4b4b"
        
        spark_data <- data.frame(
          x = 1:length(r$sparkline),
          y = r$sparkline
        )
        
        sparkline <- plot_ly(spark_data, x = ~x, y = ~y, 
          type = "scatter", mode = "lines",
          line = list(color = cor_var, width = 2),
          hoverinfo = "y"
        ) %>% layout(
          margin = list(l = 0, r = 0, t = 0, b = 0),
          xaxis = list(visible = FALSE, showgrid = FALSE, fixedrange = TRUE),
          yaxis = list(visible = FALSE, showgrid = FALSE, fixedrange = TRUE),
          paper_bgcolor = "transparent",
          plot_bgcolor = "transparent",
          dragmode = FALSE,
          hovermode = FALSE
        ) %>% config(displayModeBar = FALSE)
        
        div(class = paste("kpi-card", classe),
          div(class = "kpi-header",
            div(class = "kpi-ticker", acao),
            div(class = "kpi-setor", r$setor)
          ),
          div(class = "kpi-body",
            div(class = "kpi-preco", sprintf("R$ %.2f", r$ultimo)),
            div(class = "kpi-variacao", style = paste0("color:", cor_var),
              sprintf("%s %.2f%%", seta, abs(r$variacao))
            )
          ),
          div(class = "kpi-sparkline", sparkline),
          div(class = "kpi-footer",
            span(class = "kpi-metric", sprintf("Mês: %+.1f%%", r$ret_mes)),
            span(class = "kpi-metric", sprintf("Ano: %+.1f%%", r$ret_ano))
          )
        )
      })
      div(class = "cards-container", do.call(tagList, cards))
    })
    
    # Gráfico de pizza por setor
    output$grafico_setor <- renderPlotly({
      res <- resumo()
      setores <- sapply(res, `[[`, "setor")
      precos <- sapply(res, `[[`, "ultimo")
      
      df_setor <- aggregate(precos ~ setores, FUN = sum)
      names(df_setor) <- c("Setor", "Valor")
      
      colors <- c("Energia" = "#ff6b6b", "Mineração" = "#ffd93d", 
                   "Financeiro" = "#6bcb77", "Consumo" = "#4d96ff")
      
      plot_ly(df_setor, labels = ~Setor, values = ~Valor, type = "pie",
        marker = list(colors = colors[df_setor$Setor]),
        textinfo = "label+percent",
        hoverinfo = "label+value+percent"
      ) %>% layout(
        paper_bgcolor = "#1a1a2e",
        plot_bgcolor = "#1a1a2e",
        font = list(color = "#e0e0e0"),
        margin = list(t = 20, b = 20, l = 20, r = 20)
      )
    })
    
    # Gráfico de barras de desempenho
    output$grafico_desempenho <- renderPlotly({
      res <- resumo()
      
      df <- data.frame(
        Ação = sapply(res, `[[`, "acao"),
        `Mês` = sapply(res, `[[`, "ret_mes"),
        `Ano` = sapply(res, `[[`, "ret_ano")
      )
      
      plot_ly(df, x = ~Ação, y = ~Mês, name = "Mês", type = "bar",
        marker = list(color = "#4d96ff")
      ) %>% add_trace(y = ~Ano, name = "Ano", marker = list(color = "#00d084")) %>%
        layout(
          barmode = "group",
          paper_bgcolor = "#1a1a2e",
          plot_bgcolor = "#1a1a2e",
          font = list(color = "#e0e0e0"),
          xaxis = list(title = "", gridcolor = "#2a2a3e"),
          yaxis = list(title = "Retorno (%)", gridcolor = "#2a2a3e"),
          legend = list(font = list(color = "#e0e0e0")),
          margin = list(t = 20, b = 40, l = 50, r = 20)
        )
    })
    
    # Heatmap de correlação
    output$grafico_correlacao <- renderPlotly({
      precos_df <- dados$precos[, -1, drop = FALSE]
      retornos <- as.data.frame(lapply(precos_df, function(x) diff(log(x))))
      names(retornos) <- dados$acoes
      
      cor_matrix <- round(cor(retornos, use = "complete.obs"), 2)
      
      plot_ly(
        x = dados$acoes, y = dados$acoes, z = cor_matrix,
        type = "heatmap",
        colors = colorRamp(c("#ff4b4b", "#1a1a2e", "#00d084")),
        hoverinfo = "x+y+z"
      ) %>% layout(
        paper_bgcolor = "#1a1a2e",
        plot_bgcolor = "#1a1a2e",
        font = list(color = "#e0e0e0"),
        xaxis = list(title = "", gridcolor = "#2a2a3e"),
        yaxis = list(title = "", gridcolor = "#2a2a3e"),
        margin = list(t = 20, b = 40, l = 50, r = 20)
      )
    })
    
    # Tabela detalhada
    output$tabela_resumo <- DT::renderDataTable({
      res <- resumo()
      acoes_list <- dados$acoes
      tabela <- data.frame(
        Ticker = character(),
        Setor = character(),
        ultimo = numeric(),
        var_dia = numeric(),
        var_mes = numeric(),
        var_ano = numeric(),
        vol_med = numeric(),
        vol_30 = numeric(),
        stringsAsFactors = FALSE
      )
      
      for (i in seq_along(acoes_list)) {
        acao <- acoes_list[[i]]
        r <- res[[i]]
        tabela <- rbind(tabela, data.frame(
          Ticker = acao,
          Setor = as.character(r$setor),
          ultimo = as.numeric(r$ultimo),
          var_dia = as.numeric(r$variacao),
          var_mes = as.numeric(r$ret_mes),
          var_ano = as.numeric(r$ret_ano),
          vol_med = as.numeric(r$vol_med),
          vol_30 = as.numeric(r$vol_30),
          stringsAsFactors = FALSE
        ))
      }
      
      names(tabela) <- c("Ticker", "Setor", "Último (R$)", "Var. Dia (%)", "Var. Mês (%)", "Var. Ano (%)", "Vol. Méd (Milhoes)", "Volat. (%)")
      
      DT::datatable(tabela,
        options = list(
          pageLength = 10,
          dom = "ftip",
          language = list(
            sEmptyTable = "Nenhum registro encontrado",
            sInfo = "Mostrando de _START_ até _END_ de _TOTAL_ registros",
            sInfoEmpty = "Mostrando 0 até 0 de 0 registros",
            sInfoFiltered = "(Filtrados de _MAX_ registros)",
            sInfoPostFix = "",
            sInfoThousands = ".",
            sLengthMenu = "_MENU_ resultados por página",
            sLoadingRecords = "Carregando...",
            sProcessing = "Processando...",
            sZeroRecords = "Nenhum registro encontrado",
            oPaginate = list(
              sNext = "Próximo",
              sPrevious = "Anterior",
              sFirst = "Primeiro",
              sLast = "Último"
            ),
            oAria = list(
              sSortAscending = ": Ordenar colunas de forma ascendente",
              sSortDescending = ": Ordenar colunas de forma descendente"
            )
          )
        ),
        class = "table table-striped table-hover",
        rownames = FALSE
      ) %>% DT::formatStyle(
        columns = "Var. Dia (%)",
        valueColumns = "Var. Dia (%)",
        color = DT::styleInterval(0, c("#ff4b4b", "#00d084"))
      )
    })
  })
}
