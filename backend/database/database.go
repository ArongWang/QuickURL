package database

import (
	"fmt"
	"log"

	"shortlink/config"
	"shortlink/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func Connect(cfg *config.Config) error {
	db, err := gorm.Open(mysql.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return fmt.Errorf("connect mysql: %w", err)
	}

	if err := db.AutoMigrate(&models.Link{}); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	DB = db
	log.Println("MySQL connected and migrated")
	return nil
}
