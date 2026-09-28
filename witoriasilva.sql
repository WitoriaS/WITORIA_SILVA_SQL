-- ==========================================
-- bloco_A.sql: SELECT básico
-- ==========================================

-- 1. Listar os 20 pedidos com status delivered mais recentes, ordenados pela data de entrega.
SELECT order_id, order_delivered_customer_date 
FROM olist_orders_dataset 
WHERE order_status = 'delivered' 
ORDER BY order_delivered_customer_date DESC 
LIMIT 20;

-- 2. Listar todos os produtos de uma categoria específica (usando a tabela de tradução).
SELECT p.product_id, t.product_category_name_english AS categoria_traduzida
FROM olist_products_dataset p
JOIN product_category_name_translation t 
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english = 'bed_bath_table';

-- 3. Listar os métodos de pagamento distintos utilizados na base.
SELECT DISTINCT payment_type 
FROM olist_order_payments_dataset;

-- 4. Listar os produtos com peso acima de 10kg (10000g), ordenados do mais pesado para o mais leve.
SELECT product_id, product_weight_g 
FROM olist_products_dataset 
WHERE product_weight_g > 10000 
ORDER BY product_weight_g DESC;

-- ==========================================
-- bloco_B.sql: JOINS
-- ==========================================

-- 1. Relatório com categoria do produto (traduzida), valor do item, cidade do vendedor.
SELECT t.product_category_name_english AS categoria, i.price AS valor_item, s.seller_city AS cidade_vendedor
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id;

-- 2. Identificar pedidos com atraso na entrega (data real > data estimada).
SELECT o.order_id, c.customer_id, o.order_estimated_delivery_date, o.order_delivered_customer_date
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date;

-- 3. Listar pedidos e formas de pagamento com mais de uma parcela.
SELECT o.order_id, op.payment_type, op.payment_installments
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
WHERE op.payment_installments > 1;

-- 4. Listar produtos e categoria traduzida, incluindo produtos sem tradução cadastrada.
SELECT p.product_id, p.product_category_name, t.product_category_name_english
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name;

-- 5. Pedidos em que o cliente e o vendedor são do mesmo estado.
SELECT o.order_id, c.customer_state
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
WHERE c.customer_state = s.seller_state;

-- ==========================================
-- bloco_C.sql: Funções agregadas + GROUP BY + HAVING
-- ==========================================

-- 1. Faturamento total por estado do cliente.
SELECT c.customer_state, SUM(op.payment_value) AS faturamento_total
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
GROUP BY c.customer_state;

-- 2. Top 10 vendedores por faturamento.
SELECT i.seller_id, SUM(i.price) AS faturamento_total
FROM olist_order_items_dataset i
GROUP BY i.seller_id
ORDER BY faturamento_total DESC
LIMIT 10;

-- 3. Ticket médio por categoria de produto.
SELECT p.product_category_name, AVG(i.price) AS ticket_medio
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
GROUP BY p.product_category_name;

-- 4. Vendedores com nota média de avaliação abaixo de 3.
SELECT i.seller_id, AVG(r.review_score) AS nota_media
FROM olist_order_items_dataset i
JOIN olist_order_reviews_dataset r ON i.order_id = r.order_id
GROUP BY i.seller_id
HAVING AVG(r.review_score) < 3;

-- 5. Quantidade de pedidos por forma de pagamento.
SELECT payment_type, COUNT(DISTINCT order_id) AS qtd_pedidos
FROM olist_order_payments_dataset
GROUP BY payment_type;

-- 6. Peso médio dos produtos por categoria.
SELECT product_category_name, AVG(product_weight_g) AS peso_medio
FROM olist_products_dataset
GROUP BY product_category_name;

-- 7. Número médio de parcelas por categoria de produto.
SELECT p.product_category_name, AVG(op.payment_installments) AS media_parcelas
FROM olist_order_items_dataset i
JOIN olist_products_dataset p ON i.product_id = p.product_id
JOIN olist_order_payments_dataset op ON i.order_id = op.order_id
GROUP BY p.product_category_name;

-- ==========================================
-- bloco_D.sql: Subqueries
-- ==========================================

-- 1. Clientes cujo gasto total está acima da média geral de gasto por cliente.
SELECT customer_id, total_gasto FROM (
    SELECT o.customer_id, SUM(op.payment_value) AS total_gasto
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
    GROUP BY o.customer_id
) agrupado
WHERE total_gasto > (
    SELECT SUM(payment_value) / COUNT(DISTINCT order_id) FROM olist_order_payments_dataset
);

