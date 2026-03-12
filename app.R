# ============================================================
# app.R — Ponto de entrada | B3 Análise de Bolsa de Valores
# ============================================================
# Pacotes necessários:
#   install.packages(c("shiny", "plotly", "dplyr", "tidyr", "htmlwidgets"))
# ============================================================

library(shiny)
library(plotly)
library(tidyr)

# Carregar módulos e dados
source("R/mock_data.R")
source("R/modules/indicadores_module.R")
source("R/modules/precos_module.R")
source("R/modules/volume_module.R")
source("R/modules/correlacao_module.R")
source("R/modules/volatilidade_module.R")
source("R/modules/relatorio_module.R")

# Gerar dados mock uma única vez
dados <- gerar_dados_mock(seed = 42, num_dias = 252)

# ── UI ──────────────────────────────────────────────────────
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$title("B3 - Análise de Bolsa de Valores")
  ),

  # Header
  div(class = "header-banner",
    div(class = "header-content",
      div(
        h1(
          tags$span("B3", class = "b3", style = "color:#00d084"),
          " — Análise de Bolsa de Valores",
          class = "app-title"
        ),
        p(
          paste0(
            "Dados simulados (mock) | ",
            length(dados$acoes), " ações | ",
            format(dados$data_inicio, "%d/%m/%Y"), " a ",
            format(dados$data_fim,    "%d/%m/%Y")
          ),
          class = "app-subtitle"
        )
      )
    )
  ),

  # Conteúdo principal com tabs
  div(class = "main-content",
    tabsetPanel(id = "main_tabs",
      tabPanel("Dashboard",    indicadoresUI("indicadores")),
      tabPanel("Preços",       precosUI("precos")),
      tabPanel("Volume",       volumeUI("volume")),
      tabPanel("Correlação",   correlacaoUI("correlacao")),
      tabPanel("Volatilidade", volatilidadeUI("volatilidade")),
      tabPanel("Relatório",    relatorioUI("relatorio"))
    )
  )
)

# ── Server ──────────────────────────────────────────────────
server <- function(input, output, session) {
  indicadoresServer("indicadores", dados)
  precosServer("precos",           dados)
  volumeServer("volume",           dados)
  correlacaoServer("correlacao",   dados)
  volatilidadeServer("volatilidade", dados)
  relatorioServer("relatorio",     dados)
}

# ── Iniciar ─────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
