package main

import (
	"database/sql"  // For SQL database operations
	"encoding/json" // For JSON handling (modern APIs)
	"fmt"
	"log" // For better error logging
	"net/http"
	"os" // For environment variables
	"strconv"

	_ "github.com/lib/pq" // PostgreSQL driver (underscore means we import for side effects only)
)

type Book struct {
	ID     int     `json:"id"`
	Title  string  `json:"title"`
	Author string  `json:"author"`
	Price  float64 `json:"price"`
}

var books = []Book{
	{ID: 1, Title: "The Great Gatsby", Author: "F. Scott Fitzgerald", Price: 10.99},
	{ID: 2, Title: "1984", Author: "George Orwell", Price: 12.99},
	{ID: 3, Title: "To Kill a Mockingbird", Author: "Harper Lee", Price: 14.99},
}

var database *sql.DB

func initDatabase() {
	var err error

	// Get database connection parameters from environment variables
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "password")
	dbname := getEnv("DB_NAME", "bookstore")

	// Create PostgreSQL connection string
	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	// Open database connection
	database, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Test the connection
	err = database.Ping()
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	fmt.Println("Successfully connected to database!")

	// Setup database schema and sample data
	createTable()
	insertSampleData()
}

func createTable() {
	query := `
	CREATE TABLE IF NOT EXISTS books (
		id SERIAL PRIMARY KEY,
		title VARCHAR(255) NOT NULL,
		author VARCHAR(255) NOT NULL,
		price DECIMAL(10,2) NOT NULL
	)`

	_, err := database.Exec(query)
	if err != nil {
		log.Fatal("Failed to create table:", err)
	}

	fmt.Println("Books table created or already exists")
}

func insertSampleData() {
	// Check if table already has data
	var count int
	err := database.QueryRow("SELECT COUNT(*) FROM books").Scan(&count)
	if err != nil {
		log.Printf("Error checking table count: %v", err)
		return
	}

	if count > 0 {
		fmt.Println("Table already has data, skipping sample data insertion")
		return
	}

	// Insert the same sample books you had before
	sampleBooks := []Book{
		{Title: "The Great Gatsby", Author: "F. Scott Fitzgerald", Price: 10.99},
		{Title: "1984", Author: "George Orwell", Price: 12.99},
		{Title: "To Kill a Mockingbird", Author: "Harper Lee", Price: 14.99},
	}

	for _, book := range sampleBooks {
		_, err := database.Exec("INSERT INTO books (title, author, price) VALUES ($1, $2, $3)",
			book.Title, book.Author, book.Price)
		if err != nil {
			log.Printf("Error inserting sample book: %v", err)
		}
	}

	fmt.Println("Sample data inserted successfully")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, World!")
}

func getBookHandler(w http.ResponseWriter, r *http.Request) {
	// Only allow GET requests
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Same parameter validation as before
	bookIdStr := r.URL.Query().Get("id")
	if bookIdStr == "" {
		http.Error(w, "Book ID is required", http.StatusBadRequest)
		return
	}

	bookId, err := strconv.Atoi(bookIdStr)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	// Use database function instead of in-memory search
	book, err := getBookByID(bookId)
	if err != nil {
		http.Error(w, "Book not found", http.StatusNotFound)
		return
	}

	// Return pretty JSON
	w.Header().Set("Content-Type", "application/json")

	// Pretty print JSON with indentation
	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	encoder.Encode(book)
}

func getBookByID(id int) (*Book, error) {
	book := &Book{}
	err := database.QueryRow("SELECT id, title, author, price FROM books WHERE id = $1", id).
		Scan(&book.ID, &book.Title, &book.Author, &book.Price)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("book not found")
	}
	if err != nil {
		return nil, err
	}

	return book, nil
}

func createBookHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse JSON from request body
	var book Book
	err := json.NewDecoder(r.Body).Decode(&book)
	if err != nil {
		http.Error(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if book.Title == "" || book.Author == "" || book.Price <= 0 {
		http.Error(w, "Title, Author, and Price (>0) are required", http.StatusBadRequest)
		return
	}

	// Create book in database
	createdBook, err := createBook(book)
	if err != nil {
		http.Error(w, "Failed to create book", http.StatusInternalServerError)
		return
	}

	// Return created book with HTTP 201 status and pretty JSON
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)

	// Pretty print JSON with indentation
	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	encoder.Encode(createdBook)
}

func createBook(book Book) (*Book, error) {
	var id int
	err := database.QueryRow("INSERT INTO books (title, author, price) VALUES ($1, $2, $3) RETURNING id",
		book.Title, book.Author, book.Price).Scan(&id)

	if err != nil {
		return nil, err
	}

	book.ID = id
	return &book, nil
}

// Add this function to get all books from database
func getAllBooks() ([]Book, error) {
	rows, err := database.Query("SELECT id, title, author, price FROM books ORDER BY id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var books []Book
	for rows.Next() {
		var book Book
		err := rows.Scan(&book.ID, &book.Title, &book.Author, &book.Price)
		if err != nil {
			return nil, err
		}
		books = append(books, book)
	}

	return books, nil
}

// Delete book from database
func deleteBook(id int) error {
	result, err := database.Exec("DELETE FROM books WHERE id = $1", id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("book with id %d not found", id)
	}

	return nil
}

// HTTP handler for deleting books
func deleteBookHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get book ID from URL parameter
	bookIdStr := r.URL.Query().Get("id")
	if bookIdStr == "" {
		http.Error(w, "Book ID is required", http.StatusBadRequest)
		return
	}

	bookId, err := strconv.Atoi(bookIdStr)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	// Delete the book
	err = deleteBook(bookId)
	if err != nil {
		if err.Error() == fmt.Sprintf("book with id %d not found", bookId) {
			http.Error(w, "Book not found", http.StatusNotFound)
		} else {
			http.Error(w, "Failed to delete book", http.StatusInternalServerError)
		}
		return
	}

	// Return success message with pretty JSON
	w.Header().Set("Content-Type", "application/json")

	response := map[string]interface{}{
		"message": "Book deleted successfully",
		"id":      bookId,
	}

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	encoder.Encode(response)
}

// Add this HTTP handler with pretty JSON formatting
func getAllBooksHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	books, err := getAllBooks()
	if err != nil {
		http.Error(w, "Failed to retrieve books", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	// Pretty print JSON with indentation
	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	encoder.Encode(books)
}

func main() {
	// Initialize database connection
	initDatabase()
	defer database.Close()

	// Register handlers
	http.HandleFunc("/", helloHandler)
	http.HandleFunc("/book", getBookHandler)          // GET /book?id=X
	http.HandleFunc("/createBook", createBookHandler) // POST /createBook
	http.HandleFunc("/books", getAllBooksHandler)     // GET /books
	http.HandleFunc("/deleteBook", deleteBookHandler) // DELETE /deleteBook?id=X

	port := getEnv("PORT", "8080")
	fmt.Println("Server is running on port 8080...\n", port)
	http.ListenAndServe(":"+port, nil)
}
