#!/bin/sh

# Configurações do servidor novo
NEW_SERVER_IP="82.29.59.86"
NEW_SERVER_USER="root"
NEW_SERVER_DIR="/home/deploy/empresa/backend"

# Caminho da pasta a ser copiada
SOURCE_DIR="/home/deploy/gdschat/backend/public"

# Nome do arquivo compactado
BACKUP_FILE="public_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# Compactar a pasta
echo "Compactando a pasta $SOURCE_DIR..."
tar -czvf $BACKUP_FILE -C $(dirname $SOURCE_DIR) $(basename $SOURCE_DIR)

# Verificar se a compactação foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Pasta compactada com sucesso: $BACKUP_FILE"
else
    echo "Erro ao compactar a pasta."
    exit 1
fi

# Transferir o arquivo compactado para o novo servidor
echo "Iniciando transferência para o novo servidor..."
scp $BACKUP_FILE $NEW_SERVER_USER@$NEW_SERVER_IP:$NEW_SERVER_DIR

# Verificar se a transferência foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Arquivo transferido com sucesso para o novo servidor."
else
    echo "Erro ao transferir o arquivo. Verifique a conexão e tente novamente."
    echo "Possíveis causas:"
    echo "1. Senha incorreta."
    echo "2. Servidor SSH bloqueando conexões."
    echo "3. Firewall bloqueando a porta 22."
    echo "4. Serviço SSH não está rodando no servidor novo."
    exit 1
fi

# Limpar o arquivo compactado local
rm $BACKUP_FILE

echo "Processo de compactação e transferência concluído."