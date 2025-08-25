# Book Store API

A production-ready REST API for managing books, built with Go and PostgreSQL. Easy to deploy on OpenShift using enterprise-grade templates.

## 🚀 Features

- **Simple CRD Operations**: Create, Read, Read All, Delete books
- **Enterprise PostgreSQL**: Uses OpenShift's PostgreSQL template (no external dependencies)
- **Pretty JSON Responses**: Formatted JSON output for better readability
- **Cloud-Native**: Containerized and deployed on OpenShift/Kubernetes
- **Persistent Storage**: Data survives pod restarts and scaling
- **Production Ready**: Enterprise-grade database with proper security

## 📋 API Endpoints

| Method | Endpoint | Description | Parameters |
|--------|----------|-------------|------------|
| `GET` | `/` | Health check / Hello World | None |
| `GET` | `/book?id=X` | Get single book by ID | `id` (required) |
| `GET` | `/books` | Get all books | None |
| `POST` | `/createBook` | Create a new book | JSON body |
| `DELETE` | `/deleteBook?id=X` | Delete book by ID | `id` (required) |

## 📝 API Usage Examples

### Get All Books
```bash
curl "http://your-app-url/books"
```

**Response:**
```json
[
  {
    "id": 1,
    "title": "The Great Gatsby",
    "author": "F. Scott Fitzgerald",
    "price": 10.99
  },
  {
    "id": 2,
    "title": "1984",
    "author": "George Orwell",
    "price": 12.99
  }
]
```

### Get Single Book
```bash
curl "http://your-app-url/book?id=1"
```

### Create New Book
```bash
curl -X POST "http://your-app-url/createBook" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Clean Code",
    "author": "Robert Martin",
    "price": 35.99
  }'
```

### Delete Book
```bash
curl -X DELETE "http://your-app-url/deleteBook?id=5"
```

**Response:**
```json
{
  "message": "Book deleted successfully",
  "id": 5
}
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   OpenShift     │    │   Go App         │    │   PostgreSQL    │
│   Route         │───▶│   (2 replicas)   │───▶│   (Template)    │
│   (External)    │    │   Port 8080      │    │   Port 5432     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                       ┌──────────────┐        ┌─────────────────┐
                       │   Service    │        │ Persistent      │
                       │   NodePort   │        │ Volume          │
                       └──────────────┘        │ (Ceph Storage)  │
                                              └─────────────────┘
```

## 🛠️ Technology Stack

- **Language**: Go 1.23
- **Database**: PostgreSQL 13 (Enterprise Red Hat image)
- **Container**: Docker with multi-stage builds
- **Orchestration**: OpenShift/Kubernetes
- **Storage**: Ceph RBD (Block Storage)
- **Registry**: Quay.io
- **Database Deployment**: OpenShift PostgreSQL Template

## 📦 Project Structure

```
firstGoApp/
├── main.go              # Go application source code
├── go.mod               # Go module dependencies
├── go.sum               # Dependency checksums  
├── dockerfile           # Container build instructions
├── deployment.yaml      # OpenShift app deployment
├── service.yaml         # OpenShift app service
├── test_api.sh         # Comprehensive API test suite
└── README.md           # This documentation
```

**Note**: PostgreSQL is deployed using OpenShift's enterprise template, not manual YAML files.

## 🚀 Quick Start

### Prerequisites
- OpenShift cluster access with `oc` CLI
- Docker with container registry push access
- Git for cloning the repository

### Step 1: Clone and Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd firstGoApp

# Create or switch to your OpenShift namespace
oc new-project my-bookstore
# OR
oc project my-bookstore
```

### Step 2: Deploy PostgreSQL
```bash
# Deploy enterprise PostgreSQL using OpenShift template
oc new-app postgresql-persistent \
  -p DATABASE_SERVICE_NAME=postgresql-service \
  -p POSTGRESQL_USER=postgres \
  -p POSTGRESQL_PASSWORD=password \
  -p POSTGRESQL_DATABASE=bookstore \
  -p VOLUME_CAPACITY=1Gi
