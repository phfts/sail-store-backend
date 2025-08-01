# Sail Store Backend

Backend Rails API para o sistema Sail Store com autenticação e controle de acesso baseado em roles.

## Funcionalidades

- **Autenticação**: Sistema de login/logout com sessões
- **Controle de Acesso**: Usuários admin têm acesso total, usuários regulares têm acesso limitado
- **Gestão de Usuários**: Apenas admins podem gerenciar usuários
- **Gestão de Stores**: CRUD completo para stores (criação/edição/exclusão apenas para admins)

## Configuração

### 1. Instalar dependências
```bash
bundle install
```

### 2. Configurar banco de dados
```bash
rails db:create
rails db:migrate
```

### 3. Configurar variáveis de ambiente
Crie um arquivo `.env` na raiz do projeto:

```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
ADMIN_EMAIL=admin@example.com
```

### 4. Criar usuário admin inicial
```bash
rails db:seed
```

## API Endpoints

### Autenticação
- `POST /auth/login` - Login de usuário (retorna token JWT)
- `POST /auth/register` - Registro de novo usuário (retorna token JWT)
- `GET /auth/me` - Informações do usuário atual

### Stores (protegido por autenticação)
- `GET /stores` - Listar todas as stores (todos os usuários)
- `GET /stores/:id` - Ver store específica (todos os usuários)
- `POST /stores` - Criar store (apenas admin)
- `PUT /stores/:id` - Atualizar store (apenas admin)
- `DELETE /stores/:id` - Excluir store (apenas admin)

### Usuários (apenas admin)
- `GET /users` - Listar todos os usuários
- `GET /users/:id` - Ver usuário específico
- `POST /users` - Criar usuário
- `PUT /users/:id` - Atualizar usuário
- `DELETE /users/:id` - Excluir usuário

## Exemplos de Uso

### Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}'
```

**Resposta:**
```json
{
  "message": "Login realizado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "admin": true
  }
}
```

### Criar Store (requer admin)
```bash
curl -X POST http://localhost:3000/stores \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -d '{"store": {"name": "Loja Teste", "cnpj": "12345678901234", "address": "Rua Teste, 123"}}'
```

## Controle de Acesso

- **Usuários Admin**: Acesso total a todas as funcionalidades
- **Usuários Regulares**: Apenas visualização de stores, sem permissão para criar/editar/excluir

## Desenvolvimento

```bash
# Iniciar servidor
rails server

# Executar testes
rails test

# Verificar rotas
rails routes
```

## Segurança

- Senhas são hasheadas com bcrypt
- Autenticação via JWT (JSON Web Tokens)
- Tokens expiram em 24 horas
- Controle de acesso baseado em roles
- Validações de entrada em todos os endpoints
