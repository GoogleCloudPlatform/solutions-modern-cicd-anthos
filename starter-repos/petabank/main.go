package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
)

const defaultAddr = ":8080"

var statistics = 123324

// main starts an http server on the $PORT environment variable.
func main() {
	addr := defaultAddr
	// $PORT environment variable is provided in the Kubernetes deployment.
	if p := os.Getenv("PORT"); p != "" {
		addr = ":" + p
	}

	log.Printf("server starting to listen on %s", addr)

	http.HandleFunc("/stats", stats)
	http.HandleFunc("/", home)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("server listen error: %+v", err)
	}
}

// home logs the received request and returns a simple response.
func home(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received request: %s %s", r.Method, r.URL.Path)
	fmt.Fprintf(w, "Hipster Shop now accepts all major credit cards! (powered by Petabank)")
}

func stats(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received request: %s %s", r.Method, r.URL.Path)
	statistics = statistics + 7
	fmt.Fprintf(w, strconv.Itoa(statistics))
}
