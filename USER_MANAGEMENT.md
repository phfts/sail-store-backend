# Gerenciamento de Usuários

Este documento descreve como gerenciar usuários no sistema usando as rake tasks disponíveis.

## Comandos Disponíveis

### 1. Seeds com Senha Personalizada

Ao executar `rails db:seed`, o sistema agora perguntará a senha do admin:

```bash
rails db:seed
```

O sistema irá:
- Perguntar a senha para o admin
- Solicitar confirmação da senha
- Criar o usuário admin com a senha escolhida

### 2. Alterar Senha de Usuário

Para alterar a senha de qualquer usuário:

```bash
rails user:change_password
```

O sistema irá:
- Solicitar o email do usuário
- Verificar se o usuário existe
- Solicitar a nova senha
- Solicitar confirmação da senha
- Atualizar a senha

### 3. Listar Usuários

Para ver todos os usuários do sistema:

```bash
rails user:list
```

Mostra:
- ID do usuário
- Email
- Status admin (Sim/Não)
- Data de criação

### 4. Criar Novo Admin

Para criar um novo usuário administrador:

```bash
rails user:create_admin
```

O sistema irá:
- Solicitar email do novo admin
- Verificar se o email já existe
- Solicitar senha
- Solicitar confirmação da senha
- Criar o usuário com privilégios de admin

### 5. Promover Usuário para Admin

Para promover um usuário existente para admin:

```bash
rails user:promote_to_admin
```

O sistema irá:
- Solicitar email do usuário
- Verificar se o usuário existe
- Confirmar a promoção
- Dar privilégios de admin ao usuário

### 6. Remover Privilégios de Admin

Para remover privilégios de admin de um usuário:

```bash
rails user:demote_from_admin
```

O sistema irá:
- Solicitar email do admin
- Verificar se é o último admin (não permite remover)
- Confirmar a remoção
- Remover privilégios de admin

## Validações

- **Senhas**: Devem ter pelo menos 6 caracteres
- **Emails**: Devem ser únicos no sistema
- **Último Admin**: Não é possível remover o último admin do sistema
- **Confirmação**: Senhas devem ser confirmadas

## Exemplos de Uso

### Primeiro Setup do Sistema

```bash
# 1. Executar migrations
rails db:migrate

# 2. Executar seeds (vai pedir senha do admin)
rails db:seed
# Digite a senha para o usuário admin (admin@sail.app.br): sua_senha_aqui
# Confirme a senha: sua_senha_aqui

# 3. Verificar usuários criados
rails user:list
```

### Gerenciar Usuários Existentes

```bash
# Alterar senha de um usuário
rails user:change_password
# Digite o email do usuário: usuario@exemplo.com
# Digite a nova senha: nova_senha
# Confirme a nova senha: nova_senha

# Criar novo admin
rails user:create_admin
# Digite o email do novo admin: admin2@exemplo.com
# Digite a senha: senha_admin2
# Confirme a senha: senha_admin2

# Promover usuário para admin
rails user:promote_to_admin
# Digite o email do usuário: usuario@exemplo.com
# Confirma a promoção de usuario@exemplo.com para admin? (s/N): s
```

## Segurança

- As senhas são criptografadas automaticamente pelo Rails
- Não há logs das senhas digitadas
- Confirmação obrigatória para operações sensíveis
- Proteção contra remoção do último admin

## Troubleshooting

### Problema: "Usuário não encontrado"
- Verifique se o email está correto
- Use `rails user:list` para ver todos os usuários

### Problema: "Senha muito curta"
- Senhas devem ter pelo menos 6 caracteres
- Digite uma senha mais longa

### Problema: "Não é possível remover o último admin"
- Crie outro admin antes de remover o atual
- Use `rails user:create_admin` ou `rails user:promote_to_admin`
