// Copyright 2020 Google LLC

package resources

// VersionNumber holds the build-number passed at build-time
var VersionNumber string

//GetBuildVersion provides the build version for output
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
