# API de Carregamento em Lote de Pedidos e Itens

Esta documentação descreve os endpoints para carregar pedidos e itens de pedido em lote, evitando duplicatas.

## Endpoints Disponíveis

### 1. Verificar Pedidos Existentes
**POST** `/orders/load_orders`

Verifica quais pedidos já existem baseado em `external_id`.

**Parâmetros:**
```json
{
  "external_ids": ["order_001", "order_002", "order_003"]
}
```

**Resposta:**
```json
{
  "existing_orders": [...],
  "new_external_ids": ["order_002"],
  "total_existing": 2,
  "total_new": 1
}
```

### 2. Carregar Pedidos em Lote
**POST** `/orders/bulk_load_orders`

Carrega múltiplos pedidos de uma vez, evitando duplicatas.

**Parâmetros:**
```json
{
  "orders": [
    {
      "external_id": "order_001",
      "seller_id": 1,
      "sold_at": "2024-01-15T10:30:00Z"
    },
    {
      "external_id": "order_002", 
      "seller_id": 2,
      "sold_at": "2024-01-15T11:00:00Z"
    }
  ]
}
```

**Resposta:**
```json
{
  "success": true,
  "created_orders": [...],
  "skipped_orders": [
    {
      "external_id": "order_001",
      "reason": "Pedido já existe"
    }
  ],
  "errors": [],
  "summary": {
    "total_created_orders": 1,
    "total_skipped_orders": 1,
    "total_errors": 0
  }
}
```

### 3. Carregar Pedidos com Itens
**POST** `/orders/bulk_load_orders_with_items`

Carrega pedidos e seus itens em uma única operação transacional.

**Parâmetros:**
```json
{
  "orders_with_items": [
    {
      "external_id": "order_001",
      "seller_id": 1,
      "sold_at": "2024-01-15T10:30:00Z",
      "order_items": [
        {
          "product_id": 1,
          "store_id": 1,
          "quantity": 2,
          "unit_price": 29.99
        },
        {
          "product_id": 2,
          "store_id": 1,
          "quantity": 1,
          "unit_price": 15.50
        }
      ]
    }
  ]
}
```

**Resposta:**
```json
{
  "success": true,
  "created_orders": [...],
  "created_order_items": [...],
  "skipped_orders": [...],
  "skipped_order_items": [...],
  "errors": [],
  "summary": {
    "total_created_orders": 1,
    "total_created_order_items": 2,
    "total_skipped_orders": 0,
    "total_skipped_order_items": 0,
    "total_errors": 0
  }
}
```

### 4. Verificar Itens de Pedido Existentes
**POST** `/order_items/load_order_items`

Verifica quais itens de pedido já existem baseado em `order_id` e `product_id`.

**Parâmetros:**
```json
{
  "order_items": [
    {
      "order_id": 1,
      "product_id": 1
    },
    {
      "order_id": 1,
      "product_id": 2
    }
  ]
}
```

**Resposta:**
```json
{
  "existing_order_items": [...],
  "new_order_items": [[1, 2]],
  "total_existing": 1,
  "total_new": 1
}
```

### 5. Carregar Itens de Pedido em Lote
**POST** `/order_items/bulk_load_order_items`

Carrega múltiplos itens de pedido de uma vez, evitando duplicatas.

**Parâmetros:**
```json
{
  "order_items": [
    {
      "order_id": 1,
      "product_id": 1,
      "store_id": 1,
      "quantity": 2,
      "unit_price": 29.99
    },
    {
      "order_id": 1,
      "product_id": 2,
      "store_id": 1,
      "quantity": 1,
      "unit_price": 15.50
    }
  ]
}
```

**Resposta:**
```json
{
  "success": true,
  "created_order_items": [...],
  "skipped_order_items": [
    {
      "order_id": 1,
      "product_id": 1,
      "reason": "Item já existe para este pedido e produto"
    }
  ],
  "errors": [],
  "summary": {
    "total_created_order_items": 1,
    "total_skipped_order_items": 1,
    "total_errors": 0
  }
}
```

## Estratégias de Prevenção de Duplicatas

### Para Pedidos
- **Chave única:** `external_id`
- **Comportamento:** Se um pedido com o mesmo `external_id` já existe, ele é pulado
- **Mensagem:** "Pedido já existe"

### Para Itens de Pedido
- **Chave única:** Combinação de `order_id` + `product_id`
- **Comportamento:** Se um item com a mesma combinação já existe, ele é pulado
- **Mensagem:** "Item já existe para este pedido e produto"

## Tratamento de Erros

Todos os endpoints retornam informações detalhadas sobre:
- **Pedidos/Itens criados:** Lista dos registros criados com sucesso
- **Pedidos/Itens pulados:** Lista dos registros que foram pulados por já existirem
- **Erros:** Lista detalhada de erros de validação ou exceções
- **Resumo:** Estatísticas gerais da operação

## Exemplo de Uso com cURL

```bash
# Carregar pedidos em lote
curl -X POST http://localhost:3000/orders/bulk_load_orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "orders": [
      {
        "external_id": "order_001",
        "seller_id": 1,
        "sold_at": "2024-01-15T10:30:00Z"
      }
    ]
  }'

# Carregar pedidos com itens
curl -X POST http://localhost:3000/orders/bulk_load_orders_with_items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "orders_with_items": [
      {
        "external_id": "order_001",
        "seller_id": 1,
        "sold_at": "2024-01-15T10:30:00Z",
        "order_items": [
          {
            "product_id": 1,
            "store_id": 1,
            "quantity": 2,
            "unit_price": 29.99
          }
        ]
      }
    ]
  }'
```

## Benefícios

1. **Performance:** Operações em lote são mais eficientes que múltiplas requisições individuais
2. **Prevenção de Duplicatas:** Evita criar registros duplicados automaticamente
3. **Transacional:** Operações com pedidos e itens são atômicas
4. **Feedback Detalhado:** Informações completas sobre o resultado da operação
5. **Flexibilidade:** Múltiplas opções para diferentes cenários de uso 