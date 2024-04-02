#!/bin/bash
APP_DIR="/app"
APP_REPO_PATH="/book-store-devops/book-store"

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Este script debe ejecutarse como root o con sudo."
        exit 1
    fi
}
install_nodejs() {
    if command -v node >/dev/null && [[ $(node -v) == v16* ]]; then
        echo "Node.js versión 16 ya está instalada."
    else
        # Actualizar la lista de paquetes
        apt-get update -y >/dev/null 2>&1 || { echo "Error al actualizar la lista de paquetes. Abortando."; exit 1; }

        # Instalar Node.js versión 16
        echo "Instalando Node.js versión 16..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | bash - || { echo "Error al agregar el repositorio de Node.js. Abortando."; exit 1; }
        apt-get install -y nodejs >/dev/null 2>&1 || { echo "Error al instalar Node.js. Abortando."; exit 1; }
        echo "------------"
        echo "Node.js versión $(node -v) ha sido instalada correctamente."
        echo "------------"

    fi
}

install_pm2(){
    
    if ! command -v pm2 &> /dev/null; then
        npm install pm2@latest -g >/dev/null 2>&1
        if ! command -v pm2 &> /dev/null; then
            echo "Error: PM2 no se instaló correctamente, verifica la instalación de Nodejs "
        fi
    fi
}

clone_repository(){
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Installing "
        apt-get update
        apt-get install -y git

    fi

    if [ -d $APP_DIR ]; then
        echo "El directorio ${APP_DIR} ya existe."
    else
        mkdir $APP_DIR
        cd $APP_DIR
        echo "Clonando repositorio."
        git clone https://gitlab.com/training-devops-cf/book-store-devops.git &> /dev/null
    fi
}
app_install_requirements(){
    cd $APP_DIR$APP_REPO_PATH

    if [ -d "node_modules" ]; then
        echo "Las dependencias ya están instaladas en el directorio 'node_modules'."
        exit 0
    fi
    echo "Instalando dependencias utilizando 'npm install'..."
    npm install

    # Verificar si la instalación fue exitosa
    if [ $? -eq 0 ]; then
        echo "Las dependencias se han instalado correctamente."
    else
        echo "Error: La instalación de dependencias falló. Verifica tu configuración de npm y el archivo package.json."
        exit 1
    fi    
    # build 
    npm run build
}

configure_pm2() {
    cd $APP_DIR/$APP_REPO_PATH/src
    pm2 start --name "book-store" npm -- start
    sleep 2
    # Guardar el estado actual de los procesos de PM2 para que se inicien automáticamente al arrancar el sistema
    pm2 save

    # Configurar PM2 para iniciar automáticamente al arrancar el sistema
    pm2 startup

    echo "PM2 se ha instalado y configurado correctamente. Tu aplicación se iniciará automáticamente con PM2 al arrancar el sistema."
}


# Llamar a la función install_nodejs para instalar Node.js
install_nodejs
install_pm2
clone_repository
app_install_requirements
configure_pm2
