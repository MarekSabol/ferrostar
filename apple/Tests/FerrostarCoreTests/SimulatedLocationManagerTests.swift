import CoreLocation
import FerrostarCoreFFI
import XCTest
@testable import FerrostarCore

final class SimulatedLocationManagerTests: XCTestCase {
    func testInitialValuesAreNull() {
        let locationManager = SimulatedLocationProvider()
        XCTAssertNil(locationManager.lastLocation, "Initial location must be nil")
        XCTAssertNil(locationManager.lastHeading, "Initial heading must be nil")
    }

    func testSetLocation() {
        let locationManager = SimulatedLocationProvider()

        let location = CLLocation(latitude: 42, longitude: 24).userLocation
        locationManager.lastLocation = location

        XCTAssertEqual(locationManager.lastLocation, location)
    }

    func testSetHeading() {
        let locationManager = SimulatedLocationProvider()

        let heading = Heading(trueHeading: 42, accuracy: 0, timestamp: Date())
        locationManager.lastHeading = heading

        XCTAssertEqual(locationManager.lastHeading, heading)
    }

    func testDelegateSetLocation() {
        let exp = expectation(description: "The delegate should receive two location updates")
        exp.expectedFulfillmentCount = 2

        class LocationDelegate: LocationManagingDelegate {
            private let expectation: XCTestExpectation
            private var expectedLocations: [UserLocation]

            init(expectation: XCTestExpectation, expectedLocations: [UserLocation]) {
                self.expectation = expectation
                self.expectedLocations = expectedLocations
            }

            func locationManager(_: LocationProviding, didUpdateLocations locations: [UserLocation]) {
                XCTAssertEqual(locations.last, expectedLocations.removeFirst())
                expectation.fulfill()
            }

            func locationManager(_: LocationProviding, didUpdateHeading _: Heading) {
                XCTFail("Unexpected heading update")
            }

            func locationManager(_: LocationProviding, didFailWithError _: Error) {
                XCTFail("Unexpected failure")
            }
        }

        var locations = [
            CLLocation(latitude: 42, longitude: 24).userLocation,
            CLLocation(latitude: 24, longitude: 42).userLocation,
        ]

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = LocationDelegate(expectation: exp, expectedLocations: locations)
        locationManager.startUpdating()

        locationManager.lastLocation = locations.removeFirst()
        locationManager.lastLocation = locations.removeFirst()

        wait(for: [exp], timeout: 1.0)
    }

    func testDelegateSetHeading() {
        let exp = expectation(description: "The delegate should receive two heading updates")
        exp.expectedFulfillmentCount = 2

        class LocationDelegate: LocationManagingDelegate {
            private let expectation: XCTestExpectation
            private var expectedHeadings: [Heading]

            init(expectation: XCTestExpectation, expectedHeadings: [Heading]) {
                self.expectation = expectation
                self.expectedHeadings = expectedHeadings
            }

            func locationManager(_: LocationProviding, didUpdateLocations _: [UserLocation]) {
                XCTFail("Unexpected location update")
            }

            func locationManager(_: LocationProviding, didUpdateHeading newHeading: Heading) {
                XCTAssertEqual(newHeading, expectedHeadings.removeFirst())
                expectation.fulfill()
            }

            func locationManager(_: LocationProviding, didFailWithError _: Error) {
                XCTFail("Unexpected failure")
            }
        }

        var headings = [
            Heading(trueHeading: 42, accuracy: 0, timestamp: Date()),
            Heading(trueHeading: 24, accuracy: 0, timestamp: Date()),
        ]

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = LocationDelegate(expectation: exp, expectedHeadings: headings)
        locationManager.startUpdating()

        locationManager.lastHeading = headings.removeFirst()
        locationManager.lastHeading = headings.removeFirst()

        wait(for: [exp], timeout: 1.0)
    }
    
    
    // Marek addon tests
    
    func testDelegateReceivesLocationUpdates() {
        let exp = expectation(description: "The delegate should receive location updates")
        exp.expectedFulfillmentCount = 2  // Expect the fulfillment twice

        class LocationDelegate: LocationManagingDelegate {
            private let expectation: XCTestExpectation
            private var expectedLocations: [UserLocation]

            init(expectation: XCTestExpectation, expectedLocations: [UserLocation]) {
                self.expectation = expectation
                self.expectedLocations = expectedLocations
            }

            func locationManager(_: LocationProviding, didUpdateLocations locations: [UserLocation]) {
                XCTAssertEqual(locations.last, expectedLocations.removeFirst())
                expectation.fulfill()  // Fulfill each time an update is received
            }

            func locationManager(_: LocationProviding, didUpdateHeading _: Heading) {
                XCTFail("Unexpected heading update")
            }

            func locationManager(_: LocationProviding, didFailWithError _: Error) {
                XCTFail("Unexpected failure")
            }
        }

        var locations = [
            CLLocation(latitude: 42, longitude: 24).userLocation,
            CLLocation(latitude: 24, longitude: 42).userLocation,
        ]

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = LocationDelegate(expectation: exp, expectedLocations: locations)
        locationManager.startUpdating()

        locationManager.lastLocation = locations.removeFirst()
        locationManager.lastLocation = locations.removeFirst()

        wait(for: [exp], timeout: 1.0)
    }

