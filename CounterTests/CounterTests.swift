import XCTest
@testable import Counter
import ComposableArchitecture
import SnapshotTesting
import SwiftUI

class CounterTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Current = .mock
    }

//    func testSnapshots() {
//        let store = Store(
//            initialValue: CounterViewState(),
//            reducer: counterViewReducer
//        )
//
//        let view = CounterView(store: store)
//
//        let vc = UIHostingController(rootView: view)
//        vc.view.frame = UIScreen.main.bounds
//
//        assertSnapshot(matching: vc, as: .image)
//
//        store.send(.counter(.incrTapped))
//        assertSnapshot(matching: vc, as: .image)
//    }

    func testIncrButtonTapped() {
        assert(
            initialValue: CounterViewState(count: 2),
            reducer: counterViewReducer,
            steps: Step(.send, .counter(.incrTapped)) { $0.count = 3 }
        )
    }

    func testDecrButtonTapped() {
        assert(
            initialValue: CounterViewState(count: 3),
            reducer: counterViewReducer,
            steps: Step(.send, .counter(.decrTapped)) { $0.count = 2 }
        )
    }

    func testNthPrimeButtonHappyFlow() {
        Current.nthPrime = { _ in Effect.sync { 3 }}

        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false
            ),
            reducer: counterViewReducer,
            steps:
            Step(.send, .counter(.nthPrimeButtonTapped)) {
                $0.isNthPrimeButtonDisabled = true
            },
            Step(.receive, .counter(.nthPrimeResponse(3))) {
                $0.isNthPrimeButtonDisabled = false
                $0.alertNthPrime = PrimeAlert(prime: 3)
            },
            Step(.send, .counter(.closeNthPrimeAlert)) {
                $0.alertNthPrime = nil
            }
        )
    }

    func testNthPrimeButtonUnhappyFlow() {
        Current.nthPrime = { _ in .sync { nil }}

        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false
            ),
            reducer: counterViewReducer,
            steps:
            Step(.send, .counter(.nthPrimeButtonTapped)) {
                $0.isNthPrimeButtonDisabled = true
            },
            Step(.receive, .counter(.nthPrimeResponse(nil))) {
                $0.isNthPrimeButtonDisabled = false
            }
        )
    }

    func testPrimeModal() {
        Current = .mock
        
        assert(
            initialValue: CounterViewState(
                count: 2,
                favoritePrimes: [3, 5]
            ),
            reducer: counterViewReducer,
            steps:
            Step(.send, .primeModal(.saveFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5, 2]
            },
            Step(.send, .primeModal(.removeFavoritePrimeTapped)) {
                $0.favoritePrimes = [3, 5]
            }
        )
    }
}
