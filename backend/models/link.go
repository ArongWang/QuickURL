package models

import "time"

type Link struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	OriginalURL string    `json:"original_url" gorm:"type:varchar(2048);not null"`
	ShortCode   string    `json:"short_code" gorm:"type:varchar(16);uniqueIndex;not null"`
	ClickCount  int       `json:"click_count" gorm:"default:0"`
	CreatedAt   time.Time `json:"created_at"`
}
