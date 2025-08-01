# Configuração de Variáveis de Ambiente

Este projeto requer algumas variáveis de ambiente para funcionar corretamente, especialmente para criar o usuário admin inicial e configurar JWT.

## Variáveis Obrigatórias

### Para o usuário admin:
- `ADMIN_NAME`: Nome de usuário do admin (ex: admin)
- `ADMIN_PASSWORD`: Senha do admin (ex: admin123)
- `ADMIN_EMAIL`: Email do admin (ex: admin@example.com)

### Para JWT:
- `JWT_SECRET_KEY`: Chave secreta para assinar tokens JWT (ex: sua-chave-secreta-muito-segura)

## Como configurar

### Opção 1: Arquivo .env (recomendado para desenvolvimento)
Crie um arquivo `.env` na raiz do projeto com o seguinte conteúdo:

```
ADMIN_NAME=admin
ADMIN_PASSWORD=admin123
ADMIN_EMAIL=admin@example.com
JWT_SECRET_KEY=sua-chave-secreta-muito-segura
```

### Opção 2: Variáveis de ambiente do sistema
Configure as variáveis de ambiente no seu sistema:

```bash
export ADMIN_NAME=admin
export ADMIN_PASSWORD=admin123
export ADMIN_EMAIL=admin@example.com
export JWT_SECRET_KEY=sua-chave-secreta-muito-segura
```

### Opção 3: Para produção/Docker
Configure as variáveis de ambiente no seu ambiente de produção ou no Docker.

## Executar o seed

Após configurar as variáveis de ambiente, execute:

```bash
rails db:seed
```

Isso criará o usuário admin inicial com as credenciais especificadas.

## Segurança

- Use senhas fortes em produção
- Use uma chave JWT segura e única em produção
- Não commite o arquivo `.env` no repositório
- Considere usar um gerenciador de segredos em produção
- Tokens JWT expiram em 24 horas por padrão 