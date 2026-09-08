package main

import (
	"context"
	"crypto/subtle"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/coder/websocket"
)

var (
	defaultUUID = "694949f5-54c3-4113-b3c9-2d2518f770f4"
	expectedUUID [16]byte
)

func init() {
	uStr := os.Getenv("UUID")
	if uStr == "" {
		uStr = defaultUUID
	}
	cleaned := strings.ReplaceAll(uStr, "-", "")
	b, err := hex.DecodeString(cleaned)
	if err != nil || len(b) != 16 {
		log.Fatalf("Invalid UUID: %s", uStr)
	}
	copy(expectedUUID[:], b)

	net.DefaultResolver = &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := net.Dialer{Timeout: 3 * time.Second}
			return d.DialContext(ctx, "udp", "1.1.1.1:53")
		},
	}
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"ok":true,"ts":%d}`, time.Now().UnixMilli())
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			fmt.Fprintf(w, "VLESS WebSocket Service Ready\n")
			return
		}

		conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			InsecureSkipVerify: true,
			CompressionMode:    websocket.CompressionDisabled,
		})
		if err != nil {
			log.Printf("[WS] Accept error: %v", err)
			return
		}

		go handleVlessConn(conn, r.RemoteAddr)
	})

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  120 * time.Second,
		WriteTimeout: 120 * time.Second,
	}

	log.Printf("VLESS WS Microkernel Server Ready on :%s", port)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Server ListenAndServe error: %v", err)
	}
}

func handleVlessConn(ws *websocket.Conn, remoteAddr string) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	defer ws.Close(websocket.StatusNormalClosure, "done")

	nc := websocket.NetConn(ctx, ws, websocket.MessageBinary)
	defer nc.Close()

	buf := make([]byte, 4096)
	n, err := nc.Read(buf)
	if err != nil || n < 18 {
		return
	}

	if buf[0] != 0x00 {
		return
	}

	if subtle.ConstantTimeCompare(buf[1:17], expectedUUID[:]) != 1 {
		log.Printf("[VLESS] Auth failed: UUID mismatch from %s", remoteAddr)
		return
	}

	addonsLen := int(buf[17])
	off := 18 + addonsLen
	if n < off+4 {
		return
	}

	cmd := buf[off]
	off++
	port := binary.BigEndian.Uint16(buf[off : off+2])
	off += 2
	atyp := buf[off]
	off++

	var host string
	switch atyp {
	case 0x01:
		if n < off+4 {
			return
		}
		host = net.IP(buf[off : off+4]).String()
		off += 4
	case 0x02:
		if n < off+1 {
			return
		}
		dLen := int(buf[off])
		off++
		if n < off+dLen {
			return
		}
		host = string(buf[off : off+dLen])
		off += dLen
	case 0x03:
		if n < off+16 {
			return
		}
		host = net.IP(buf[off : off+16]).String()
		off += 16
	default:
		return
	}

	target := fmt.Sprintf("%s:%d", host, port)
	initialData := buf[off:n]

	log.Printf("[VLESS] CMD %d: %s -> %s", cmd, remoteAddr, target)

	if cmd != 0x01 {
		return
	}

	dialer := &net.Dialer{Timeout: 10 * time.Second}
	remoteConn, err := dialer.DialContext(ctx, "tcp", target)
	if err != nil {
		log.Printf("[VLESS] Dial error to %s: %v", target, err)
		return
	}
	defer remoteConn.Close()

	if tc, ok := remoteConn.(*net.TCPConn); ok {
		_ = tc.SetNoDelay(true)
		_ = tc.SetKeepAlive(true)
		_ = tc.SetKeepAlivePeriod(30 * time.Second)
	}

	if _, err := nc.Write([]byte{0x00, 0x00}); err != nil {
		return
	}

	if len(initialData) > 0 {
		if _, err := remoteConn.Write(initialData); err != nil {
			return
		}
	}

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		defer remoteConn.Close()
		_, _ = io.Copy(remoteConn, nc)
	}()

	go func() {
		defer wg.Done()
		defer nc.Close()
		_, _ = io.Copy(nc, remoteConn)
	}()

	wg.Wait()
}