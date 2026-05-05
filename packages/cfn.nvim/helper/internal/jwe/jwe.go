package jwe

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"

	"github.com/go-jose/go-jose/v4"
)

func GenerateKey() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(b), nil
}

func Encrypt(plaintext []byte, base64Key string) (string, error) {
	key, err := base64.StdEncoding.DecodeString(base64Key)
	if err != nil {
		return "", fmt.Errorf("decode jwe key: %w", err)
	}
	encrypter, err := jose.NewEncrypter(
		jose.A256GCM,
		jose.Recipient{Algorithm: jose.DIRECT, Key: key},
		nil,
	)
	if err != nil {
		return "", fmt.Errorf("new encrypter: %w", err)
	}
	obj, err := encrypter.Encrypt(plaintext)
	if err != nil {
		return "", fmt.Errorf("encrypt: %w", err)
	}
	return obj.CompactSerialize()
}