-- 2. Produtos que nunca receberam avaliação (NOT IN).
SELECT product_id 
FROM olist_products_dataset 
WHERE product_id NOT IN (
    SELECT DISTINCT i.product_id 
    FROM olist_order_items_dataset i
    JOIN olist_order_reviews_dataset r ON i.order_id = r.order_id
);

-- 3. Vendedores que venderam produtos de mais de 5 categorias diferentes.
SELECT seller_id 
FROM (
    SELECT i.seller_id, COUNT(DISTINCT p.product_category_name) AS qtd_categorias
    FROM olist_order_items_dataset i
    JOIN olist_products_dataset p ON i.product_id = p.product_id
    GROUP BY i.seller_id
) sub
WHERE qtd_categorias > 5;

-- 4. Pedidos cujo valor de frete é maior que o valor total dos itens.
SELECT order_id 
FROM olist_order_items_dataset i1
GROUP BY order_id
HAVING SUM(freight_value) > (
    SELECT SUM(price) FROM olist_order_items_dataset i2 WHERE i1.order_id = i2.order_id
);

-- ==========================================
-- bloco_E.sql: CASE WHEN
-- ==========================================

-- 1. Classificar pedidos por prazo de entrega.
SELECT order_id,
    CASE 
        WHEN order_delivered_customer_date < order_estimated_delivery_date THEN 'adiantado'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'atrasado'
        ELSE 'no prazo'
    END AS status_prazo
FROM olist_orders_dataset
WHERE order_status = 'delivered';

-- 2. Classificar clientes por faixa de gasto total.
SELECT o.customer_id, SUM(op.payment_value) AS gasto_total,
    CASE 
        WHEN SUM(op.payment_value) > 1000 THEN 'ouro'
        WHEN SUM(op.payment_value) > 500 THEN 'prata'
        ELSE 'bronze'
    END AS classificacao_cliente
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
GROUP BY o.customer_id;

-- 3. Classificar produtos por faixa de peso.
SELECT product_id, product_weight_g,
    CASE 
        WHEN product_weight_g < 2000 THEN 'leve'
        WHEN product_weight_g <= 10000 THEN 'médio'
        ELSE 'pesado'
    END AS categoria_peso
FROM olist_products_dataset;

-- 4. Classificar pagamentos e sinalizar parcelamentos longos.
SELECT order_id, payment_installments,
    CASE 
        WHEN payment_installments = 1 THEN 'à vista'
        WHEN payment_installments > 6 THEN 'parcelado longo'
        ELSE 'parcelado'
    END AS tipo_pagamento
FROM olist_order_payments_dataset;

-- ==========================================
-- bloco_F.sql: CTE / Tabela temporária
-- ==========================================

-- 1. Variação percentual de faturamento mensal por estado.
WITH faturamento_mensal AS (
    SELECT c.customer_state, DATE_TRUNC('month', o.order_purchase_timestamp) AS mes, SUM(op.payment_value) AS total
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
    GROUP BY 1, 2
)
SELECT customer_state, mes, total,
    LAG(total) OVER(PARTITION BY customer_state ORDER BY mes) AS total_mes_anterior,
    ((total - LAG(total) OVER(PARTITION BY customer_state ORDER BY mes)) / LAG(total) OVER(PARTITION BY customer_state ORDER BY mes)) * 100 AS variacao_percentual
FROM faturamento_mensal;

-- 2. Categorias com pior reputação.
WITH avaliacoes_categoria AS (
    SELECT p.product_category_name, COUNT(r.review_id) AS volume_avaliacoes, AVG(r.review_score) AS nota_media
    FROM olist_order_reviews_dataset r
    JOIN olist_order_items_dataset i ON r.order_id = i.order_id
    JOIN olist_products_dataset p ON i.product_id = p.product_id
    GROUP BY p.product_category_name
)
SELECT * FROM avaliacoes_categoria 
WHERE volume_avaliacoes > 50 AND nota_media < 3.5 
ORDER BY nota_media ASC;

-- 3. Comparação de frete médio por estado vs média geral.
WITH frete_estado AS (
    SELECT c.customer_state, AVG(i.freight_value) AS frete_medio_estado
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
)
SELECT customer_state, frete_medio_estado,
    (SELECT AVG(freight_value) FROM olist_order_items_dataset) AS frete_medio_geral
FROM frete_estado;

-- ==========================================
-- bloco_G.sql: Views
-- ==========================================