```

**This automatically creates:**
- PostgreSQL with enterprise Red Hat image
- Service for database connectivity  
- PersistentVolumeClaim with optimal storage
- Secrets for credential management

### Step 3: Build and Deploy Application
```bash
# Build the container image
docker build --platform linux/amd64 -t <your-registry>/bookstore-api:latest .

# Push to your container registry
docker push <your-registry>/bookstore-api:latest

# Update deployment.yaml with your image
sed -i 's|quay.io/rh-ee-yhod/mygoapp:.*|<your-registry>/bookstore-api:latest|' deployment.yaml

# Deploy the application
oc apply -f deployment.yaml
oc apply -f service.yaml

# Create external access route
oc expose service go-app-service --name=bookstore-route
```

### Step 4: Test Your Deployment
```bash
# Get your application URL
export APP_URL=$(oc get route bookstore-route -o jsonpath='{.spec.host}')

# Test the API
curl "http://$APP_URL/"                    # Health check
curl "http://$APP_URL/books"               # Get all books
curl "http://$APP_URL/book?id=1"           # Get single book

# Run comprehensive tests
./test_api.sh "http://$APP_URL"
```

### Environment Variables

The application uses these environment variables (configured in `deployment.yaml`):

| Variable | Value | Description |
|----------|-------|-------------|
| `DB_HOST` | `postgresql-service` | PostgreSQL service name |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `postgres` | Database username |
| `DB_PASSWORD` | `password` | Database password |
| `DB_NAME` | `bookstore` | Database name |
| `PORT` | `8080` | Application port |

## 🧪 Testing

### Automated Test Suite
```bash
# Make test script executable
chmod +x test_api.sh

# Run comprehensive tests (24 test cases)
./test_api.sh

# Test with specific URL
./test_api.sh "http://your-custom-url"
```

**Test Coverage:**
- ✅ Basic connectivity and health checks
- ✅ CRUD operations (Create, Read, Delete)
- ✅ Error handling and validation
- ✅ Performance testing with concurrent requests
- ✅ Edge cases and invalid inputs
- ✅ JSON response validation

### Manual Testing
```bash
# Get your application URL
APP_URL=$(oc get route bookstore-route -o jsonpath='{.spec.host}')

# Test endpoints
curl "http://$APP_URL/"                    # Health check
curl "http://$APP_URL/books"               # Get all books
curl "http://$APP_URL/book?id=1"           # Get single book

# Create a test book
curl -X POST "http://$APP_URL/createBook" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Book","author":"Test Author","price":19.99}'
```

## 📊 Monitoring & Operations

### Check Application Status
```bash
# Overview of all resources
oc get all

# Application logs
oc logs -f deployment/go-app

# Database logs  
oc logs -f deploymentconfig/postgresql
```

### Database Operations
```bash
# Connect to database
oc exec -it deploymentconfig/postgresql -- psql -U postgres -d bookstore

# Check database size and connections
oc exec -it deploymentconfig/postgresql -- psql -U postgres -d bookstore -c "
  SELECT pg_size_pretty(pg_database_size('bookstore')) as db_size;
  SELECT count(*) as book_count FROM books;
"
```

### Scaling
```bash
# Scale application (database auto-scales)
oc scale deployment go-app --replicas=3

# Check scaling status
oc get pods -l app=go-app
```

## 🔧 Development Workflow

### Making Changes
1. **Modify** `main.go` with your changes
2. **Build** new Docker image with incremented tag:
   ```bash
   docker build --platform linux/amd64 -t <your-registry>/bookstore-api:v1.1 .
   ```
3. **Push** to registry:
   ```bash
   docker push <your-registry>/bookstore-api:v1.1
   ```
4. **Update** `deployment.yaml` with new image tag
5. **Deploy**:
   ```bash
   oc apply -f deployment.yaml
   ```

### Adding New Endpoints
The application follows this pattern for new endpoints:
1. Add handler function in `main.go`
2. Register route in `main()` function  
3. Use pretty JSON encoding for responses
4. Add validation and error handling
5. Update tests in `test_api.sh`

## 🐛 Troubleshooting

### Common Issues

**Application won't start:**
```bash
# Check logs
oc logs deployment/go-app

