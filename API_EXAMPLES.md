# Exemplos de Uso da API

Este arquivo contém exemplos práticos de como usar a API do Sail Store Backend com autenticação JWT.

## Pré-requisitos

1. Configure as variáveis de ambiente (veja `ENV_SETUP.md`)
2. Execute `rails db:seed` para criar o usuário admin
3. Inicie o servidor: `rails server`

## Exemplos de Uso

### 1. Login como Admin

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

**Resposta esperada:**
```json
{
  "message": "Login realizado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJ1c2VybmFtZSI6ImFkbWluIiwiYWRtaW4iOnRydWUsImV4cCI6MTYzMjU2NzIwMH0...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "admin": true
  }
}
```

### 2. Verificar usuário atual

```bash
curl -X GET http://localhost:3000/auth/me \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

### 3. Criar uma nova store (requer admin)

```bash
curl -X POST http://localhost:3000/stores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -d '{
    "store": {
      "name": "Loja Central",
      "cnpj": "12345678901234",
      "address": "Rua das Flores, 123 - Centro"
    }
  }'
```

### 4. Listar todas as stores

```bash
curl -X GET http://localhost:3000/stores \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

### 5. Registrar um novo usuário

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "username": "usuario1",
      "email": "usuario1@example.com",
      "password": "senha123",
      "password_confirmation": "senha123"
    }
  }'
```

### 6. Criar um usuário admin (apenas admin)

```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -d '{
    "user": {
      "username": "admin2",
      "email": "admin2@example.com",
      "password": "senha123",
      "password_confirmation": "senha123",
      "admin": true
    }
  }'
```

### 7. Listar todos os usuários (apenas admin)

```bash
curl -X GET http://localhost:3000/users \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

## Endpoints de Sellers

### 8. Listar vendedores por loja

```bash
curl -X GET http://localhost:3000/stores/souq-sp-iguatemi-sp/sellers \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

**Resposta esperada:**
```json
{
  "sellers": [
    {
      "id": 1,
      "name": "João Silva",
      "code": "001",
      "active": true,
      "queue_order": 1,
      "store_id": 1
    },
    {
      "id": 2,
      "name": "Maria Santos",
      "code": "002", 
      "active": true,
      "queue_order": 2,
      "store_id": 1
    }
  ]
}
```

### 9. Atualizar ordem de fila dos vendedores

```bash
curl -X PUT http://localhost:3000/stores/souq-sp-iguatemi-sp/sellers/queue_order \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -d '{
    "queue_order": [
      {"seller_id": 2, "queue_order": 1},
      {"seller_id": 1, "queue_order": 2},
      {"seller_id": 3, "queue_order": 3}
    ]
  }'
```

**Resposta esperada:**
```json
{
  "message": "Ordem de fila atualizada com sucesso",
  "updated_sellers": [
    {"id": 2, "name": "Maria Santos", "queue_order": 1},
    {"id": 1, "name": "João Silva", "queue_order": 2},
    {"id": 3, "name": "Pedro Costa", "queue_order": 3}
  ]
}
```

### 10. Obter detalhes de um vendedor específico

```bash
curl -X GET http://localhost:3000/stores/souq-sp-iguatemi-sp/sellers/1 \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

**Resposta esperada:**
```json
{
  "seller": {
    "id": 1,
    "name": "João Silva",
    "code": "001",
    "active": true,
    "queue_order": 1,
    "store_id": 1,
    "phone": "+5511999999999",
    "whatsapp": "+5511999999999"
  }
}
```

## Endpoints Beta (Funcionalidades Experimentais)

### 11. Obter KPIs de um vendedor

```bash
curl -X GET http://localhost:3000/beta/sellers/1/kpis \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

**Resposta esperada:**
```json
{
  "seller": {
    "id": 1,
    "name": "João Silva",
    "primeiro_nome": "João",
    "whatsapp": "+5511999999999"
  },
  "kpis": {
    "vendas_hoje": 1500.00,
    "vendas_mes": 45000.00,
    "meta_progresso": 75.5
  }
}
```

## Testando com diferentes níveis de acesso

### Usuário Regular tentando criar store
```bash
# Login como usuário regular
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "usuario1@example.com", "password": "senha123"}'

# Guardar o token retornado e usar no próximo comando
TOKEN="eyJhbGciOiJIUzI1NiJ9..."

# Tentar criar store (será negado)
curl -X POST http://localhost:3000/stores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"store": {"name": "Loja", "cnpj": "123", "address": "Rua"}}'
```

**Resposta esperada:**
```json
{
  "error": "Acesso negado. Apenas administradores podem acessar este recurso."
}
```

### Usuário Regular tentando acessar lista de usuários
```bash
curl -X GET http://localhost:3000/users \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta esperada:**
```json
{
  "error": "Acesso negado. Apenas administradores podem acessar este recurso."
}
```

## Script de exemplo completo

```bash
#!/bin/bash

# 1. Login como admin
echo "Fazendo login como admin..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}')

# Extrair token da resposta
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Token obtido: $TOKEN"

# 2. Verificar usuário atual
echo "Verificando usuário atual..."
curl -X GET http://localhost:3000/auth/me \
  -H "Authorization: Bearer $TOKEN"

# 3. Criar uma store
echo "Criando store..."
curl -X POST http://localhost:3000/stores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"store": {"name": "Loja Teste", "cnpj": "12345678901234", "address": "Rua Teste, 123"}}'

# 4. Listar stores
echo "Listando stores..."
curl -X GET http://localhost:3000/stores \
  -H "Authorization: Bearer $TOKEN"

# 5. Listar vendedores
echo "Listando vendedores..."
curl -X GET http://localhost:3000/stores/souq-sp-iguatemi-sp/sellers \
  -H "Authorization: Bearer $TOKEN"

# 6. Atualizar ordem de fila
echo "Atualizando ordem de fila..."
curl -X PUT http://localhost:3000/stores/souq-sp-iguatemi-sp/sellers/queue_order \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"queue_order": [{"seller_id": 1, "queue_order": 1}]}'
```

## Notas Importantes

1. **Tokens JWT**: O sistema usa JWT para autenticação. Guarde o token retornado pelo login e use no header `Authorization: Bearer TOKEN`.

2. **Expiração**: Tokens JWT expiram em 24 horas por padrão.

3. **Controle de Acesso**:
   - Usuários admin podem fazer tudo
   - Usuários regulares podem apenas visualizar stores
   - Apenas admins podem gerenciar usuários
   - Usuários de loja podem gerenciar vendedores da sua loja

4. **Validações**:
   - Senhas devem ter pelo menos 6 caracteres
   - Emails devem ser válidos
   - Usernames devem ser únicos
   - Queue order deve ser um número inteiro positivo

5. **Segurança**:
   - Senhas são hasheadas com bcrypt
   - Tokens JWT são assinados com chave secreta
   - Todas as operações sensíveis requerem autenticação
   - Configure uma chave JWT segura em produção

6. **Funcionalidades de Fila**:
   - `queue_order` determina a ordem de atendimento dos vendedores
   - Vendedores com menor `queue_order` têm prioridade
   - A ordem pode ser alterada dinamicamente via API
   - Mudanças na ordem são persistidas no banco de dados 