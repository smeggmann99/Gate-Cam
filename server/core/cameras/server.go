// core/cameras/server.go
package cameras

import (
	"sync"
)

type MultiCamServer struct {
    cameras map[string]*Camera
    mu      sync.RWMutex
}

func NewMultiCamServer() *MultiCamServer {
	return &MultiCamServer{
		cameras: make(map[string]*Camera),
	}
}

func (mcs *MultiCamServer) AddCamera(cam *Camera) {
    mcs.mu.Lock()
    defer mcs.mu.Unlock()
    mcs.cameras[cam.Name] = cam
}

func (mcs *MultiCamServer) GetCamera(id string) (*Camera, bool) {
    mcs.mu.RLock()
    defer mcs.mu.RUnlock()
    cam, ok := mcs.cameras[id]
    return cam, ok
}

func (mcs *MultiCamServer) CloseAll() {
    mcs.mu.Lock()
    defer mcs.mu.Unlock()
    for _, cam := range mcs.cameras {
        cam.Stop()
    }
}