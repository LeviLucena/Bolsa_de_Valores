# ============================================================
# mock_data.R — Geração de dados simulados (Bolsa B3)
# ============================================================

#' Simula preços via Movimento Browniano Geométrico (GBM)
simular_gbm <- function(S0, mu, sigma, n) {
  Z <- rnorm(n)
  retornos <- (mu - 0.5 * sigma^2) + sigma * Z
  c(S0, S0 * cumprod(exp(retornos)))[1:n]
}

#' Gera todos os dados mock da aplicação
#' @param seed Semente para reprodutibilidade
#' @param num_dias Número de dias de simulação
gerar_dados_mock <- function(seed = 42, num_dias = 252) {
  set.seed(seed)

  # Datas (dias úteis aproximados)
  datas <- seq(as.Date("2024-01-02"), by = "day", length.out = num_dias)

  # Parâmetros das ações (B3)
  acoes_params <- list(
    PETR4 = list(S0 = 36.50, mu = 0.00020, sigma = 0.022, vol_medio = 45e6, setor = "Energia"),
    VALE3 = list(S0 = 68.20, mu = 0.00010, sigma = 0.025, vol_medio = 38e6, setor = "Mineração"),
    ITUB4 = list(S0 = 32.80, mu = 0.00015, sigma = 0.018, vol_medio = 52e6, setor = "Financeiro"),
    BBDC4 = list(S0 = 14.50, mu = 0.00010, sigma = 0.020, vol_medio = 41e6, setor = "Financeiro"),
    ABEV3 = list(S0 = 12.90, mu = 0.00008, sigma = 0.015, vol_medio = 35e6, setor = "Consumo")
  )

  nomes <- names(acoes_params)

  # Gerar preços e volumes
  precos_df  <- data.frame(Data = datas)
  volumes_df <- data.frame(Data = datas)

  for (nome in nomes) {
    p <- acoes_params[[nome]]
    precos_df[[nome]]  <- simular_gbm(p$S0, p$mu, p$sigma, num_dias)
    volumes_df[[nome]] <- pmax(
      rnorm(num_dias, mean = p$vol_medio, sd = p$vol_medio * 0.30),
      p$vol_medio * 0.10
    )
  }

  # Calcular retornos diários
  retornos_df <- data.frame(Data = datas[-1])
  for (nome in nomes) {
    retornos_df[[nome]] <- diff(log(precos_df[[nome]]))
  }

  # Volatilidade histórica rolante (21 dias) — reutiliza retornos_df já calculado
  volatilidade_rolante <- data.frame(Data = datas)
  for (nome in nomes) {
    ret <- c(NA, retornos_df[[nome]])   # retornos já calculados no loop anterior
    vol_rol <- sapply(seq_along(ret), function(i) {
      if (i < 21) return(NA)
      sd(ret[(i - 20):i], na.rm = TRUE) * sqrt(252) * 100
    })
    volatilidade_rolante[[nome]] <- vol_rol
  }

  # Metadados das ações
  metadados <- data.frame(
    Ticker = nomes,
    Setor  = sapply(acoes_params, `[[`, "setor"),
    stringsAsFactors = FALSE
  )

  list(
    precos             = precos_df,
    volumes            = volumes_df,
    retornos           = retornos_df,
    volatilidade       = volatilidade_rolante,
    acoes              = nomes,
    metadados          = metadados,
    data_inicio        = min(datas),
    data_fim           = max(datas)
  )
}
