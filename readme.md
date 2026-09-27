# Desafio SQL - Análise do Dataset Olist

Este repositório contém as soluções do "Desafio SQL" focado na exploração e análise do **Olist Brazilian E-Commerce Public Dataset** usando a linguagem de consulta estruturada (DQL) em PostgreSQL.

## Objetivo
O projeto visa extrair respostas para perguntas de negócio complexas a partir de uma base de dados real e não otimizada para análise analítica prévia, demonstrando a capacidade de manipular `JOINs`, agregações, subqueries, `Window Functions` e `CTEs`.

## Estrutura do Repositório
* `bloco_A.sql`: Consultas básicas e exploração inicial.
* `bloco_B.sql`: Relacionamento entre entidades (JOINs).
* `bloco_C.sql`: Agrupamento e agregações métricas.
* `bloco_D.sql`: Subqueries correlacionadas e de filtragem.
* `bloco_E.sql`: Classificações lógicas com `CASE WHEN`.
* `bloco_F.sql`: Expressões de Tabela Comuns (CTEs) para métricas compostas.
* `bloco_G.sql`: Criação de visualizações (`VIEWs`) para consumo de BI.
* `bloco_H.sql`: Funções de base de dados parametrizadas para relatórios.
* `bloco_I.sql`: Funções de janela (`Window Functions`) para análises de tendências e rankings.

## Principais Insights da Base de Dados
Durante a construção destas consultas, é possível identificar padrões de negócio interessantes:
1. **Modelagem e Cardinalidade**: Constatou-se a ausência de chaves estrangeiras (`FKs`) rígidas no dataset bruto, exigindo atenção extra ao granular as consultas (`JOINs` entre `orders` e `order_payments` podem gerar duplicações se não agregados corretamente devido a pagamentos em múltiplos cartões).
2. **Logística e Prazos**: Uma parcela significativa de avaliações negativas (< 3) correlaciona-se com discrepâncias temporais descobertas no *Bloco E* (onde a data real de entrega excedeu a data estimada).
3. **Distribuição de Faturamento**: A análise com `Window Functions` (*Bloco I*) demonstra a elevada concentração de faturamento em poucos vendedores por estado (Princípio de Pareto acentuado).
4. **Preferências de Pagamento**: O cartão de crédito domina amplamente em volume de transações parceladas, impactando o ticket médio das categorias de produtos mais dispendiosas avaliadas no *Bloco C*.

## Como Executar
1. Importar os ficheiros CSV do Kaggle para o seu PostgreSQL local.
2. Certificar de que os nomes das tabelas respeitam o padrão: `olist_orders_dataset`, `olist_customers_dataset`, etc.
3. Utilizar um cliente SQL como o DBeaver para rodar os scripts `.sql` presentes neste repositório.