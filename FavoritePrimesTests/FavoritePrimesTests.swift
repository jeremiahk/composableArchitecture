import XCTest
@testable import FavoritePrimes

class FavoritePrimesTests: XCTestCase {
    func testDeleteFavoritePrimes() {
        var state = FavoritePrimesState(favoritePrimes: [1, 2, 3])
        let effect = favoritePrimesReducer(state: &state, action: .deleteFavoritePrimes(IndexSet(integer: 1)))
        XCTAssertEqual(state, FavoritePrimesState(favoritePrimes: [1, 3]))
        XCTAssert(effect.isEmpty)
    }

    func testSaveFavoritePrimes() {
        var state = FavoritePrimesState(favoritePrimes: [1, 2, 3])
        let effect = favoritePrimesReducer(state: &state, action: .saveButtonTapped)
        XCTAssertEqual(state, FavoritePrimesState(favoritePrimes: [1, 2, 3]))
        XCTAssertEqual(effect.count, 1)
    }

    func testLoadFavoritePrimesFlow() {
        var state = FavoritePrimesState(favoritePrimes: [1, 2, 3])
        var effects = favoritePrimesReducer(state: &state, action: .loadButtonTapped)
        XCTAssertEqual(state, FavoritePrimesState(favoritePrimes: [1, 2, 3]))
        XCTAssertEqual(effects.count, 1)

        effects = favoritePrimesReducer(state: &state, action: .loadedFavoritePrimes([2, 31]))
        XCTAssertEqual(state, FavoritePrimesState(favoritePrimes: [2, 31]))
        XCTAssert(effects.isEmpty)
    }
}