-- 1. View vw_pedidos_completos
CREATE OR REPLACE VIEW vw_pedidos_completos AS
SELECT o.order_id, c.customer_id, c.customer_state, i.product_id, i.seller_id, i.price, op.payment_type, op.payment_value
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset i ON o.order_id = i.order_id
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id;

-- 2. View vw_avaliacoes_categoria
CREATE OR REPLACE VIEW vw_avaliacoes_categoria AS
SELECT p.product_category_name, COUNT(r.review_id) AS volume_avaliacoes, AVG(r.review_score) AS nota_media
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset i ON r.order_id = i.order_id
JOIN olist_products_dataset p ON i.product_id = p.product_id
GROUP BY p.product_category_name;

-- ==========================================
-- bloco_H.sql: Procedures/Functions (Leitura)
-- ==========================================

-- 1. Function sp_relatorio_vendedor
CREATE OR REPLACE FUNCTION sp_relatorio_vendedor(p_id_vendedor VARCHAR, p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE (faturamento NUMERIC, ticket_medio NUMERIC, nota_media NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CAST(SUM(i.price) AS NUMERIC), 
        CAST(AVG(i.price) AS NUMERIC), 
        CAST(AVG(r.review_score) AS NUMERIC)
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
    WHERE i.seller_id = p_id_vendedor 
      AND DATE(o.order_purchase_timestamp) BETWEEN p_data_inicio AND p_data_fim;
END;
$$ LANGUAGE plpgsql;

-- 2. Function sp_relatorio_categoria
CREATE OR REPLACE FUNCTION sp_relatorio_categoria(p_categoria VARCHAR, p_data_inicio DATE, p_data_fim DATE)
RETURNS TABLE (faturamento NUMERIC, ticket_medio NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CAST(SUM(i.price) AS NUMERIC), 
        CAST(AVG(i.price) AS NUMERIC)
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    JOIN olist_products_dataset p ON i.product_id = p.product_id
    WHERE p.product_category_name = p_categoria 
      AND DATE(o.order_purchase_timestamp) BETWEEN p_data_inicio AND p_data_fim;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- bloco_I.sql: Window Functions
-- ==========================================

-- 1. Ranking dos vendedores por faturamento dentro de cada estado.
SELECT s.seller_state, i.seller_id, SUM(i.price) AS faturamento,
    RANK() OVER(PARTITION BY s.seller_state ORDER BY SUM(i.price) DESC) AS rank_vendedor
FROM olist_order_items_dataset i
JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
GROUP BY s.seller_state, i.seller_id;

-- 2. Faturamento mensal acumulado por vendedor.
WITH fat_mensal AS (
    SELECT i.seller_id, DATE_TRUNC('month', o.order_purchase_timestamp) AS mes, SUM(i.price) AS total_mes
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    GROUP BY i.seller_id, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT seller_id, mes, total_mes,
    SUM(total_mes) OVER(PARTITION BY seller_id ORDER BY mes) AS faturamento_acumulado
FROM fat_mensal;

-- 3. Percentual de participação de cada vendedor no faturamento total do seu estado.
WITH fat_vendedor AS (
    SELECT s.seller_state, i.seller_id, SUM(i.price) AS faturamento_vendedor
    FROM olist_order_items_dataset i
    JOIN olist_sellers_dataset s ON i.seller_id = s.seller_id
    GROUP BY s.seller_state, i.seller_id
)
SELECT seller_state, seller_id, faturamento_vendedor,
    SUM(faturamento_vendedor) OVER(PARTITION BY seller_state) AS faturamento_estado,
    (faturamento_vendedor / SUM(faturamento_vendedor) OVER(PARTITION BY seller_state)) * 100 AS percentual_participacao
FROM fat_vendedor;

-- 4. Variação de faturamento de um mês para o outro por vendedor (LAG).
WITH fat_mensal AS (
    SELECT 
        i.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS mes,
        SUM(i.price) AS total_faturado
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o ON i.order_id = o.order_id
    GROUP BY 
        i.seller_id, 
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp)
)
SELECT 
    seller_id,
    mes,
    total_faturado,
    LAG(total_faturado) OVER (PARTITION BY seller_id ORDER BY mes) AS faturamento_mes_anterior,
    total_faturado - LAG(total_faturado) OVER (PARTITION BY seller_id ORDER BY mes) AS variacao_faturamento
FROM fat_mensal
ORDER BY 
    seller_id, 
    mes;
