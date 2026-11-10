# Countries

An iOS app that lists the countries of the world. Search by name or capital.

<p align="center">
  <img src="docs/tour.gif" width="260">
</p>

<p align="center">
  <img src="docs/screenshots/list-light.png" width="200">
  <img src="docs/screenshots/list-dark.png" width="200">
  <img src="docs/screenshots/search.png" width="200">
</p>

## Run

Needs Xcode 16 or newer and an iOS 18.4 simulator.

```sh
git clone https://github.com/makambo13/Walmart.git
open Walmart/walmart.xcodeproj
```

## Test

```sh
xcodebuild test -project walmart.xcodeproj -scheme walmart \
  -destination "platform=iOS Simulator,id=<SIMULATOR_ID>"
```

Get a simulator id with `xcrun simctl list devices available`. Unit tests cover decoding, the network service and the view model. UI tests run the app on a small bundled list instead of the network (the `-UITestStubFeed` launch argument, Debug builds only).

## Structure

The view controller watches a view model. The view model loads countries through `CountryServicing`, one async function. `CountryService` implements it with `URLSession`, and the tests use fakes.

<p align="center">
  <img src="docs/architecture.png" width="800">
</p>
