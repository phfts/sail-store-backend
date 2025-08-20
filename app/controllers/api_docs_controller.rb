class ApiDocsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :html]
  
  def index
    render json: api_documentation
  end
  
  def html
    render html: html_documentation.html_safe
  end
  
  private
  
  def api_documentation
    {
      api_info: {
        name: "Sail Store Performance API",
        version: "1.0.0",
        description: "API REST para sistema de gestão de vendas e performance de lojas",
        base_url: "https://sail-store-backend-3018fcb425c5.herokuapp.com",
        documentation_url: "https://sail-store-backend-3018fcb425c5.herokuapp.com/api/docs",
        contact: {
          email: "suporte@sail.com.br"
        }
      },
      authentication: {
        type: "Bearer Token",
        description: "A maioria dos endpoints requer autenticação via token Bearer",
        header: "Authorization: Bearer YOUR_TOKEN",
        endpoints: [
          {
            method: "POST",
            path: "/auth/login",
            description: "Realizar login no sistema",
            request_body: {
              email: "user@example.com",
              password: "password123"
            },
            response: {
              token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
              user: {
                id: 1,
                email: "user@example.com",
                admin: false,
                store_slug: "loja-exemplo"
              }
            }
          },
          {
            method: "POST",
            path: "/auth/register",
            description: "Registrar novo usuário",
            request_body: {
              user: {
                email: "new@example.com",
                password: "password123",
                password_confirmation: "password123"
              }
            },
            response: {
              token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
              user: {
                id: 2,
                email: "new@example.com",
                admin: false
              }
            }
          },
          {
            method: "POST",
            path: "/auth/logout",
            description: "Realizar logout do sistema",
            auth_required: true,
            response: {
              message: "Logout realizado com sucesso"
            }
          },
          {
            method: "GET",
            path: "/auth/me",
            description: "Verificar token e obter dados do usuário atual",
            auth_required: true,
            response: {
              user: {
                id: 1,
                email: "user@example.com",
                admin: false,
                store_slug: "loja-exemplo"
              }
            }
          }
        ]
      },
      endpoints: {
        users: {
          description: "Gerenciamento de usuários do sistema",
          base_path: "/users",
          endpoints: [
            {
              method: "GET",
              path: "/users",
              description: "Listar todos os usuários",
              auth_required: true,
              response: {
                users: [
                  {
                    id: 1,
                    email: "user@example.com",
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/users",
              description: "Criar novo usuário",
              auth_required: true,
              request_body: {
                user: {
                  email: "newuser@example.com",
                  password: "password123",
                  password_confirmation: "password123"
                }
              },
              response: {
                user: {
                  id: 3,
                  email: "newuser@example.com",
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "PUT",
              path: "/users/:id",
              description: "Atualizar usuário existente",
              auth_required: true,
              request_body: {
                user: {
                  email: "updated@example.com"
                }
              },
              response: {
                user: {
                  id: 1,
                  email: "updated@example.com",
                  updated_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "DELETE",
              path: "/users/:id",
              description: "Deletar usuário",
              auth_required: true,
              response: {
                message: "Usuário deletado com sucesso"
              }
            }
          ]
        },
        companies: {
          description: "Gerenciamento de empresas",
          base_path: "/companies",
          endpoints: [
            {
              method: "GET",
              path: "/companies",
              description: "Listar todas as empresas",
              auth_required: true,
              response: {
                companies: [
                  {
                    id: 1,
                    name: "Empresa Exemplo",
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/companies",
              description: "Criar nova empresa",
              auth_required: true,
              request_body: {
                company: {
                  name: "Nova Empresa"
                }
              },
              response: {
                company: {
                  id: 2,
                  name: "Nova Empresa",
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            }
          ]
        },
        stores: {
          description: "Gerenciamento de lojas",
          base_path: "/stores",
          endpoints: [
            {
              method: "GET",
              path: "/stores",
              description: "Listar todas as lojas",
              auth_required: true,
              response: {
                stores: [
                  {
                    id: 1,
                    name: "Loja Centro",
                    slug: "loja-centro",
                    company_id: 1,
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores",
              description: "Criar nova loja",
              auth_required: true,
              request_body: {
                store: {
                  name: "Nova Loja",
                  company_id: 1
                }
              },
              response: {
                store: {
                  id: 2,
                  name: "Nova Loja",
                  slug: "nova-loja",
                  company_id: 1,
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "GET",
              path: "/stores/:slug",
              description: "Obter dados de uma loja específica",
              auth_required: true,
              response: {
                store: {
                  id: 1,
                  name: "Loja Centro",
                  slug: "loja-centro",
                  company_id: 1,
                  sellers: [],
                  targets: [],
                  created_at: "2024-01-01T00:00:00Z"
                }
              }
            }
          ]
        },
        sellers: {
          description: "Gerenciamento de vendedores por loja",
          base_path: "/stores/:slug/sellers",
          endpoints: [
            {
              method: "GET",
              path: "/stores/:slug/sellers",
              description: "Listar vendedores de uma loja",
              auth_required: true,
              response: {
                sellers: [
                  {
                    id: 1,
                    name: "João Silva",
                    email: "joao@example.com",
                    store_id: 1,
                    active: true,
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores/:slug/sellers",
              description: "Criar novo vendedor",
              auth_required: true,
              request_body: {
                seller: {
                  name: "Maria Santos",
                  email: "maria@example.com"
                }
              },
              response: {
                seller: {
                  id: 2,
                  name: "Maria Santos",
                  email: "maria@example.com",
                  store_id: 1,
                  active: true,
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "PUT",
              path: "/stores/:slug/sellers/:id",
              description: "Atualizar vendedor",
              auth_required: true,
              request_body: {
                seller: {
                  name: "João Silva Atualizado",
                  email: "joao.novo@example.com"
                }
              },
              response: {
                seller: {
                  id: 1,
                  name: "João Silva Atualizado",
                  email: "joao.novo@example.com",
                  store_id: 1,
                  active: true,
                  updated_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "DELETE",
              path: "/stores/:slug/sellers/:id",
              description: "Deletar vendedor",
              auth_required: true,
              response: {
                message: "Vendedor deletado com sucesso"
              }
            }
          ]
        },
        targets: {
          description: "Gerenciamento de metas de vendas por loja",
          base_path: "/stores/:slug/targets",
          endpoints: [
            {
              method: "GET",
              path: "/stores/:slug/targets",
              description: "Listar metas de uma loja",
              auth_required: true,
              response: {
                targets: [
                  {
                    id: 1,
                    store_id: 1,
                    month: "2024-01",
                    target_amount: 50000.00,
                    current_amount: 35000.00,
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores/:slug/targets",
              description: "Criar nova meta",
              auth_required: true,
              request_body: {
                target: {
                  month: "2024-02",
                  target_amount: 60000.00
                }
              },
              response: {
                target: {
                  id: 2,
                  store_id: 1,
                  month: "2024-02",
                  target_amount: 60000.00,
                  current_amount: 0.00,
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "PUT",
              path: "/stores/:slug/targets/:id",
              description: "Atualizar meta",
              auth_required: true,
              request_body: {
                target: {
                  target_amount: 70000.00
                }
              },
              response: {
                target: {
                  id: 1,
                  store_id: 1,
                  month: "2024-01",
                  target_amount: 70000.00,
                  current_amount: 35000.00,
                  updated_at: "2024-01-03T00:00:00Z"
                }
              }
            }
          ]
        },
        schedules: {
          description: "Gerenciamento de escalas de trabalho",
          base_path: "/stores/:slug/schedules",
          endpoints: [
            {
              method: "GET",
              path: "/stores/:slug/schedules",
              description: "Listar escalas de uma loja",
              auth_required: true,
              response: {
                schedules: [
                  {
                    id: 1,
                    seller_id: 1,
                    store_id: 1,
                    date: "2024-01-15",
                    start_time: "08:00",
                    end_time: "17:00",
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores/:slug/schedules",
              description: "Criar nova escala",
              auth_required: true,
              request_body: {
                schedule: {
                  seller_id: 1,
                  date: "2024-01-16",
                  start_time: "09:00",
                  end_time: "18:00"
                }
              },
              response: {
                schedule: {
                  id: 2,
                  seller_id: 1,
                  store_id: 1,
                  date: "2024-01-16",
                  start_time: "09:00",
                  end_time: "18:00",
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            }
          ]
        },
        orders: {
          description: "Gerenciamento de pedidos",
          base_path: "/stores/:slug/orders",
          endpoints: [
            {
              method: "GET",
              path: "/stores/:slug/orders",
              description: "Listar pedidos de uma loja",
              auth_required: true,
              response: {
                orders: [
                  {
                    id: 1,
                    store_id: 1,
                    seller_id: 1,
                    total_amount: 1500.00,
                    sold_at: "2024-01-15",
                    created_at: "2024-01-15T10:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores/:slug/orders",
              description: "Criar novo pedido",
              auth_required: true,
              request_body: {
                order: {
                  seller_id: 1,
                  total_amount: 2000.00,
                  sold_at: "2024-01-16"
                }
              },
              response: {
                order: {
                  id: 2,
                  store_id: 1,
                  seller_id: 1,
                  total_amount: 2000.00,
                  sold_at: "2024-01-16",
                  created_at: "2024-01-16T10:00:00Z"
                }
              }
            }
          ]
        },
        categories: {
          description: "Gerenciamento de categorias de produtos",
          base_path: "/stores/:slug/categories",
          endpoints: [
            {
              method: "GET",
              path: "/stores/:slug/categories",
              description: "Listar categorias de uma loja",
              auth_required: true,
              response: {
                categories: [
                  {
                    id: 1,
                    name: "Eletrônicos",
                    store_id: 1,
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/stores/:slug/categories",
              description: "Criar nova categoria",
              auth_required: true,
              request_body: {
                category: {
                  name: "Roupas"
                }
              },
              response: {
                category: {
                  id: 2,
                  name: "Roupas",
                  store_id: 1,
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            }
          ]
        },
        products: {
          description: "Gerenciamento de produtos",
          base_path: "/products",
          endpoints: [
            {
              method: "GET",
              path: "/products",
              description: "Listar todos os produtos",
              auth_required: true,
              response: {
                products: [
                  {
                    id: 1,
                    name: "BLUSA BORDALLO",
                    external_id: "224217",
                    sku: "224217",
                    category_id: 8,
                    category: {
                      id: 8,
                      external_id: "CAT001",
                      name: "Roupas"
                    },
                    created_at: "2024-01-01T00:00:00Z"
                  }
                ]
              }
            },
            {
              method: "POST",
              path: "/products",
              description: "Criar novo produto",
              auth_required: true,
              request_body: {
                product: {
                  name: "BLUSA BORDALLO",
                  external_id: "224217",
                  sku: "224217",
                  category_id: 8
                }
              },
              response: {
                product: {
                  id: 2,
                  name: "BLUSA BORDALLO",
                  external_id: "224217",
                  sku: "224217",
                  category_id: 8,
                  category: {
                    id: 8,
                    external_id: "CAT001",
                    name: "Roupas"
                  },
                  created_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "GET",
              path: "/products/:id",
              description: "Obter produto específico",
              auth_required: true,
              response: {
                product: {
                  id: 1,
                  name: "BLUSA BORDALLO",
                  external_id: "224217",
                  sku: "224217",
                  category_id: 8,
                  category: {
                    id: 8,
                    external_id: "CAT001",
                    name: "Roupas"
                  },
                  created_at: "2024-01-01T00:00:00Z"
                }
              }
            },
            {
              method: "PUT",
              path: "/products/:id",
              description: "Atualizar produto",
              auth_required: true,
              request_body: {
                product: {
                  name: "BLUSA BORDALLO ATUALIZADA",
                  external_id: "224217",
                  sku: "224217",
                  category_id: 8
                }
              },
              response: {
                product: {
                  id: 1,
                  name: "BLUSA BORDALLO ATUALIZADA",
                  external_id: "224217",
                  sku: "224217",
                  category_id: 8,
                  category: {
                    id: 8,
                    external_id: "CAT001",
                    name: "Roupas"
                  },
                  updated_at: "2024-01-03T00:00:00Z"
                }
              }
            },
            {
              method: "DELETE",
              path: "/products/:id",
              description: "Excluir produto",
              auth_required: true,
              response: {
                message: "Produto excluído com sucesso"
              }
            }
          ]
        },
        metrics: {
          description: "Métricas e relatórios do sistema",
          base_path: "/metrics",
          endpoints: [
            {
              method: "GET",
              path: "/metrics",
              description: "Obter métricas gerais do sistema",
              auth_required: true,
              response: {
                total_stores: 10,
                total_users: 50,
                monthly_active_users: 35,
                weekly_active_users: 25,
                daily_active_users: 15
              }
            },
            {
              method: "GET",
              path: "/stores/:slug/dashboard",
              description: "Obter métricas de uma loja específica",
              auth_required: true,
              response: {
                store_metrics: {
                  total_sellers: 5,
                  total_orders: 150,
                  total_sales: 75000.00,
                  current_month_target: 50000.00,
                  current_month_sales: 35000.00
                }
              }
            }
          ]
        }
      },
      status_codes: {
        "200": "Sucesso",
        "201": "Criado com sucesso",
        "400": "Erro de validação",
        "401": "Não autorizado",
        "403": "Acesso negado",
        "404": "Não encontrado",
        "422": "Erro de validação",
        "500": "Erro interno do servidor"
      },
      data_formats: {
        date_format: "YYYY-MM-DDTHH:mm:ssZ (ISO 8601)",
        currency_format: "Decimal com 2 casas (ex: 1500.00)",
        pagination: {
          page: "Número da página (padrão: 1)",
          per_page: "Itens por página (padrão: 20, máximo: 100)"
        }
      },
            examples: {
        curl_example: "curl -X GET https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers \\\n  -H 'Authorization: Bearer YOUR_TOKEN'",
        javascript_example: "fetch('https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers', {\n  headers: {\n    'Authorization': 'Bearer YOUR_TOKEN'\n  }\n})",
        python_example: "import requests\n\nresponse = requests.get(\n  'https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers',\n  headers={'Authorization': 'Bearer YOUR_TOKEN'}\n)"
      }
     }
   end
   
   def html_documentation
     <<~HTML
       <!DOCTYPE html>
       <html lang="pt-BR">
       <head>
           <meta charset="UTF-8">
           <meta name="viewport" content="width=device-width, initial-scale=1.0">
           <title>Documentação da API - Sail Store Performance</title>
           <style>
               * { margin: 0; padding: 0; box-sizing: border-box; }
               body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #f5f5f5; }
               .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
               .header { background: #fff; padding: 30px; border-radius: 8px; margin-bottom: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
               .header h1 { color: #2563eb; margin-bottom: 10px; }
               .header p { color: #666; font-size: 18px; }
               .section { background: #fff; padding: 30px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
               .section h2 { color: #2563eb; margin-bottom: 20px; border-bottom: 2px solid #e5e7eb; padding-bottom: 10px; }
               .endpoint { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 20px; margin-bottom: 15px; }
               .endpoint-header { display: flex; align-items: center; gap: 15px; margin-bottom: 15px; }
               .method { padding: 4px 12px; border-radius: 4px; font-weight: bold; font-size: 14px; }
               .method.get { background: #dcfce7; color: #166534; }
               .method.post { background: #dbeafe; color: #1e40af; }
               .method.put { background: #fef3c7; color: #92400e; }
               .method.delete { background: #fee2e2; color: #991b1b; }
               .path { font-family: monospace; background: #e5e7eb; padding: 8px 12px; border-radius: 4px; font-size: 14px; }
               .auth-badge { background: #fef3c7; color: #92400e; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
               .admin-badge { background: #fee2e2; color: #991b1b; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
               .description { color: #666; margin-bottom: 15px; }
               .code-block { background: #1f2937; color: #f9fafb; padding: 15px; border-radius: 6px; font-family: monospace; font-size: 14px; overflow-x: auto; margin: 10px 0; }
               .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; }
               .info-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 20px; }
               .info-card h3 { color: #2563eb; margin-bottom: 10px; }
               .status-code { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; margin-right: 10px; }
               .status-200 { background: #dcfce7; color: #166534; }
               .status-201 { background: #dcfce7; color: #166534; }
               .status-400 { background: #fef3c7; color: #92400e; }
               .status-401 { background: #fee2e2; color: #991b1b; }
               .status-403 { background: #fee2e2; color: #991b1b; }
               .status-404 { background: #fee2e2; color: #991b1b; }
               .status-422 { background: #fef3c7; color: #92400e; }
               .status-500 { background: #fee2e2; color: #991b1b; }
               .sidebar { position: fixed; top: 20px; left: 20px; width: 250px; background: #fff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); padding: 20px; max-height: calc(100vh - 40px); overflow-y: auto; }
               .sidebar h3 { color: #2563eb; margin-bottom: 15px; }
               .sidebar ul { list-style: none; }
               .sidebar li { margin-bottom: 8px; }
               .sidebar a { color: #666; text-decoration: none; padding: 5px 0; display: block; }
               .sidebar a:hover { color: #2563eb; }
               .main-content { margin-left: 290px; }
               @media (max-width: 768px) { .sidebar { display: none; } .main-content { margin-left: 0; } }
           </style>
       </head>
       <body>
           <div class="sidebar">
               <h3>Navegação</h3>
               <ul>
                   <li><a href="#info">Informações Gerais</a></li>
                   <li><a href="#auth">Autenticação</a></li>
                   <li><a href="#users">Usuários</a></li>
                   <li><a href="#companies">Empresas</a></li>
                   <li><a href="#stores">Lojas</a></li>
                   <li><a href="#sellers">Vendedores</a></li>
                   <li><a href="#targets">Metas</a></li>
                   <li><a href="#schedules">Escalas</a></li>
                   <li><a href="#orders">Pedidos</a></li>
                   <li><a href="#categories">Categorias</a></li>
                   <li><a href="#products">Produtos</a></li>
                   <li><a href="#metrics">Métricas</a></li>
                   <li><a href="#status-codes">Códigos de Status</a></li>
               </ul>
           </div>
           
           <div class="main-content">
               <div class="container">
                   <div class="header">
                       <h1>🚢 Sail Store Performance API</h1>
                       <p>Documentação completa da API REST para sistema de gestão de vendas e performance de lojas</p>
                       <p><strong>Versão:</strong> 1.0.0 | <strong>Base URL:</strong> #{request.base_url}</p>
                   </div>
                   
                   <div id="info" class="section">
                       <h2>📋 Informações Gerais</h2>
                       <p>A Sail Store Performance API é uma API REST completa para gerenciamento de vendas, vendedores, metas e performance de lojas.</p>
                       
                       <div class="info-grid">
                           <div class="info-card">
                               <h3>🔐 Autenticação</h3>
                               <p>A maioria dos endpoints requer autenticação via token Bearer. Inclua o header:</p>
                               <div class="code-block">Authorization: Bearer YOUR_TOKEN</div>
                           </div>
                           
                           <div class="info-card">
                               <h3>📅 Formato de Data</h3>
                               <p>Todas as datas são retornadas no formato ISO 8601:</p>
                               <div class="code-block">YYYY-MM-DDTHH:mm:ssZ</div>
                           </div>
                           
                           <div class="info-card">
                               <h3>💰 Formato de Moeda</h3>
                               <p>Valores monetários são retornados como decimal com 2 casas:</p>
                               <div class="code-block">1500.00</div>
                           </div>
                       </div>
                   </div>
                   
                   <div id="auth" class="section">
                       <h2>🔐 Autenticação</h2>
                       <p>Endpoints para autenticação e gerenciamento de sessões</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/auth/login</span>
                           </div>
                           <div class="description">Realizar login no sistema</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "email": "user@example.com",
  "password": "password123"
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "admin": false,
    "store_slug": "loja-exemplo"
  }
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/auth/register</span>
                           </div>
                           <div class="description">Registrar novo usuário</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "user": {
    "email": "new@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "user": {
    "id": 2,
    "email": "new@example.com",
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/auth/logout</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Realizar logout do sistema</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "message": "Logout realizado com sucesso"
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/auth/me</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Verificar token e obter dados do usuário atual</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "store_slug": "loja-exemplo",
    "created_at": "2024-01-01T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="users" class="section">
                       <h2>👥 Usuários</h2>
                       <p>Gerenciamento de usuários do sistema</p>
                       
                                                <div class="endpoint">
                             <div class="endpoint-header">
                                 <span class="method get">GET</span>
                                 <span class="path">/users</span>
                                 <span class="auth-badge">Auth</span>
                             </div>
                             <div class="description">Listar todos os usuários</div>
                             <h4>Response:</h4>
                             <div class="code-block">{
  "users": [
    {
      "id": 1,
      "email": "user@example.com",
      "store_slug": "loja-exemplo",
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "email": "admin@example.com",
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                         </div>
                         
                         <div class="endpoint">
                             <div class="endpoint-header">
                                 <span class="method post">POST</span>
                                 <span class="path">/users</span>
                                 <span class="auth-badge">Auth</span>
                             </div>
                             <div class="description">Criar novo usuário</div>
                             <h4>Request Body:</h4>
                             <div class="code-block">{
  "user": {
    "email": "newuser@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}</div>
                             <h4>Response:</h4>
                             <div class="code-block">{
  "user": {
    "id": 3,
    "email": "newuser@example.com",
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                         </div>
                   </div>
                   
                   <div id="stores" class="section">
                       <h2>🏪 Lojas</h2>
                       <p>Gerenciamento de lojas do sistema</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar todas as lojas</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "stores": [
    {
      "id": 1,
      "name": "Loja Centro",
      "slug": "loja-centro",
      "company_id": 1,
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "name": "Loja Norte",
      "slug": "loja-norte",
      "company_id": 1,
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Obter dados de uma loja específica</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "store": {
    "id": 1,
    "name": "Loja Centro",
    "slug": "loja-centro",
    "company_id": 1,
    "sellers": [
      {
        "id": 1,
        "name": "João Silva",
        "email": "joao@example.com"
      }
    ],
    "targets": [
      {
        "id": 1,
        "month": "2024-01",
        "target_amount": 50000.00
      }
    ],
    "created_at": "2024-01-01T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="sellers" class="section">
                       <h2>👨‍💼 Vendedores</h2>
                       <p>Gerenciamento de vendedores por loja</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/sellers</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar vendedores de uma loja</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "sellers": [
    {
      "id": 1,
      "name": "João Silva",
      "email": "joao@example.com",
      "store_id": 1,
      "active": true,
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "name": "Maria Santos",
      "email": "maria@example.com",
      "store_id": 1,
      "active": true,
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/stores/:slug/sellers</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar novo vendedor</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "seller": {
    "name": "Pedro Costa",
    "email": "pedro@example.com"
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "seller": {
    "id": 3,
    "name": "Pedro Costa",
    "email": "pedro@example.com",
    "store_id": 1,
    "active": true,
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="targets" class="section">
                       <h2>🎯 Metas</h2>
                       <p>Gerenciamento de metas de vendas por loja</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/targets</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar metas de uma loja</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "targets": [
    {
      "id": 1,
      "store_id": 1,
      "month": "2024-01",
      "target_amount": 50000.00,
      "current_amount": 35000.00,
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "store_id": 1,
      "month": "2024-02",
      "target_amount": 60000.00,
      "current_amount": 0.00,
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/stores/:slug/targets</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar nova meta</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "target": {
    "month": "2024-03",
    "target_amount": 70000.00
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "target": {
    "id": 3,
    "store_id": 1,
    "month": "2024-03",
    "target_amount": 70000.00,
    "current_amount": 0.00,
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="schedules" class="section">
                       <h2>📅 Escalas</h2>
                       <p>Gerenciamento de escalas de trabalho</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/schedules</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar escalas de uma loja</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "schedules": [
    {
      "id": 1,
      "seller_id": 1,
      "store_id": 1,
      "date": "2024-01-15",
      "start_time": "08:00",
      "end_time": "17:00",
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "seller_id": 2,
      "store_id": 1,
      "date": "2024-01-16",
      "start_time": "09:00",
      "end_time": "18:00",
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/stores/:slug/schedules</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar nova escala</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "schedule": {
    "seller_id": 1,
    "date": "2024-01-17",
    "start_time": "10:00",
    "end_time": "19:00"
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "schedule": {
    "id": 3,
    "seller_id": 1,
    "store_id": 1,
    "date": "2024-01-17",
    "start_time": "10:00",
    "end_time": "19:00",
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="orders" class="section">
                       <h2>🛒 Pedidos</h2>
                       <p>Gerenciamento de pedidos</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/orders</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar pedidos de uma loja</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "orders": [
    {
      "id": 1,
      "store_id": 1,
      "seller_id": 1,
      "total_amount": 1500.00,
      "sold_at": "2024-01-15",
      "created_at": "2024-01-15T10:00:00Z"
    },
    {
      "id": 2,
      "store_id": 1,
      "seller_id": 2,
      "total_amount": 2300.00,
      "sold_at": "2024-01-16",
      "created_at": "2024-01-16T14:30:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/stores/:slug/orders</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar novo pedido</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "order": {
    "seller_id": 1,
    "total_amount": 2800.00,
    "sold_at": "2024-01-17"
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "order": {
    "id": 3,
    "store_id": 1,
    "seller_id": 1,
    "total_amount": 2800.00,
    "sold_at": "2024-01-17",
    "created_at": "2024-01-17T11:45:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="categories" class="section">
                       <h2>📂 Categorias</h2>
                       <p>Gerenciamento de categorias de produtos</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/categories</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar categorias de uma loja</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "categories": [
    {
      "id": 1,
      "name": "Eletrônicos",
      "store_id": 1,
      "created_at": "2024-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "name": "Roupas",
      "store_id": 1,
      "created_at": "2024-01-02T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/stores/:slug/categories</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar nova categoria</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "category": {
    "name": "Acessórios"
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "category": {
    "id": 3,
    "name": "Acessórios",
    "store_id": 1,
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="products" class="section">
                       <h2>📦 Produtos</h2>
                       <p>Gerenciamento de produtos</p>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/products</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Listar todos os produtos</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "products": [
    {
      "id": 1,
      "name": "BLUSA BORDALLO",
      "external_id": "224217",
      "sku": "224217",
      "category_id": 8,
      "category": {
        "id": 8,
        "external_id": "CAT001",
        "name": "Roupas"
      },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method post">POST</span>
                               <span class="path">/products</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Criar novo produto</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "product": {
    "name": "BLUSA BORDALLO",
    "external_id": "224217",
    "sku": "224217",
    "category_id": 8
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "product": {
    "id": 2,
    "name": "BLUSA BORDALLO",
    "external_id": "224217",
    "sku": "224217",
    "category_id": 8,
    "category": {
      "id": 8,
      "external_id": "CAT001",
      "name": "Roupas"
    },
    "created_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/products/:id</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Obter produto específico</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "product": {
    "id": 1,
    "name": "BLUSA BORDALLO",
    "external_id": "224217",
    "sku": "224217",
    "category_id": 8,
    "category": {
      "id": 8,
      "external_id": "CAT001",
      "name": "Roupas"
    },
    "created_at": "2024-01-01T00:00:00Z"
  }
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method put">PUT</span>
                               <span class="path">/products/:id</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Atualizar produto</div>
                           <h4>Request Body:</h4>
                           <div class="code-block">{
  "product": {
    "name": "BLUSA BORDALLO ATUALIZADA",
    "external_id": "224217",
    "sku": "224217",
    "category_id": 8
  }
}</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "product": {
    "id": 1,
    "name": "BLUSA BORDALLO ATUALIZADA",
    "external_id": "224217",
    "sku": "224217",
    "category_id": 8,
    "category": {
      "id": 8,
      "external_id": "CAT001",
      "name": "Roupas"
    },
    "updated_at": "2024-01-03T00:00:00Z"
  }
}</div>
                       </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method delete">DELETE</span>
                               <span class="path">/products/:id</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Excluir produto</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "message": "Produto excluído com sucesso"
}</div>
                       </div>
                   </div>
                   
                   <div id="metrics" class="section">
                       <h2>📊 Métricas</h2>
                       <p>Métricas e relatórios do sistema</p>
                       
                                                <div class="endpoint">
                             <div class="endpoint-header">
                                 <span class="method get">GET</span>
                                 <span class="path">/metrics</span>
                                 <span class="auth-badge">Auth</span>
                             </div>
                             <div class="description">Obter métricas gerais do sistema</div>
                             <h4>Response:</h4>
                             <div class="code-block">{
  "metrics": {
    "total_stores": 5,
    "total_users": 25,
    "total_orders": 150,
    "total_revenue": 75000.00,
    "mau": 20,
    "wau": 15,
    "dau": 8
  }
}</div>
                         </div>
                       
                       <div class="endpoint">
                           <div class="endpoint-header">
                               <span class="method get">GET</span>
                               <span class="path">/stores/:slug/dashboard</span>
                               <span class="auth-badge">Auth</span>
                           </div>
                           <div class="description">Obter métricas de uma loja específica</div>
                           <h4>Response:</h4>
                           <div class="code-block">{
  "dashboard": {
    "store": {
      "id": 1,
      "name": "Loja Centro",
      "slug": "loja-centro"
    },
    "current_goal": {
      "month": "2024-01",
      "target_amount": 50000.00,
      "current_amount": 35000.00,
      "percentage": 70.0
    },
    "sales_made": 15000.00,
    "active_sellers": 3,
    "next_schedule": {
      "date": "2024-01-18",
      "seller": "João Silva",
      "start_time": "08:00",
      "end_time": "17:00"
    }
  }
}</div>
                       </div>
                   </div>
                   
                   <div id="status-codes" class="section">
                       <h2>📋 Códigos de Status HTTP</h2>
                       <div class="info-grid">
                           <div class="info-card">
                               <h3>Sucesso</h3>
                               <p><span class="status-code status-200">200</span> Sucesso</p>
                               <p><span class="status-code status-201">201</span> Criado com sucesso</p>
                           </div>
                           
                           <div class="info-card">
                               <h3>Erro do Cliente</h3>
                               <p><span class="status-code status-400">400</span> Erro de validação</p>
                               <p><span class="status-code status-401">401</span> Não autorizado</p>
                               <p><span class="status-code status-403">403</span> Acesso negado</p>
                               <p><span class="status-code status-404">404</span> Não encontrado</p>
                               <p><span class="status-code status-422">422</span> Erro de validação</p>
                           </div>
                           
                           <div class="info-card">
                               <h3>Erro do Servidor</h3>
                               <p><span class="status-code status-500">500</span> Erro interno do servidor</p>
                           </div>
                       </div>
                   </div>
                   
                   <div class="section">
                       <h2>💡 Exemplos de Uso</h2>
                       <div class="info-grid">
                           <div class="info-card">
                               <h3>cURL</h3>
                               <div class="code-block">curl -X GET https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers \\
  -H 'Authorization: Bearer YOUR_TOKEN'</div>
                           </div>
                           
                           <div class="info-card">
                               <h3>JavaScript</h3>
                               <div class="code-block">fetch('https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers', {
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN'
  }
})</div>
                           </div>
                           
                           <div class="info-card">
                               <h3>Python</h3>
                               <div class="code-block">import requests

response = requests.get(
  'https://sail-store-backend-3018fcb425c5.herokuapp.com/stores/loja-centro/sellers',
  headers={'Authorization': 'Bearer YOUR_TOKEN'}
)</div>
                           </div>
                       </div>
                   </div>
               </div>
           </div>
       </body>
       </html>
     HTML
   end
end
