package main

import (
	"log"

	"shortlink/config"
	"shortlink/database"
	"shortlink/router"
)

func main() {
	cfg := config.Load()

	if err := database.Connect(cfg); err != nil {
		log.Fatalf("database: %v", err)
	}

	r := router.Setup(cfg)
	addr := ":" + cfg.ServerPort
	log.Printf("server listening on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("server: %v", err)
	}
}
