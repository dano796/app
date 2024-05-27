# Usa una imagen base de Node.js
FROM node:14

# Crea un directorio de trabajo
WORKDIR /usr/src/app

# Copia los archivos de la aplicación al directorio de trabajo
COPY package*.json ./
COPY index.html .
COPY script.js .
COPY server.js .
COPY style.css .

# Instala las dependencias de la aplicación
RUN npm install express

# Exponer el puerto en el que la aplicación se ejecutará
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["node", "server.js"]