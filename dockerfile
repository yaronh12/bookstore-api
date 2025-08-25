FROM golang:1.23.3-alpine

WORKDIR /app

# Copy go module files first (for better caching)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application
RUN go build -o main .

EXPOSE 8080

CMD ["./main"]