# Check database connectivity
oc exec -it deploymentconfig/postgresql -- pg_isready -U postgres
```

**Database connection errors:**
```bash
# Verify database exists
oc exec -it deploymentconfig/postgresql -- psql -U postgres -l | grep bookstore

# Create database if missing
oc exec -it deploymentconfig/postgresql -- psql -U postgres -c "CREATE DATABASE bookstore;"
```

**Image pull errors:**
```bash
# Ensure correct architecture
docker build --platform linux/amd64 -t <your-registry>/bookstore-api .

# Check image exists in registry
docker pull <your-registry>/bookstore-api:latest
```

**Storage issues:**
```bash
# Check PVC status
oc get pvc

# Check storage class
oc describe pvc postgresql
```

## 🔒 Security Features

- **SQL Injection Protection**: Parameterized queries with `$1, $2` placeholders
- **Network Isolation**: Database only accessible within cluster
- **Credential Management**: Database passwords stored in OpenShift secrets
- **Resource Limits**: Configurable CPU/memory limits in deployment
- **Enterprise Images**: Red Hat certified container images

## 📈 Performance

- **Connection Pooling**: Go's `database/sql` provides automatic connection pooling
- **Horizontal Scaling**: Can scale to multiple replicas
- **Persistent Storage**: High-performance Ceph block storage
- **Load Balancing**: OpenShift automatically load balances between replicas
- **Health Checks**: Kubernetes health probes ensure only healthy pods serve traffic

## 📚 Sample Data

The application automatically initializes with sample books:
1. **The Great Gatsby** by F. Scott Fitzgerald ($10.99)
2. **1984** by George Orwell ($12.99)  
3. **To Kill a Mockingbird** by Harper Lee ($14.99)

Additional books can be created via the API.

## 🏢 Enterprise Features

### Why OpenShift Template for PostgreSQL?
- ✅ **No External Dependencies**: No Docker Hub rate limits
- ✅ **Enterprise Support**: Red Hat certified and supported
- ✅ **Automatic Configuration**: Optimal settings for OpenShift
- ✅ **Security**: Built-in secrets management
- ✅ **Storage Integration**: Automatic storage class selection
- ✅ **Monitoring**: Integrated with OpenShift monitoring

### Production Considerations
- Database backups via OpenShift operators
- High availability with multiple database replicas
- Resource quotas and limits
- Network policies for enhanced security
- Integration with CI/CD pipelines

## 📞 Support & Contributing

### Getting Help
- **Logs**: `oc logs deployment/go-app`
- **Status**: `oc get all`
- **Database**: `oc exec -it deploymentconfig/postgresql -- psql -U postgres -d bookstore`

### Contributing
1. Fork the repository
2. Create feature branch
3. Add tests for new functionality  
4. Update documentation
5. Test thoroughly with `./test_api.sh`
6. Submit pull request

## ⚙️ Customization

### Using Different Container Registries
Replace `<your-registry>` with your preferred registry:
- **Docker Hub**: `docker.io/username/bookstore-api`
- **Quay.io**: `quay.io/username/bookstore-api`
- **Google Container Registry**: `gcr.io/project-id/bookstore-api`
- **OpenShift Internal Registry**: `image-registry.openshift-image-registry.svc:5000/namespace/bookstore-api`

### Environment Customization
Modify `deployment.yaml` environment variables:
```yaml
env:
- name: DB_HOST
  value: "your-custom-db-host"
- name: PORT
  value: "3000"  # Change application port
```

### Database Customization
For different database settings, modify the PostgreSQL template parameters:
```bash
oc new-app postgresql-persistent \
  -p POSTGRESQL_DATABASE=mystore \
  -p POSTGRESQL_USER=myuser \
  -p VOLUME_CAPACITY=5Gi
```

---

**Built with ❤️ using Go, PostgreSQL, and OpenShift** 🚀📚
