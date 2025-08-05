# Exemplos de Uso da API com Tokens

## Token Gerado
```
Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E
```

## 🔍 Exemplos de Requisições

### 1. Verificar Token
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/auth/me
```

### 2. Listar Todas as Lojas
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/stores
```

### 3. Criar uma Nova Loja
```bash
curl -X POST http://localhost:3000/stores \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Loja Exemplo",
    "slug": "loja-exemplo",
    "address": "Rua Exemplo, 123"
  }'
```

### 4. Listar Todos os Vendedores
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/sellers
```

### 5. Criar um Vendedor
```bash
curl -X POST http://localhost:3000/sellers \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@example.com",
    "store_id": 1
  }'
```

### 6. Listar Produtos
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/products
```

### 7. Criar um Produto
```bash
curl -X POST http://localhost:3000/products \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Produto Exemplo",
    "description": "Descrição do produto",
    "price": 99.99,
    "category_id": 1
  }'
```

### 8. Obter Métricas (Apenas Admin)
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/metrics
```

### 9. Dashboard Administrativo
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/dashboard
```

### 10. Listar Vendas
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/sales
```

### 11. Criar uma Venda
```bash
curl -X POST http://localhost:3000/sales \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  -H "Content-Type: application/json" \
  -d '{
    "seller_id": 1,
    "amount": 150.00,
    "date": "2024-08-05"
  }'
```

## 📝 Usando com JavaScript/Fetch

```javascript
const token = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E';

// Exemplo: Listar lojas
fetch('http://localhost:3000/stores', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
})
.then(response => response.json())
.then(data => console.log(data));

// Exemplo: Criar vendedor
fetch('http://localhost:3000/sellers', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: 'Maria Silva',
    email: 'maria@example.com',
    store_id: 1
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

## 🐍 Usando com Python/Requests

```python
import requests

token = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E'

headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

# Listar lojas
response = requests.get('http://localhost:3000/stores', headers=headers)
print(response.json())

# Criar vendedor
data = {
    'name': 'Pedro Santos',
    'email': 'pedro@example.com',
    'store_id': 1
}
response = requests.post('http://localhost:3000/sellers', headers=headers, json=data)
print(response.json())
```

## ⚠️ Importante

- Este token tem permissões de **Super Admin** e pode acessar todas as funcionalidades
- Use apenas em ambientes seguros
- O token expira em **1 ano** (2026-08-05)
- Para produção, sempre use HTTPS 