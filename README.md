# Tardis



**Descrição:** O projeto consiste em um servidor caseiro para hospedar minhas aplicações web FullStack, eliminando o custo mensal de serviços de Cloud para projetos de pequeno porte.

O hardware base utilizado é um **Raspberry Pi 4 Model B**, com 8 GB de RAM, CPU de 1,5 GHz e um cartão SD de 128 GB. Este servidor receberá o hostname de `tardis-core01`. Dessa forma, caso haja necessidade de expansão futura, bastará replicar a infraestrutura alterando a nomenclatura dos nós.

---

## Planos

### Acesso Direto

Inicialmente, para garantir a segurança, o acesso direto ao servidor será realizado exclusivamente através do protocolo **SSH**, utilizando chaves criptográficas (ou usuário e senha robustos bem definidos) e alterando a porta padrão do serviço.

### Acesso Indireto

Para o acesso externo às aplicações, utilizarei o **NGINX** atuando como Proxy Reverso e Load Balancer para gerenciar as requisições. O NGINX será executado dentro de um container (Docker ou Podman), isolando o ponto de entrada da rede.

### Conteinerização (Docker)

Os motivos que levaram à escolha do Docker foram:

* **Gestão de Projetos:** Facilidade para orquestrar, reiniciar ou atualizar todo o ecossistema de forma centralizada caso algo falhe.
* **Segurança:** Isolamento de vulnerabilidades dentro do container, impedindo que uma aplicação comprometida afete o sistema operacional hospedeiro ou outros projetos.

### Banco de Dados

Embora a decisão técnica de qual SGDB (PostgreSQL, MySQL/MariaDB, etc.) utilizar ainda não tenha sido tomada, ficou pré-definido que haverá uma **centralização do banco de dados**. Um único container robusto gerenciará as instâncias das aplicações internas por questões de eficiência de hardware e economia de recursos.

### Infraestrutura Backend

A stack base do backend para as futuras aplicações ainda está sendo avaliada, mas a maior parte do ecossistema gravitará em torno de **Python (Flask/FastAPI)** ou **PHP (Laravel)**.

---

## Configuração do Sistema

### Preparando o Ambiente

Abaixo estão as configurações iniciais obrigatórias para um Raspberry Pi com sistema operacional limpo (Raspberry Pi OS / Debian).

> **Nota:** Caso já tenha realizado a atualização de pacotes e a configuração de rede, você pode pular direto para a seção de **Monitoramento**.

**1. Atualizar os pacotes básicos do sistema:**

```bash
sudo apt update && sudo apt upgrade -y
```

**2. Alterar o Hostname do dispositivo:**
Para mudar o nome do servidor para `tardis-core01`:

```bash
sudo hostnamectl set-hostname tardis-core01
```

---

### Instalação do Docker e Docker Compose

Para suportar a arquitetura planejada (NGINX e Bancos de Dados), o Docker precisa ser instalado no ecossistema:

```bash
# Baixa e executa o script oficial de instalação do Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adiciona o seu usuário ao grupo docker para não precisar usar 'sudo' em todo comando
sudo usermod -aG docker $USER
```

*Certifique-se de deslogar e logar novamente no SSH para que a permissão do grupo surta efeito.*

---

### Monitoramento

> **OBS:** Para fins de estabilidade, recomenda-se o uso de ambientes virtuais Python (`venv`). Isso impede que pacotes de terceiros entrem em conflito com as dependências do sistema operacional do Raspberry Pi.

**Criação e ativação do ambiente virtual:**

```bash
# Garante que o pacote python3-full está instalado
sudo apt install python3-full -y

# Navega até o diretório do script de monitoramento
cd Axiom/monitoramento_server

# Cria e ativa o ambiente virtual
python3 -m venv venv
source venv/bin/activate

```

**Instalando as dependências do script:**

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Inicializando o serviço de monitoramento:**

```bash
python3 monitor.py
```

## Banco de Dados (PostgreSQL)

Para a centralização dos dados das aplicações, utilizamos o **PostgreSQL** rodando em um container Docker. A configuração está otimizada para o Raspberry Pi utilizando a imagem baseada em Alpine Linux, que é mais leve e consome menos memória RAM.

### Arquivo `docker-compose.yml`

```yaml
services:
  postgresql:
    image: postgres:alpine
    container_name: DB_Server
    restart: unless-stopped
    env_file:
      - .env
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_DATABASE}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./databases:/docker-entrypoint-initdb.d:ro

volumes:
  postgres_data:

```

### Gerenciamento de Volumes e Inicialização

* **`postgres_data`**: Volume persistente gerenciado pelo Docker para garantir que os dados não sejam perdidos quando o container for reiniciado ou atualizado.
* **`./databases`**: Pasta local mapeada como *Read-Only* (`ro`). Qualquer script `.sql` ou `.sh` colocado dentro dela será executado automaticamente assim que o banco de dados for iniciado pela primeira vez (útil para criar tabelas iniciais).

---

## Variáveis de Ambiente (`.env`)

O projeto utiliza um arquivo `.env` na raiz do diretório para isolar credenciais sensíveis. **Nunca envie o arquivo `.env` para o repositório.** Em vez disso, utilize o `.env.example` como referência.

### Estrutura do `.env.example`

```env
DB_USER=user_admin
DB_PASSWORD=password_secret
DB_DATABASE=tardis_db
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/SUA/URL/AQUI_MUDE_ISSO

```

### Dicionário de Variáveis

| Variável | Descrição | Exemplo |
| --- | --- | --- |
| `DB_USER` | Usuário administrador do banco de dados (Root do Postgres). | `user_admin` |
| `DB_PASSWORD` | Senha forte para o usuário administrador. | `uma_senha_muito_segura` |
| `DB_DATABASE` | Nome do banco de dados padrão criado na inicialização. | `tardis_db` |
| `SLACK_WEBHOOK_URL` | URL de integração do Slack para envio de alertas do servidor. | `https://hooks.slack.com/...` |

---

## Como Rodar o Banco de Dados

1. Certifique-se de que o arquivo `.env` foi criado e preenchido com suas credenciais.
2. Crie o diretório de inicialização de scripts (caso queira usar scripts SQL automáticos):
```bash
mkdir databases
```


3. Suba o serviço em segundo plano (modo daemon):
```bash
docker compose up -d
```


4. Para acompanhar os logs do banco de dados e verificar se tudo iniciou corretamente:
```bash
docker logs -f DB_Server
```