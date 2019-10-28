package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	env := os.Getenv("ENVIRONMENT")
	port := 8080
	log.Printf("Running in environment: %s\n", env)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received request from %s at %s", r.RemoteAddr, r.URL.EscapedPath())
		fmt.Fprint(w, "Hello World!")
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Received health check from %s", r.RemoteAddr)
		w.WriteHeader(http.StatusOK)
	})
	log.Printf("Starting server on port: %v", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%v", port), nil))

}
