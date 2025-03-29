#!/bin/sh

# Caminho onde o arquivo foi transferido
BACKUP_DIR="/home/deploy/empresa/backend"
BACKUP_FILE=$(ls $BACKUP_DIR/public_backup_*.tar.gz)

# Verificar se o arquivo existe
if [ -z "$BACKUP_FILE" ]; then
    echo "Nenhum arquivo de backup encontrado em $BACKUP_DIR."
    exit 1
fi

# Extrair o arquivo compactado
echo "Extraindo o arquivo $BACKUP_FILE..."
tar -xzvf $BACKUP_FILE -C $BACKUP_DIR

# Verificar se a extração foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Arquivo extraído com sucesso."
else
    echo "Erro ao extrair o arquivo."
    exit 1
fi

# Limpar o arquivo compactado
rm $BACKUP_FILE

echo "Processo de extração concluído."