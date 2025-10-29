package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Uptime    string    `json:"uptime"`
}

type User struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Age       int       `json:"age"`
	Country   string    `json:"country"`
	CreatedAt time.Time `json:"created_at"`
}

type UsersResponse struct {
	Users []User `json:"users"`
	Total int    `json:"total"`
}

var (
	startTime  = time.Now()
	firstNames = []string{"John", "Jane", "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"}
	lastNames  = []string{"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"}
	countries  = []string{"USA", "UK", "Canada", "Australia", "Germany", "France", "Japan", "Brazil", "India", "Spain"}
)

func main() {
	// Set random seed
	rand.Seed(time.Now().UnixNano())

	// Setup routes
	http.HandleFunc("/api/v1/health", healthHandler)
	http.HandleFunc("/api/v1/users", usersHandler)

	// Start server
	port := ":8080"
	fmt.Printf("Server starting on port %s\n", port)
	fmt.Println("Endpoints:")
	fmt.Println("  GET http://localhost:8080/api/v1/health")
	fmt.Println("  GET http://localhost:8080/api/v1/users")

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	uptime := time.Since(startTime)
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Uptime:    uptime.String(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Generate random mock users
	userCount := rand.Intn(6) + 5 // 5-10 users
	users := make([]User, userCount)

	for i := 0; i < userCount; i++ {
		firstName := firstNames[rand.Intn(len(firstNames))]
		lastName := lastNames[rand.Intn(len(lastNames))]

		users[i] = User{
			ID:        i + 1,
			Name:      fmt.Sprintf("%s %s", firstName, lastName),
			Email:     fmt.Sprintf("%s.%s@example.com", firstName, lastName),
			Age:       rand.Intn(50) + 18, // 18-67 years old
			Country:   countries[rand.Intn(len(countries))],
			CreatedAt: time.Now().Add(-time.Duration(rand.Intn(365*2)) * 24 * time.Hour), // Random date in last 2 years
		}
	}

	response := UsersResponse{
		Users: users,
		Total: len(users),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
