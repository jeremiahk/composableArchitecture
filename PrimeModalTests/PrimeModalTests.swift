import XCTest
@testable import PrimeModal

class PrimeModalTests: XCTestCase {
    func testSaveFavoritesPrimesTapped() {
        var state = PrimeModalState(count: 2, favoritePrimes: [3, 5])
        let effect = primeModalReducer(state: &state, action: PrimeModalAction.saveFavoritePrimeTapped)
        XCTAssertEqual(state, PrimeModalState(count: 2, favoritePrimes: [3, 5, 2]))
        XCTAssert(effect.isEmpty)
    }

    func testRemoveFavoritesPrimesTapped() {
        var state = PrimeModalState(count: 3, favoritePrimes: [3, 5])
        let effect = primeModalReducer(state: &state, action: PrimeModalAction.removeFavoritePrimeTapped)
        XCTAssertEqual(state, PrimeModalState(count: 3, favoritePrimes: [5]))
        XCTAssert(effect.isEmpty)
    }
}
