package main

import "testing"

func TestVarsHaveDefaults(t *testing.T) {
	// The release workflow overrides these via -ldflags. The defaults exist
	// so `go test` doesn't fail in dev where ldflags isn't set.
	if commit == "" || tag == "" {
		t.Fatal("build-time vars should default to non-empty")
	}
}