    func testLocationUpdateFrequency() {
        let expectation = self.expectation(description: "Expect to receive multiple location updates")
        expectation.expectedFulfillmentCount = 3
        
        class LocationDelegate: LocationManagingDelegate {
            private let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func locationManager(_: LocationProviding, didUpdateLocations _: [UserLocation]) {
                expectation.fulfill()
            }

            func locationManager(_: LocationProviding, didUpdateHeading _: Heading) {}
            func locationManager(_: LocationProviding, didFailWithError _: Error) {}
        }

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = LocationDelegate(expectation: expectation)
        locationManager.startUpdating()

        // Simulate multiple location updates
        for _ in 1...3 {
            locationManager.lastLocation = CLLocation(latitude: 42, longitude: 24).userLocation
            usleep(100_000) // 100ms sleep between updates
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDelegateReceivesHeadingUpdatesOnly() {
        let expectation = self.expectation(description: "The delegate should only receive heading updates")
        expectation.expectedFulfillmentCount = 2 // Expect 2 heading updates

        class HeadingDelegate: LocationManagingDelegate {
            private let expectation: XCTestExpectation
            private var expectedHeadings: [Heading]

            init(expectation: XCTestExpectation, expectedHeadings: [Heading]) {
                self.expectation = expectation
                self.expectedHeadings = expectedHeadings
            }

            func locationManager(_: LocationProviding, didUpdateLocations _: [UserLocation]) {
                XCTFail("Unexpected location update")
            }

            func locationManager(_: LocationProviding, didUpdateHeading newHeading: Heading) {
                XCTAssertEqual(newHeading, expectedHeadings.removeFirst())
                expectation.fulfill()
            }

            func locationManager(_: LocationProviding, didFailWithError _: Error) {
                XCTFail("Unexpected failure")
            }
        }

        var headings = [
            Heading(trueHeading: 90, accuracy: 1, timestamp: Date()),
            Heading(trueHeading: 180, accuracy: 1, timestamp: Date()),
        ]

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = HeadingDelegate(expectation: expectation, expectedHeadings: headings)
        locationManager.startUpdating()

        locationManager.lastHeading = headings.removeFirst()
        locationManager.lastHeading = headings.removeFirst()

        wait(for: [expectation], timeout: 1.0)
    }

    
    func testDelegateReceivesLocationAndHeadingUpdates() {
        let locationExpectation = expectation(description: "The delegate should receive location updates")
        locationExpectation.expectedFulfillmentCount = 2

        let headingExpectation = expectation(description: "The delegate should receive heading updates")
        headingExpectation.expectedFulfillmentCount = 2

        class CombinedDelegate: LocationManagingDelegate {
            private let locationExpectation: XCTestExpectation
            private let headingExpectation: XCTestExpectation
            private var expectedLocations: [UserLocation]
            private var expectedHeadings: [Heading]

            init(locationExpectation: XCTestExpectation, headingExpectation: XCTestExpectation,
                 expectedLocations: [UserLocation], expectedHeadings: [Heading]) {
                self.locationExpectation = locationExpectation
                self.headingExpectation = headingExpectation
                self.expectedLocations = expectedLocations
                self.expectedHeadings = expectedHeadings
            }

            func locationManager(_: LocationProviding, didUpdateLocations locations: [UserLocation]) {
                XCTAssertEqual(locations.last, expectedLocations.removeFirst())
                locationExpectation.fulfill()
            }

            func locationManager(_: LocationProviding, didUpdateHeading newHeading: Heading) {
                XCTAssertEqual(newHeading, expectedHeadings.removeFirst())
                headingExpectation.fulfill()
            }

            func locationManager(_: LocationProviding, didFailWithError _: Error) {
                XCTFail("Unexpected failure")
            }
        }

        var locations = [
            CLLocation(latitude: 42, longitude: 24).userLocation,
            CLLocation(latitude: 24, longitude: 42).userLocation,
        ]

        var headings = [
            Heading(trueHeading: 90, accuracy: 1, timestamp: Date()),
            Heading(trueHeading: 180, accuracy: 1, timestamp: Date()),
        ]

        let locationManager = SimulatedLocationProvider()
        locationManager.delegate = CombinedDelegate(
            locationExpectation: locationExpectation,
            headingExpectation: headingExpectation,
            expectedLocations: locations,
            expectedHeadings: headings
        )
        locationManager.startUpdating()

        locationManager.lastLocation = locations.removeFirst()
        locationManager.lastHeading = headings.removeFirst()
        locationManager.lastLocation = locations.removeFirst()
        locationManager.lastHeading = headings.removeFirst()

        wait(for: [locationExpectation, headingExpectation], timeout: 1.0)
    }

    
    func testCoreLocationProviderStartStopUpdating() {
           let provider = CoreLocationProvider(activityType: .automotiveNavigation, allowBackgroundLocationUpdates: false)
           
           // Start and stop updating; check if no errors occur
           provider.startUpdating()
           provider.stopUpdating()
           
           // This test assumes successful execution without errors
       }
    
    
    
}
