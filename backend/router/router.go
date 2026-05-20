package router

import (
	"shortlink/config"
	"shortlink/handlers"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func Setup(cfg *config.Config) *gin.Engine {
	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://127.0.0.1:5173"},
		AllowMethods:     []string{"GET", "POST", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept"},
		AllowCredentials: true,
	}))

	h := handlers.NewLinkHandler(cfg)

	api := r.Group("/api")
	{
		api.GET("/health", h.Health)
		api.POST("/links", h.Create)
		api.GET("/links", h.List)
	}

	r.GET("/:code", h.Redirect)

	return r
}
