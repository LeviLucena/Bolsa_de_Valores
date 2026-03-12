# Bolsa de Valores - Aplicação Shiny

Aplicação web interativa para análise de dados da bolsa de valores, desenvolvida em R com o framework Shiny.

![Preview](https://github.com/LeviLucena/Bolsa_de_Valores/assets/34045910/eb85bf90-f647-4c14-926e-caebb5dd5cd9)

## Funcionalidades

| Aba | Descrição |
|-----|-----------|
| **Preços** | Gráfico de linha interativo com preços históricos das ações |
| **Volume** | Gráfico de barras com volume de negociação diário |
| **Correlação** | Mapa de calor da matriz de correlação entre ações |
| **Volatilidade** | Gráfico de linha com volatilidade histórica |
| **Relatório** | Visualização integrada com opção de exportar e imprimir |

## Tecnologias

- **R** - Linguagem de programação
- **Shiny** - Framework web
- **Plotly** - Gráficos interativos
- **dplyr** - Manipulação de dados

## Instalação

```r
# Instale as dependências
install.packages(c("shiny", "plotly", "dplyr"))
```

## Como Executar

```r
# Clone o repositório
git clone https://github.com/LeviLucena/Bolsa_de_Valores.git
cd Bolsa_de_Valores

# Execute no RStudio
# Abra o arquivo app.R e clique em "Run App"

# Ou via console
shiny::runApp("app.R")
```

## Screenshots

![Preços](https://github.com/LeviLucena/Bolsa_de_Valores/assets/34045910/da250b4a-fe8e-4fd2-a8f7-73e5573a70e1)

![Volume](https://github.com/LeviLucena/Bolsa_de_Valores/assets/34045910/e75dfdc1-df6e-4d95-a15d-7c2b7c8ee751)

![Correlação](https://github.com/LeviLucena/Bolsa_de_Valores/assets/34045910/06f71af7-1239-4a83-a8d3-cc80aae399a5)

![Volatilidade](https://github.com/LeviLucena/Bolsa_de_Valores/assets/34045910/dc7ff6fc-7828-4374-bee4-8898e4fd3d8f)

## Licença

MIT License - sinta-se livre para usar e modificar.

---

Desenvolvido por [Levi Lucena](https://www.linkedin.com/in/levilucena/)
