# 🚀 Tokens de API - Sail Store Backend

## ✅ Token Super Admin Gerado

**Token com permissões completas para todas as operações da API:**

```
Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E
```

**Credenciais do usuário:**
- **Email:** `superadmin@api.com`
- **Senha:** `superadmin123!`
- **Admin:** `true`
- **Expira em:** 2026-08-05

## 🔧 Como Gerar Novos Tokens

### Método 1: Script Ruby
```bash
# Token Super Admin
ruby scripts/generate_api_token.rb super

# Token Regular
ruby scripts/generate_api_token.rb regular

# Listar todos
ruby scripts/generate_api_token.rb list
```

### Método 2: Tasks Rake
```bash
# Token Super Admin
rails api:generate_super_token

# Token Regular
rails api:generate_test_token

# Listar todos
rails api:list_tokens
```

### Método 3: Endpoint da API
```bash
# Primeiro faça login como admin
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password"}'

# Depois gere o token
curl -X POST http://localhost:3000/auth/generate_api_token \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{"admin": "true"}'
```

## 📋 Exemplos de Uso

### Verificar Token
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/auth/me
```

### Listar Lojas
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  http://localhost:3000/stores
```

### Criar Vendedor
```bash
curl -X POST http://localhost:3000/sellers \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJlbWFpbCI6InN1cGVyYWRtaW5AYXBpLmNvbSIsImFkbWluIjp0cnVlLCJleHAiOjE3ODU5NTE4ODV9.fu-Jkgm08gdMjhalr6Z3Iq-Eqyw8qSOEYu6tENqFa8E" \
  -H "Content-Type: application/json" \
  -d '{"name": "João Silva", "email": "joao@example.com", "store_id": 1}'
```

## 🔒 Endpoints que Requerem Admin

- `GET /metrics` - Métricas do sistema
- `GET /dashboard` - Dashboard administrativo
- `POST /auth/generate_api_token` - Gerar tokens de API
- `GET /users` - Listar usuários
- `POST /users` - Criar usuários
- `PUT /users/:id` - Atualizar usuários
- `DELETE /users/:id` - Deletar usuários

## 📚 Documentação Completa

- **Guia Completo:** `API_TOKEN_GUIDE.md`
- **Exemplos Práticos:** `examples/api_usage_examples.md`

## ⚠️ Segurança

- Este token tem **permissões completas** de Super Admin
- Use apenas em ambientes seguros
- Para produção, sempre use HTTPS
- Mantenha a chave `JWT_SECRET_KEY` segura

## 🎯 Funcionalidades Disponíveis

Com este token você pode:
- ✅ Gerenciar todas as lojas
- ✅ Gerenciar todos os vendedores
- ✅ Gerenciar produtos e categorias
- ✅ Gerenciar vendas e comissionamento
- ✅ Gerenciar escalas e ausências
- ✅ Acessar métricas e dashboards
- ✅ Gerenciar usuários do sistema
- ✅ Gerar novos tokens de API 