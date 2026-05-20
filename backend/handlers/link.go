package handlers

import (
	"net/http"
	"time"

	"shortlink/config"
	"shortlink/models"
	"shortlink/service"

	"github.com/gin-gonic/gin"
)

type LinkHandler struct {
	cfg *config.Config
}

func NewLinkHandler(cfg *config.Config) *LinkHandler {
	return &LinkHandler{cfg: cfg}
}

type createLinkRequest struct {
	URL string `json:"url" binding:"required"`
}

type linkResponse struct {
	ID          uint   `json:"id"`
	OriginalURL string `json:"original_url"`
	ShortCode   string `json:"short_code"`
	ShortURL    string `json:"short_url"`
	ClickCount  int    `json:"click_count"`
	CreatedAt   string `json:"created_at"`
}

func (h *LinkHandler) Create(c *gin.Context) {
	var req createLinkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "url is required"})
		return
	}

	link, err := service.CreateLink(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toResponse(link, h.cfg.BaseURL))
}

func (h *LinkHandler) List(c *gin.Context) {
	links, err := service.ListLinks()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list links"})
		return
	}

	result := make([]linkResponse, 0, len(links))
	for i := range links {
		result = append(result, toResponse(&links[i], h.cfg.BaseURL))
	}

	c.JSON(http.StatusOK, result)
}

func (h *LinkHandler) Redirect(c *gin.Context) {
	code := c.Param("code")

	link, err := service.GetByCode(code)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "link not found"})
		return
	}

	_ = service.IncrementClick(code)
	c.Redirect(http.StatusFound, link.OriginalURL)
}

func (h *LinkHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func toResponse(link *models.Link, baseURL string) linkResponse {
	return linkResponse{
		ID:          link.ID,
		OriginalURL: link.OriginalURL,
		ShortCode:   link.ShortCode,
		ShortURL:    baseURL + "/" + link.ShortCode,
		ClickCount:  link.ClickCount,
		CreatedAt:   link.CreatedAt.Format(time.RFC3339),
	}
}
