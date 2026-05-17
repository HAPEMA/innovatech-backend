# Innovatech Chile — Sistema de Despachos · Backend

![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.4-6DB33F?style=flat&logo=springboot&logoColor=white)
![Java](https://img.shields.io/badge/Java-17-ED8B00?style=flat&logo=openjdk&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat&logo=githubactions&logoColor=white)

API REST para la gestión de despachos de Innovatech Chile, desarrollada en el marco del curso **ISY1101 DevOps — DuocUC**.

---

## Descripción

El backend expone un conjunto de endpoints RESTful que permiten crear, consultar, actualizar y eliminar registros de despacho. Cada despacho representa un intento de entrega asociado a una compra, con información del camión, dirección y estado de entrega.

La aplicación corre en un contenedor Docker sobre una instancia **EC2 privada en AWS**, accesible únicamente desde la capa frontend a través de la red interna de la VPC.

---

## Arquitectura

```
Internet
    │
    ▼
┌─────────────────────────┐
│  EC2 Frontend (pública) │  ← Jump host SSH / Proxy
│  Subred pública AWS      │
└────────────┬────────────┘
             │ Red interna VPC
             ▼
┌─────────────────────────┐
│  EC2 Backend (privada)  │  IP: 10.0.135.240
│  Subred privada AWS      │
│                          │
│  ┌──────────────────┐   │
│  │ backend-despachos│:8081
│  │  (Spring Boot)   │   │
│  └────────┬─────────┘   │
│           │ backend-network
│  ┌────────▼─────────┐   │
│  │  mysql-despachos  │:3306
│  │    (MySQL 8.0)    │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

> El EC2 Backend **no tiene IP pública**. El pipeline CI/CD y el frontend se conectan a él usando el EC2 Frontend como **SSH jump host**.

---

## Requisitos previos

| Herramienta | Versión mínima |
|-------------|---------------|
| Docker      | 24.x          |
| Docker Compose | 2.x        |
| Java (solo desarrollo local sin Docker) | 17 |
| Maven (solo desarrollo local sin Docker) | 3.9.x |

---

## Variables de entorno

La aplicación requiere las siguientes variables en tiempo de ejecución. Crea un archivo `.env` en la raíz del proyecto a partir del ejemplo incluido:

```bash
cp .env.example .env
```

| Variable      | Descripción                              | Ejemplo              |
|---------------|------------------------------------------|----------------------|
| `DB_ENDPOINT` | Host del servidor MySQL                  | `mysql` (en Docker)  |
| `DB_PORT`     | Puerto MySQL                             | `3306`               |
| `DB_NAME`     | Nombre de la base de datos               | `despachos_db`       |
| `DB_USERNAME` | Usuario de la base de datos              | `citt_user`          |
| `DB_PASSWORD` | Contraseña de la base de datos           | `tu_password_seguro` |

**`.env.example`**
```env
DB_NAME=despachos_db
DB_USERNAME=citt_user
DB_PASSWORD=tu_password_seguro
```

> `DB_ENDPOINT` y `DB_PORT` son fijados por Docker Compose al nombre del servicio (`mysql`) y al puerto estándar (`3306`). Solo es necesario declararlos manualmente al correr el backend sin Compose.

---

## Correr localmente con Docker Compose

```bash
# 1. Clonar el repositorio
git clone https://github.com/<usuario>/innovatech-backend.git
cd innovatech-backend

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con los valores deseados

# 3. Levantar los servicios
docker compose up -d

# 4. Verificar que los contenedores estén corriendo
docker compose ps

# 5. Ver logs del backend
docker compose logs -f backend
```

La API estará disponible en `http://localhost:8081`.

Para detener los servicios:

```bash
docker compose down
```

Para eliminar también el volumen de datos:

```bash
docker compose down -v
```

### Servicios Docker Compose

| Servicio           | Imagen                               | Puerto  | Descripción            |
|--------------------|--------------------------------------|---------|------------------------|
| `mysql-despachos`  | `mysql:8.0`                          | `3306`  | Base de datos MySQL     |
| `backend-despachos`| `hapema/innovatech-backend:latest`   | `8081`  | API REST Spring Boot    |

- **Red:** `backend-network` (bridge)
- **Volumen persistente:** `despachos-mysql-data`
- **Healthcheck MySQL:** el backend espera a que MySQL pase el healthcheck antes de iniciar (`depends_on: condition: service_healthy`)

---

## Endpoints de la API

Base URL: `http://<host>:8081/api/v1`

| Método   | Endpoint                  | Descripción                        | Código éxito |
|----------|---------------------------|------------------------------------|--------------|
| `GET`    | `/despachos`              | Listar todos los despachos         | `200 OK`     |
| `GET`    | `/despachos/{id}`         | Obtener un despacho por ID         | `200 OK`     |
| `POST`   | `/despachos`              | Crear un nuevo despacho            | `201 Created`|
| `PUT`    | `/despachos/{id}`         | Actualizar un despacho existente   | `200 OK`     |
| `DELETE` | `/despachos/{id}`         | Eliminar un despacho               | `204 No Content` |

### Modelo de datos — `Despacho`

```json
{
  "idDespacho":      1,
  "fechaDespacho":   "2026-05-16",
  "patenteCamion":   "ABCD12",
  "intento":         1,
  "idCompra":        100,
  "direccionCompra": "Av. Providencia 1234, Santiago",
  "valorCompra":     59990,
  "despachado":      false
}
```

| Campo             | Tipo      | Descripción                                    |
|-------------------|-----------|------------------------------------------------|
| `idDespacho`      | `Long`    | Identificador único (generado automáticamente) |
| `fechaDespacho`   | `LocalDate` | Fecha del despacho (formato `YYYY-MM-DD`)    |
| `patenteCamion`   | `String`  | Patente del camión asignado                    |
| `intento`         | `int`     | Número de intento de entrega                   |
| `idCompra`        | `Long`    | ID de la compra asociada                       |
| `direccionCompra` | `String`  | Dirección de entrega                           |
| `valorCompra`     | `Long`    | Valor total de la compra en CLP                |
| `despachado`      | `boolean` | Estado de la entrega (`false` por defecto)     |

### Documentación interactiva (Swagger UI)

```
http://localhost:8081/swagger-ui.html
```

---

## Pipeline CI/CD

El pipeline está definido en `.github/workflows/deploy.yml` y se activa con cada `push` a la rama **`deploy`**.

```
push → rama deploy
        │
        ▼
┌───────────────────┐
│  GitHub Actions    │
│  (ubuntu-latest)  │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Build imagen     │
│  Docker multi-stage│
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│  Push a Docker Hub │
│  hapema/innovatech │
│  -backend:latest   │
└────────┬──────────┘
         │ SSH (via EC2 Frontend como jump host)
         ▼
┌───────────────────┐
│  EC2 Backend       │
│  docker pull       │
│  docker stop/rm    │
│  docker run        │
└───────────────────┘
```

### Secrets requeridos en GitHub

| Secret               | Descripción                                      |
|----------------------|--------------------------------------------------|
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub                            |
| `DOCKERHUB_TOKEN`    | Token de acceso a Docker Hub                     |
| `EC2_FRONTEND_HOST`  | IP pública del EC2 Frontend (usado como proxy SSH)|
| `EC2_BACKEND_HOST`   | IP privada del EC2 Backend (`10.0.135.240`)      |
| `EC2_SSH_KEY`        | Clave privada SSH para ambas instancias          |
| `DB_NAME`            | Nombre de la base de datos en producción         |
| `DB_USERNAME`        | Usuario de MySQL en producción                   |
| `DB_PASSWORD`        | Contraseña de MySQL en producción                |

### Flujo de ramas

| Rama     | Propósito                                      |
|----------|------------------------------------------------|
| `main`   | Código estable, sin despliegue automático      |
| `deploy` | Rama que dispara el pipeline CI/CD a AWS       |

Para desplegar a producción:

```bash
git checkout deploy
git merge main
git push origin deploy
```

---

## Notas de despliegue en AWS

- La instancia EC2 Backend se encuentra en una **subred privada** (`10.0.135.240`) y no posee IP pública, por lo que no es accesible directamente desde internet.
- El acceso SSH al EC2 Backend se realiza a través del **EC2 Frontend como jump host** (configurado con `proxy_host` en el paso de deploy del workflow).
- En producción el backend corre como contenedor independiente (`docker run`) en lugar de Docker Compose, con las variables de entorno inyectadas vía `--env` desde los secrets de GitHub Actions.
- La base de datos MySQL también corre como contenedor en el mismo EC2 Backend. Asegúrate de que el contenedor MySQL esté en ejecución antes de iniciar el backend en un reinicio manual.
- El contenedor backend tiene política `--restart always`, por lo que se recupera automáticamente ante reinicios del sistema operativo.

---

## Estructura del proyecto

```
innovatech-backend/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD
├── src/
│   └── main/
│       ├── java/com/citt/
│       │   ├── config/         # CORS y OpenAPI/Swagger
│       │   ├── controller/     # DespachoController
│       │   ├── exceptions/     # Manejo de errores personalizado
│       │   └── persistence/
│       │       ├── entity/     # Entidad Despacho (JPA)
│       │       ├── repository/ # DespachoRepository (Spring Data JPA)
│       │       └── services/   # DespachoService + impl
│       └── resources/
│           └── application.properties
├── Dockerfile                  # Build multi-stage
├── docker-compose.yml          # Orquestación local
├── .env.example                # Plantilla de variables de entorno
└── pom.xml
```

---

## Curso

**ISY1101 DevOps — DuocUC**
