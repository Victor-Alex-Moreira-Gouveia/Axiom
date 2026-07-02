```mermaid
flowchart LR
    SSH --> Servidor[Tardis Core] --> db[(Banco de Dados PostgresSQL)]
    Servidor --> Script[Monitoramento Sistema]
    Servidor --> container[Docker]
    container --> NGINX
```