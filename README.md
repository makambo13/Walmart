# Countries

A UIKit app that lists the countries of the world and lets you search them by name or capital. It loads one JSON feed, shows it a page at a time, and handles loading, empty, error and retry states.

<p align="center">
  <img src="docs/tour.gif" alt="Screen recording: the list loads, scrolls, and is searched by name and capital" width="270">
</p>

## Features

- Country list with name, region, ISO code and capital, loaded with `async`/`await`
- Search by name or capital, ignoring case and accents (`cote` finds Côte d'Ivoire)
- Pages of 20 rows that grow as you scroll
- Loading, no results, and error states with a Retry button, plus pull to refresh
- Light and dark mode, Dynamic Type, and one VoiceOver element per row

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/list-light.png" width="220"><br><sub>List</sub></td>
    <td align="center"><img src="docs/screenshots/list-dark.png" width="220"><br><sub>Dark mode</sub></td>
    <td align="center"><img src="docs/screenshots/search.png" width="220"><br><sub>Search by capital</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/no-results.png" width="220"><br><sub>No results</sub></td>
    <td align="center"><img src="docs/screenshots/error.png" width="220"><br><sub>Error with Retry</sub></td>
    <td align="center"><img src="docs/screenshots/large-text.png" width="220"><br><sub>Larger text</sub></td>
  </tr>
</table>

## Architecture

<p align="center">
  <img src="docs/architecture.png" alt="Architecture diagram" width="900">
</p>

- **`CountryServicing`** is a one-method protocol: `func fetchCountries() async throws -> [Country]`. `CountryService` implements it with `URLSession`; tests and UI tests use doubles.
- **`CountryListViewModel`** is `@MainActor` and `@Observable`. It owns load state, the search text and the visible rows, so the view controller holds no logic.
- **`CountryListViewController`** re-renders through `withObservationTracking`. It shows empty states with `UIContentUnavailableView`.
- **`Country`** and the other models are `Sendable` structs. Errors are one typed enum, `CountryServiceError`, with readable messages.
- The project builds in Swift 6 language mode with no concurrency warnings.

## Requirements

- Xcode 16 or later (built and tested with Xcode 27.2)
- iOS 18.4 or later

## Run it

```sh
git clone https://github.com/makambo13/Walmart.git
open Walmart/walmart.xcodeproj
```

Choose the `walmart` scheme and an iPhone simulator, then press Run.

## Tests

```sh
# list simulators, then pick one id
xcrun simctl list devices available

xcodebuild test -project walmart.xcodeproj -scheme walmart \
  -destination "platform=iOS Simulator,id=<SIMULATOR_ID>"
```

**Unit tests** (Swift Testing, `walmartTests`)

| Area | What is checked |
| --- | --- |
| Decoding | full records, records with only required fields, unknown fields, missing required fields |
| Service | request method, URL and headers; HTTP 404/500/503; malformed JSON; wrong JSON shape; offline errors. A `URLProtocol` stub keeps the network out of it. |
| View model | first page, paging with no repeats or gaps, search by name and capital, accents, whitespace, no results, clearing search, duplicate codes, failed load, Retry, a failed refresh keeping the list, and a second load while one is running |
| Row view model | title text, `N/A` for a missing capital |

**UI tests** (XCUITest, `walmartUITests`) run the real app against a bundled sample feed: launch and list, scrolling to load later pages, search by name, capital and accents, no results, cancelling search, and the error screen with Retry.

### Launch arguments (Debug builds only)

| Argument | Effect |
| --- | --- |
| `-UITestStubFeed` | Serves the bundled `StubCountries.json` instead of the network |
| `-UITestFailFirstLoad` | Same feed, but the first request fails, so the error screen shows |

## Using the app from the command line

`scripts/record-tour.sh` drives the app without touching the Xcode UI. `xcrun simctl` boots the simulator, sets a clean status bar, installs and launches the app, switches light and dark mode and text size, and takes screenshots. While `simctl` records the screen, `xcodebuild` runs `GuidedTourUITests`, a paced walk through scrolling, searching and the empty state.

```sh
scripts/record-tour.sh <SIMULATOR_ID> captures
```

`simctl` has no tap or typing command, so the taps and keystrokes come from XCUITest. Screenshots and the recording in this README were made this way.

## Project layout

```
walmart/
  App/           AppDelegate, SceneDelegate, AppEnvironment (picks the service)
  Models/        Country
  Services/      CountryServicing, CountryService, StubCountryService (Debug)
  ViewModels/    CountryListViewModel, CountryRowViewModel
  Views/         CountryListViewController, CountryCell
  Resources/     StubCountries.json
walmartTests/    unit tests and test doubles
walmartUITests/  UI tests and the guided tour
scripts/         record-tour.sh
docs/            README images
```
