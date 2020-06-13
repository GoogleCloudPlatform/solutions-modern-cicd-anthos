// Copyright 2020 Google LLC

package resources

// VersionNumber holds the build-number passed at build-time
var VersionNumber string

// Binary holds the name of the binary set in Makefile
var Binary string

// GetBuildVersion provides the build version for output with a default fallback
func GetBuildVersion() string {
	ver := "UNKNOWN"
	if VersionNumber != "" {
		ver = VersionNumber
	}
	return ver
}

// SetBuildNumber provids a method to set the build number for testing purposes
func SetBuildNumber(number string) {
	VersionNumber = number
}

// BinaryName provides binary name for output with a default fallback
func BinaryName() string {
	ret := ""
	if Binary != "" {
		ret = Binary
	}
	return ret
}

// SetBinary is the setter for the name of the binary artifact
func SetBinary(binaryName string) {
	Binary = binaryName
}
