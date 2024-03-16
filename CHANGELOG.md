# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0-build.5] - 2024-03-15
### Added
- FAQ with common questions from the Reddit testing thread added at the bottom of the About view
- Contribution section
- Privacy Policy added

## [1.0.0-build.4] - 2024-03-14
### Changed
- App Name/ Display Name changed from "Vision Vacuum" to "Spatial Vacuum" after external review rejected build 3 for the naming convention.

## [1.0.0-build.3] - 2024-03-13
### Changed
- Coin collect sound is now sourced from the Reality Kit assets.
- Multiple minor UI tweaks for responsiveness.

### Fixed
- Major BREAKING bug where after 10 sessions the game completely breaks, rendering the vacuum mesh stuck to the center of the AVP and coins no longer appear. The only fix was a fresh install before another 10 sessions, rendering it broken.
    - Fixes a race condition with setup and update tasks.
    - Also resulted in an immense performance improvement as those resources are now canceled on cleanup.

## [1.0.0-build.2] - 2024-03-09
### Changed
- About now includes small excerpt about privacy policy
- Real vacuum score entity slightly lowered
- Update README

## [1.0.0-build.1] - 2024-03-09
### Added
- Initial release