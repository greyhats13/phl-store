# OLS Profile Service

## Overview

The `fta_profile` is a FastAPI-based service designed to manage user profiles. It is architected with Clean Architecture, consisting of four layers: Domain, Infrastructure, Application, and Adapter.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Contributing](#contributing)
- [License](#license)

## Features

1. **CRUD Operations**: Create, Read, Update, and Delete user profiles.
2. **Pagination**: Support for listing profiles with pagination.
3. **Rate Limiting**: API request throttling.
4. **Data Validation**: Built-in validation using Pydantic.
5. **Logging**: Detailed logging for debugging and auditing.
6. **Middleware**: Logging, CORS, Trusted Hosts, and Gzip compression.
7. **Error Handling**: Comprehensive error handling and reporting.
8. **Unit Testing**: Automated tests for the service.

## Prerequisites

- Python 3.11.6 or higher
- Docker & Docker Compose

## Installation

To run this service, you will need Docker and Docker Compose. Clone the repository and navigate to the project directory:

```bash
Extract the zip file
cd fta_profile
```

Then, simply run:

```bash
docker-compose build
docker-compose up
```
or
```bash
docker-compose up --build
```

This will build and run the Docker image.

## Configuration

The service utilizes a configuration file located at `fta_profile/app/config.py` to set various parameters, which include configurations for MongoDB, Redi. To adjust these settings, you can edit this file accordingly. 


1. Execute the code specifically in local mode.
2. Set the `CLOUD_PROVIDER` environment variable to `LOCAL` within the `.env.app` file.

Either of these approaches will enable the application to operate in local mode, allowing it to use the local instances of MongoDB and Redis as configured in the Docker Compose file.

## Usage

Once the service is up and running, you can access the API documentation at:

```
http://localhost:8000/docs
http://localhost:8000/redoc
```
I also have attached the postman collection for the API testing.

## API Endpoints

- `GET /v1/profiles`: List profiles with pagination.
- `GET /v1/profiles/{uuid}`: Retrieve a specific profile by UUID.
- `POST /v1/profiles`: Create a new profile.
- `PUT /v1/profiles/{uuid}`: Update a profile by UUID.
- `DELETE /v1/profiles/{uuid}`: Delete a profile by UUID.

## Monitoring and Logging Section

### Monitoring and Logging Overview

The architecture utilizes the Elastic Stack, often known as the ELK Stack (Elasticsearch, Logstash, and Kibana), to offer a complete monitoring and logging solution. This section will guide you through the lifecycle of logs from their origin to visualization.

---

### Filebeat: The Log Forwarder

1. **What it Does**: Filebeat operates as a lightweight shipper that forwards logs from your services running in Docker containers to Logstash.
  
2. **Filtering**: Filebeat is configured to ignore logs from certain containers like Elasticsearch, Kibana, and Logstash to prevent redundancy and reduce noise.

3. **Communication with Logstash**: The logs that pass the Filebeat filters are then forwarded to Logstash on port 5044 for further processing.

---

### Logstash: The Log Processor

1. **Initial Input**: Logstash listens on port 5044 for logs coming from Filebeat.

2. **Grok Pattern Matching**: The logs are parsed using Grok patterns to structure the incoming string of log data into meaningful fields like `level`, `timestamp`, and `json_content`.

3. **JSON Parsing**: The `json_content` field, which contains JSON-formatted log details, is then parsed to extract various log attributes.

4. **Field Mutation**: New fields such as `method`, `status_code`, `path`, and `latency` are added to the log data for more context.

5. **Field Renaming and Cleanup**: Certain fields are renamed for better readability, and unnecessary ones are removed to streamline the log data.

6. **Elasticsearch Output**: Finally, the processed logs are sent to an Elasticsearch index for storage. It may take sometime for the logs to appear in Kibana until the Elasticsearch index is updated. You can the add data view after in Kibana to see the logs in Discover tab.

---

### Elasticsearch: The Log Storage

1. **Storage**: Elasticsearch stores the structured log data coming from Logstash. 

2. **Search and Query**: It allows for complex search queries to retrieve specific logs, making it the backbone of our monitoring solution.

---

### Kibana: The Visualization Tool

1. **Data Retrieval**: Kibana fetches the log data from Elasticsearch.

2. **Visualization and Analysis**: You can create various types of visualizations like graphs, tables, and dashboards to monitor service health, debug issues, and gain operational insights.

---

By following this process, we achieve a scalable and efficient logging system that not only helps in monitoring but also in debugging and performance optimization.

## Rate Limiting
### Rate Limiting with FastAPI Limiter in `fta_profile` Service

#### Overview
The `fta_profile` service employs rate limiting to control the frequency of client requests. It's done using FastAPI Limiter, a third-party package for rate limiting FastAPI applications. This rate limiting is applicable to each client IP address.

#### How It Works

1. **Configuration**: Rate limit parameters like the number of allowed requests (`rate_limit_times`) and the time window (`rate_limit_seconds`) are configured in the `Settings` class in the `config.py` file. Conifg are read from the environment variables .env.app file. The default setup is 20 requests per 60 seconds for all endpoints.

2. **Importing RateLimiter**: The FastAPI Limiter's `RateLimiter` is imported and used as a dependency in the API routes.

3. **API Routes**: The `profile_router.py` file includes FastAPI routes like GET, POST, PUT, and DELETE. Each of these routes has the `RateLimiter` dependency added to it, specifying the rate limits defined in the settings.

4. **Middleware & Exception Handling**: The `RateLimitMiddleware` in the `middleware.py` file is responsible for maintaining the count of requests from each client IP. If a client exceeds the rate limit, an HTTP 429 (Too Many Requests) error is raised. 

5. **Redis Backend**: FastAPI Limiter uses Redis to keep track of the request count for each client. The Redis connection details are also specified in the `config.py`.

6. **Error Handling**: If a client exceeds the rate limit, the service responds with a 429 status code, as defined in the `error.py` under HTTP Exception handling.

By following this approach, the service ensures that API resources are not abused and provides a level of control over the incoming requests.


## Contributing

Please refer to the contributing guidelines for details on how to contribute to this project.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.