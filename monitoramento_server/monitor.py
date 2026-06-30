import os
import time
import requests
import psutil
from dotenv import load_dotenv

# Carrega as variáveis do arquivo .env
load_dotenv()
SLACK_URL = os.getenv("SLACK_WEBHOOK_URL")

# CONFIGURAÇÕES DE LIMITES (Altere se quiser)
LIMITE_CPU = 90.0       # Alerta se passar de 90%
LIMITE_RAM = 85.0       # Alerta se passar de 85%
LIMITE_DISCO = 85.0     # Alerta se o armazenamento passar de 85%

# CONTADORES PARA EVITAR ALARMES FALSOS
# Só avisa se o problema persistir por X checagens consecutivas
CHECAGENS_PERSISTENCIA = 3  
contador_cpu_alta = 0
contador_ram_alta = 0

# CONTROLES DE TEMPO
INTERVALO_RAPIDO = 30  # Segundos (Checa CPU e RAM)
SEGUNDOS_PARA_DISCO = 3600  # 1 Hora (Tempo para checar o disco)
contador_tempo_disco = 0

def enviar_alerta_slack(mensagem):
    """Envia uma notificação formatada para o canal do Slack"""
    if not SLACK_URL or "AQUI_MUDE_ISSO" in SLACK_URL:
        print(f"[ERRO] Webhook do Slack não configurado. Mensagem: {mensagem}")
        return

    payload = {"text": f"🚨 *[ALERTA DO SERVIDOR]* 🚨\n{mensagem}"}
    
    try:
        resposta = requests.post(SLACK_URL, json=payload, timeout=10)
        if resposta.status_code == 200:
            print("[INFO] Alerta enviado com sucesso para o Slack.")
        else:
            print(f"[ERRO] Falha ao enviar para o Slack. Status: {resposta.status_code}")
    except Exception as e:
        print(f"[ERRO] Falha de rede ao conectar ao Slack: {e}")

def checar_recursos_criticos():
    """Monitora CPU e RAM a cada 30 segundos com lógica de persistência"""
    global contador_cpu_alta, contador_ram_alta

    uso_cpu = psutil.cpu_percent(interval=1)
    uso_ram = psutil.virtual_memory().percent

    print(f"[LOG] CPU: {uso_cpu}% | RAM: {uso_ram}%")

    # Validação da CPU
    if uso_cpu > LIMITE_CPU:
        contador_cpu_alta += 1
        if contador_cpu_alta == CHECAGENS_PERSISTENCIA:
            enviar_alerta_slack(f"Uso de CPU crítico! Está em *{uso_cpu}%* por mais de 1 minuto e meio seguidos.")
    else:
        contador_cpu_alta = 0  # Reseta se o uso normalizar

    # Validação da RAM
    if uso_ram > LIMITE_RAM:
        contador_ram_alta += 1
        if contador_ram_alta == CHECAGENS_PERSISTENCIA:
            enviar_alerta_slack(f"Memória RAM esgotando! Uso atual em *{uso_ram}%*.")
    else:
        contador_ram_alta = 0  # Reseta se o uso normalizar

def checar_armazenamento():
    """Monitora o Espaço em Disco (Executado em intervalos longos)"""
    uso_disco = psutil.disk_usage('/').percent
    print(f"[LOG DISCO] Armazenamento atual em: {uso_disco}%")
    
    if uso_disco > LIMITE_DISCO:
        enviar_alerta_slack(f"Espaço em disco crítico! Seu Raspberry Pi está com *{uso_disco}%* do armazenamento ocupado.")

# --- LOOP PRINCIPAL DO SERVIDOR ---
if __name__ == "__main__":
    print("🚀 Monitor do Servidor Inicializado com Sucesso dentro da VENV!")
    enviar_alerta_slack("🟢 Monitor de Recursos Inicializado com Sucesso no Raspberry Pi!")

    while True:
        # 1. Sempre checa os recursos rápidos (CPU e RAM)
        checar_recursos_criticos()

        # 2. Controla o tempo para checar o disco (1 vez por hora)
        contador_tempo_disco += INTERVALO_RAPIDO
        if contador_tempo_disco >= SEGUNDOS_PARA_DISCO:
            checar_armazenamento()
            contador_tempo_disco = 0  # Reseta o temporizador do disco

        # Aguarda 30 segundos antes da próxima rodada
        time.sleep(INTERVALO_RAPIDO)