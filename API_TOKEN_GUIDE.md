# Guia de Tokens de API - Sail Store Backend

Este guia explica como gerar e usar tokens de API com permissões completas para a aplicação Sail Store.

## 🚀 Métodos para Gerar Tokens

### 1. Usando Tasks do Rake

```bash
# Gerar token de Super Admin (permissões completas)
rails api:generate_super_token

# Gerar token de usuário regular
rails api:generate_test_token

# Listar todos os tokens disponíveis
rails api:list_tokens
```

### 2. Usando Script Ruby

```bash
# Gerar token de Super Admin
ruby scripts/generate_api_token.rb super

# Gerar token de usuário regular
ruby scripts/generate_api_token.rb regular

# Gerar token para email específico
ruby scripts/generate_api_token.rb regular meu@email.com

# Listar todos os tokens
ruby scripts/generate_api_token.rb list
```

### 3. Via Endpoint da API (apenas para admins)

```bash
# Primeiro, faça login como admin
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password"}'

# Use o token retornado para gerar um novo token de API
curl -X POST http://localhost:3000/auth/generate_api_token \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{"admin": "true", "expires_in": 31536000}'
```

## 🔑 Tipos de Tokens

### Super Admin Token
- **Permissões**: Completas (todas as operações)
- **Validade**: 1 ano
- **Email**: `superadmin@api.com`
- **Senha**: `superadmin123!`

### Regular User Token
- **Permissões**: Limitadas (apenas operações do usuário)
- **Validade**: 30 dias
- **Email**: Gerado automaticamente
- **Senha**: Gerada automaticamente

## 📋 Como Usar os Tokens

### 1. Headers HTTP
```bash
curl -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  http://localhost:3000/api/endpoint
```

### 2. Exemplos de Uso

#### Listar todas as lojas
```bash
curl -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  http://localhost:3000/stores
```

#### Criar um vendedor
```bash
curl -X POST http://localhost:3000/sellers \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@example.com",
    "store_id": 1
  }'
```

#### Obter métricas (apenas admins)
```bash
curl -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  http://localhost:3000/metrics
```

## 🔒 Endpoints que Requerem Admin

- `GET /metrics` - Métricas do sistema
- `GET /dashboard` - Dashboard administrativo
- `POST /auth/generate_api_token` - Gerar tokens de API
- `GET /users` - Listar usuários
- `POST /users` - Criar usuários
- `PUT /users/:id` - Atualizar usuários
- `DELETE /users/:id` - Deletar usuários

## 🛡️ Segurança

### Boas Práticas
1. **Nunca compartilhe tokens** em código público
2. **Use variáveis de ambiente** para armazenar tokens
3. **Rotacione tokens** regularmente
4. **Monitore o uso** dos tokens
5. **Revogue tokens** quando não estiverem em uso

### Variável de Ambiente
```bash
# Adicione ao seu .env
JWT_SECRET_KEY=sua_chave_secreta_muito_segura_aqui
```

## 📝 Exemplo Completo

```bash
# 1. Gerar token de Super Admin
rails api:generate_super_token

# 2. Copiar o token gerado
# 3. Usar em requisições

# Exemplo: Listar todas as vendas
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  http://localhost:3000/sales

# Exemplo: Criar uma nova categoria
curl -X POST http://localhost:3000/categories \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{"name": "Eletrônicos", "description": "Produtos eletrônicos"}'
```

## 🔍 Verificar Token

Para verificar se um token é válido:

```bash
curl -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  http://localhost:3000/auth/me
```

Resposta esperada:
```json
{
  "user": {
    "id": 1,
    "email": "superadmin@api.com",
    "admin": true,
    "store_slug": null
  }
}
```

## ⚠️ Importante

- Tokens de Super Admin têm acesso total a todas as funcionalidades
- Use apenas em ambientes seguros e confiáveis
- Para produção, sempre use HTTPS
- Mantenha a chave JWT_SECRET_KEY segura e única 