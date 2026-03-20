package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/pion/webrtc/v3"
)

type Stream struct {
	ID             string
	PC             *webrtc.PeerConnection
	SenderOffer    string
	SenderAnswer   string
	ReceiverOffer  string
	ReceiverAnswer string
	CreatedAt      time.Time
	mu             sync.RWMutex
}

type WHIPServer struct {
	streams map[string]*Stream
	mu      sync.RWMutex
}

func main() {
	server := &WHIPServer{
		streams: make(map[string]*Stream),
	}

	// WHIP endpoints
	http.HandleFunc("/whip/", server.handleWHIP)
	http.HandleFunc("/whip", server.handleListStreams)

	// Health check
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	port := ":8080"
	log.Printf("🚀 WHIP Server starting on %s", port)
	log.Printf("📡 WHIP endpoint: http://localhost%s/whip/<stream-id>", port)
	log.Fatal(http.ListenAndServe(port, nil))
}

func (s *WHIPServer) handleWHIP(w http.ResponseWriter, r *http.Request) {
	// Extract stream ID from path
	streamID := r.URL.Path[len("/whip/"):]
	if streamID == "" {
		http.Error(w, "Stream ID required", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case "POST":
		s.handleCreate(w, r, streamID)
	case "PATCH":
		s.handlePatch(w, r, streamID)
	case "DELETE":
		s.handleDelete(w, r, streamID)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (s *WHIPServer) handleCreate(w http.ResponseWriter, r *http.Request, streamID string) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}

	offer := string(body)
	log.Printf("📥 WHIP Offer for stream: %s", streamID)

	s.mu.Lock()
	stream, exists := s.streams[streamID]

	if !exists {
		// Create new peer connection
		config := webrtc.Configuration{
			ICEServers: []webrtc.ICEServer{
				{URLs: []string{"stun:stun.l.google.com:19302"}},
			},
		}

		pc, err := webrtc.NewPeerConnection(config)
		if err != nil {
			log.Printf("❌ Failed to create peer connection: %v", err)
			s.mu.Unlock()
			http.Error(w, "Failed to create peer connection", http.StatusInternalServerError)
			return
		}

		stream = &Stream{
			ID:        streamID,
			PC:        pc,
			CreatedAt: time.Now(),
		}
		s.streams[streamID] = stream
		log.Printf("✅ New stream: %s", streamID)
	}
	s.mu.Unlock()

	// Set remote description
	err = stream.PC.SetRemoteDescription(webrtc.SessionDescription{
		Type: webrtc.SDPTypeOffer,
		SDP:  offer,
	})
	if err != nil {
		log.Printf("❌ Failed to set remote description: %v", err)
		http.Error(w, "Failed to set remote description", http.StatusInternalServerError)
		return
	}

	// Create answer
	answer, err := stream.PC.CreateAnswer(nil)
	if err != nil {
		log.Printf("❌ Failed to create answer: %v", err)
		http.Error(w, "Failed to create answer", http.StatusInternalServerError)
		return
	}

	err = stream.PC.SetLocalDescription(answer)
	if err != nil {
		log.Printf("❌ Failed to set local description: %v", err)
		http.Error(w, "Failed to set local description", http.StatusInternalServerError)
		return
	}

	stream.mu.Lock()
	stream.SenderOffer = offer
	stream.SenderAnswer = answer.SDP
	stream.mu.Unlock()

	// Return answer
	w.Header().Set("ETag", fmt.Sprintf("\"%s\"", streamID))
	w.Header().Set("Content-Type", "application/sdp")
	w.Header().Set("Access-Control-Expose-Headers", "ETag")
	w.WriteHeader(http.StatusCreated)
	w.Write([]byte(answer.SDP))

	log.Printf("📤 WHIP Answer sent for stream: %s", streamID)
}

func (s *WHIPServer) handlePatch(w http.ResponseWriter, r *http.Request, streamID string) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Failed to read body", http.StatusBadRequest)
		return
	}

	var candidate struct {
		Candidate string `json:"candidate"`
	}
	json.Unmarshal(body, &candidate)

	s.mu.RLock()
	stream, exists := s.streams[streamID]
	s.mu.RUnlock()

	if !exists {
		http.Error(w, "Stream not found", http.StatusNotFound)
		return
	}

	err = stream.PC.AddICECandidate(webrtc.ICECandidateInit{
		Candidate: candidate.Candidate,
	})
	if err != nil {
		log.Printf("⚠️  Failed to add ICE candidate: %v", err)
	}

	w.WriteHeader(http.StatusNoContent)
}

func (s *WHIPServer) handleDelete(w http.ResponseWriter, r *http.Request, streamID string) {
	log.Printf("🗑️  Deleting stream: %s", streamID)

	s.mu.Lock()
	if stream, exists := s.streams[streamID]; exists {
		stream.PC.Close()
		delete(s.streams, streamID)
	}
	s.mu.Unlock()

	w.WriteHeader(http.StatusOK)
}

func (s *WHIPServer) handleListStreams(w http.ResponseWriter, r *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	type StreamInfo struct {
		ID        string `json:"id"`
		CreatedAt string `json:"created_at"`
	}

	var streams []StreamInfo
	for _, stream := range s.streams {
		stream.mu.RLock()
		info := StreamInfo{
			ID:        stream.ID,
			CreatedAt: stream.CreatedAt.Format(time.RFC3339),
		}
		stream.mu.RUnlock()
		streams = append(streams, info)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"streams": streams,
	})
}
