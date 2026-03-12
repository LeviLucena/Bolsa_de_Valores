# Bolsa de Valores - Aplicação Shiny
![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Shiny](https://img.shields.io/badge/Shiny-1F77B4?style=for-the-badge&logo=rstudio&logoColor=white)
![Plotly](https://img.shields.io/badge/Plotly-3F4F75?style=for-the-badge&logo=plotly&logoColor=white)
![dplyr](https://img.shields.io/badge/dplyr-1A162D?style=for-the-badge&logo=r&logoColor=white)

Aplicação web interativa para análise de dados da bolsa de valores, desenvolvida em R com o framework Shiny.

<img width="1889" height="774" alt="image" src="https://github.com/user-attachments/assets/d4cfe47b-6266-44d3-b12b-29a54eb83993" />
<img width="1811" height="872" alt="Screenshot_2" src="https://github.com/user-attachments/assets/b4ea979c-b802-4317-b239-7e1efb91ba49" />

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

<img width="1842" height="897" alt="Screenshot_3" src="https://github.com/user-attachments/assets/2b409938-0392-4af5-8037-80eb0d5bc503" />

## Licença

MIT License - sinta-se livre para usar e modificar.

---

Desenvolvido por [Levi Lucena](https://www.linkedin.com/in/levilucena/)
