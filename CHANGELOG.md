# Change Log

All notable changes to this project will be documented in this file (at least to the extent possible, I am not infallible sadly).
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

**BREAKING**: If you previously depended on parsing of timezone abbreviations for non-POSIX zones,
for example, CEST, you will need to update your code to manually map that abbreviation to a valid zone
name. Timezone abbreviations are only supported if they are POSIX timezones in the Olson timezone database.

### Added
- Added CHANGELOG
- Add Date.from clause to handle Phoenix datetime_select changeset
### Changed
- Timezone abbreviation handling is now only valid for POSIX/Olson timezone names.
- Some small optimizations
### Deprecated
- N/A
### Removed
- Timezone abbreviation handling for non-POSIX/Olson timezone names
### Fixed
- Timezone abbreviation handling (was previously non-deterministic/incorrect)
- Disable tzdata's auto-update during compilation
- Usage of imperative if
