# Snake Game

## Descripción
Esta es una aplicación web del clásico juego de la serpiente. La aplicación está desarrollada con Flask y se despliega automáticamente en una instancia de AWS EC2 utilizando Docker y Terraform.

## Pasos para Desplegar

### Pre-requisitos
- Tener una cuenta de AWS con credenciales configuradas.
- Tener instalado Docker.
- Tener instalado Terraform.
- Tener configurado AWS CLI en tu máquina local.

### Desplegar la Aplicación

1. **Clonar el repositorio:**
    ```sh
    git clone <URL_DEL_REPOSITORIO>
    cd snake-game
    ```

2. **Construir la imagen de Docker:**
    ```sh
    docker build -t snake-game .
    ```

3. **Configurar AWS CLI:**
    Si aún no has configurado AWS CLI, hazlo con el siguiente comando y sigue las instrucciones:
    ```sh
    aws configure
    ```

4. **Iniciar la infraestructura de AWS con Terraform:**
    ```sh
    cd terraform
    terraform init
    terraform apply -var 'aws_access_key=YOUR_ACCESS_KEY' -var 'aws_secret_key=YOUR_SECRET_KEY'
    ```

    - Reemplaza `YOUR_ACCESS_KEY` y `YOUR_SECRET_KEY` con tus credenciales de AWS.
    - Sigue las instrucciones en pantalla y confirma la creación de la infraestructura cuando se te pida.

5. **Conectarse a la instancia de EC2:**
    Una vez que Terraform finalice, encontrarás la IP de la instancia en la salida. Conéctate a la instancia EC2 utilizando SSH:
    ```sh
    ssh -i /path/to/your-key.pem ec2-user@<INSTANCE_IP>
    ```

6. **Instalar Docker en la instancia de EC2:**
    Una vez conectado a la instancia EC2, instala Docker:
    ```sh
    sudo amazon-linux-extras install docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    ```

    Después de ejecutar los comandos anteriores, cierra la sesión de SSH y vuelve a conectarte para aplicar los cambios de grupo.

7. **Ejecutar el contenedor de Docker en la instancia EC2:**
    Una vez que Docker esté instalado y en funcionamiento, ejecuta el siguiente comando para ejecutar el contenedor de Docker:
    ```sh
    docker run -d -p 80:5000 snake-game
    ```

8. **Acceder a la aplicación:**
    Abra un navegador y acceda a `http://<INSTANCE_IP>`. Aquí `<INSTANCE_IP>` es la dirección IP de tu instancia EC2.

## Notas Adicionales

- Asegúrate de que el puerto 80 esté abierto en el grupo de seguridad de tu instancia EC2 para permitir el tráfico HTTP.
- Puedes revisar los logs del contenedor en la instancia EC2 con:
    ```sh
    docker logs <container_id>
    ```

- Para detener el contenedor:
    ```sh
    docker stop <container_id>
    ```

¡Disfruta jugando al clásico juego de la serpiente en tu navegador!