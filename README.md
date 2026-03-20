# ITK-6.0-ApplePlatforms

Platform-adapted packaging of ITK 6.0.0 for iOS, macOS, and visionOS.

This directory contains the platform-specific source trees and build scripts used to produce a static `ITK.xcframework` for Apple platform. I ended up needing custom scripts for each platform slice, and in some cases separate edited source files as well, because a few assumptions in the upstream source flow did not map cleanly onto Apple’s SDK. For Apple packaging, especially when the end goal is an XCFramework that can be consumed cleanly by a Swift package or app target, static packaging is often the more practical route.  I successfully built a multi-slice ITK.xcframework covering macOS, iOS, and visionOS for both devices and simulators, and integrated it into my package stack. 

To further describe what exactly was done to the source files i simply did not keep track, mostly it was bypassing test programs during configuration. just having  BUILD_TESTING=OFF and BUILD_EXAMPLES=OFF was not sufficient. 

## Layout

- `itk-ios/`
  - iOS/iOS Simulator source tree
  - `build_ios_device.sh`
  - `build_ios_sim.sh`
- `itk-macos/`
  - macOS source tree
  - `build_macos.sh`
- `itk-visionos/`
  - visionOS source tree
  - `build_visionos_device.sh`
  - `build_visionos_sim.sh`

These source trees were edited independently to keep each platform buildable.

## Top-Level Build

Run:

```bash
./build_itk_apple_xcframework.sh
```

Optional output path:

```bash
./build_itk_apple_xcframework.sh /path/to/ITK.xcframework
```

Default output:

```text
./out/ITK.xcframework
```

## What The Script Does

1. Runs the five platform build scripts.
2. Uses each platform's installed `lib/*.a` files to create one archive per slice.
3. Uses `include/ITK-6.0` as the xcframework header root so headers are flattened the way the consuming package expects.
4. Creates these slices:
   - `ios-arm64`
   - `ios-arm64-simulator`
   - `macos-arm64`
   - `xros-arm64`
   - `xros-arm64-simulator`
5. Restores `xros-arm64-simulator/Headers/itkeigen` from the visionOS device install if the simulator install omits it.

## Notes

- The packaging step intentionally uses static archives (`.a`), not dynamic frameworks.
- The header layout matters. Using `include/` directly nests headers under `Headers/ITK-6.0/...`, which does not match the current consumer include pattern.
- The `itkeigen` fallback exists because the visionOS simulator install tree did not consistently include it.
