# Configuração do Google Drive para Importação de Dados SOUQ

## 📋 Pré-requisitos

1. **Conta Google Cloud Platform**
2. **Projeto no Google Cloud Console**
3. **Arquivos CSV da SOUQ no Google Drive**

## 🔧 Configuração Passo a Passo

### 1. Criar Service Account no Google Cloud

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione seu projeto ou crie um novo
3. Vá para **IAM & Admin > Service Accounts**
4. Clique em **Create Service Account**
5. Preencha:
   - **Service account name**: `souq-data-importer`
   - **Description**: `Service account para importar dados SOUQ do Google Drive`
6. Clique em **Create and Continue**
7. Em **Grant this service account access to project**, adicione as roles:
   - `Viewer` (para acessar o projeto)
8. Clique em **Continue** e depois **Done**

### 2. Gerar Chave do Service Account

1. Na lista de Service Accounts, clique no service account criado
2. Vá para a aba **Keys**
3. Clique em **Add Key > Create new key**
4. Selecione **JSON** e clique em **Create**
5. O arquivo JSON será baixado automaticamente
6. **GUARDE ESTE ARQUIVO COM SEGURANÇA!**

### 3. Habilitar APIs Necessárias

1. No Google Cloud Console, vá para **APIs & Services > Library**
2. Procure e habilite as seguintes APIs:
   - **Google Drive API**
   - **Google Sheets API** (se necessário)

### 4. Compartilhar Pasta do Google Drive

1. Abra o Google Drive
2. Localize a pasta com os arquivos CSV da SOUQ
3. Clique com o botão direito na pasta > **Share**
4. Adicione o email do service account (encontrado no arquivo JSON baixado)
5. Dê permissão de **Viewer** ou **Editor**
6. Copie o **ID da pasta** da URL (parte após `/folders/`)

### 5. Configurar Variáveis de Ambiente

#### Para Desenvolvimento Local (.env)
```bash
# ID da pasta do Google Drive
SOUQ_GOOGLE_DRIVE_FOLDER_ID=1234567890abcdefghijklmnop

# Conteúdo completo do arquivo JSON do service account (em uma linha)
GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"seu-projeto",...}
```

#### Para Heroku
```bash
# Configurar via Heroku CLI
heroku config:set SOUQ_GOOGLE_DRIVE_FOLDER_ID=1234567890abcdefghijklmnop
heroku config:set GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"seu-projeto",...}'
```

## 🚀 Executando a Importação

### Localmente
```bash
# Carregar todos os dados
rails souq:load_all

# Ou carregar individualmente
rails souq:create_company
rails souq:create_store
rails souq:create_category
rails souq:load_sellers
rails souq:load_products
rails souq:load_orders
rails souq:load_exchanges
rails souq:load_returns
```

### No Heroku
```bash
# Executar via Heroku CLI
heroku run rails souq:load_all

# Ou conectar ao console do Heroku
heroku run rails console
```

## 📁 Estrutura Esperada dos Arquivos

Os arquivos CSV devem estar na pasta compartilhada com os seguintes nomes:

- `LinxVendedores_store=16945787001508_historical.csv`
- `LinxProdutos_store=16945787001508_beginDate=YYYY-MM-DD_endDate=YYYY-MM-DD.csv`
- `LinxMovimento_store=16945787001508_beginDate=YYYY-MM-DD_endDate=YYYY-MM-DD.csv`
- `LinxMovimentoTrocas_store=16945787001508_beginDate=YYYY-MM-DD_endDate=YYYY-MM-DD.csv`
- `LinxMovimentoDevolucoesItens_store=16945787001508_historical.csv`

## 🔍 Troubleshooting

### Erro de Autenticação
- Verifique se o service account tem acesso à pasta
- Confirme se as APIs estão habilitadas
- Verifique se o JSON das credenciais está correto

### Arquivo Não Encontrado
- Confirme se os nomes dos arquivos estão corretos
- Verifique se os arquivos estão na pasta compartilhada
- Para arquivos com datas, o sistema busca automaticamente o mais recente

### Problemas de Memória no Heroku
- Os arquivos são baixados temporariamente
- Arquivos são removidos após o processamento
- Use dynos com mais memória se necessário

## 🔒 Segurança

- **NUNCA** commite o arquivo JSON do service account
- Use variáveis de ambiente para as credenciais
- Revogue o acesso do service account quando não precisar mais
- Monitore os logs de acesso no Google Cloud Console

