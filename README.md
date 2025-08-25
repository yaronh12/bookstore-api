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


---

**Built with ❤️ using Go, PostgreSQL, and OpenShift** 🚀📚
