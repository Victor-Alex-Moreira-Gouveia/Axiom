# Tardis
---
**Descrição:** Um projeto de um servidor para hospedar minhas aplicações web FullStack sem ter que ficar pagando um valor mensal para clound em projetos pequenos

O servidor de base usado para construição desse projeto é um Rasberry Pi 4 Model B, contendo 8 RAM, 1,5GHz CPU, 128GB de memória de um cartão SD. Esse servidor ganhará o nome de `tardis-core01`, para que caso no futuro eu queira adicionar mais servidores bastava copiar a infra-estrutura modificando os nomes

---

## Planos

### Acesso direto
Inicialmente a ideia é que para que possa acessar o servidor de forma segura isso deverá ser realizado atravez do protocólo SSH com usuário, e senha bem definidos para acesso direto.

### Acesso indireto
Para acesso indireto para acesso a aplições em si, irei utilizar o NGINX que servirá com Proxy Reverso e Load Balance para gerir as requisições externas e internas. O mesmo será hospedado em um container seja ele docker ou podman

### Conteinerização com (Docker)
O motivo que me levou a decisção dessa escolha: 
- **Gestão Projetos:** Permitindo reiniciar todo o ecosistema caso algo falhe;
- **Segurança:** Isola vulnerabilidade de forma exclusiva ao container, impedindo que infecte as outras apliações, identificando e neutralizando as ameças trazendo mais segurança ao servidor e estabilidade em projetos.

### Banco de Dados

Embora a decisão tecnica na escolha de qual banco de dados será utilizado não tenha cido tomada até o presente momento, algumas coisas já foram pré-definidas e dentre elas é a centralização do banco de dados nas aplicações internas, por questão de eficiência e economia


### Infra-estrutura Backend

Ainda estou inserto a base do backend das aplicações futuras, mas a maioria não vai fugir da combinação de Python + Flask ou PHP + Laravel