package service

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"net/url"

	"shortlink/database"
	"shortlink/models"

	"gorm.io/gorm"
)

const codeChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func CreateLink(originalURL string) (*models.Link, error) {
	if _, err := url.ParseRequestURI(originalURL); err != nil {
		return nil, errors.New("invalid URL")
	}

	code, err := generateUniqueCode()
	if err != nil {
		return nil, err
	}

	link := models.Link{
		OriginalURL: originalURL,
		ShortCode:   code,
	}

	if err := database.DB.Create(&link).Error; err != nil {
		return nil, fmt.Errorf("create link: %w", err)
	}

	return &link, nil
}

func ListLinks() ([]models.Link, error) {
	var links []models.Link
	if err := database.DB.Order("created_at DESC").Find(&links).Error; err != nil {
		return nil, err
	}
	return links, nil
}

func GetByCode(code string) (*models.Link, error) {
	var link models.Link
	if err := database.DB.Where("short_code = ?", code).First(&link).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("link not found")
		}
		return nil, err
	}
	return &link, nil
}

func IncrementClick(code string) error {
	return database.DB.Model(&models.Link{}).
		Where("short_code = ?", code).
		UpdateColumn("click_count", gorm.Expr("click_count + ?", 1)).Error
}

func generateUniqueCode() (string, error) {
	for i := 0; i < 10; i++ {
		code, err := randomCode(6)
		if err != nil {
			return "", err
		}

		var count int64
		if err := database.DB.Model(&models.Link{}).Where("short_code = ?", code).Count(&count).Error; err != nil {
			return "", err
		}
		if count == 0 {
			return code, nil
		}
	}
	return "", errors.New("failed to generate unique code")
}

func randomCode(length int) (string, error) {
	b := make([]byte, length)
	max := big.NewInt(int64(len(codeChars)))
	for i := range b {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		b[i] = codeChars[n.Int64()]
	}
	return string(b), nil
}
