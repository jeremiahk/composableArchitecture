import ComposableArchitecture
@testable import Counter
import SwiftUI
import PlaygroundSupport

//Current = .mock

PlaygroundPage.current.liveView = UIHostingController(
    rootView: NavigationView {
        CounterView(
            store: Store(
                initialValue: CounterViewState(
                    count: 2,
                    favoritePrimes: [],
                    alertNthPrime: nil,
                    isNthPrimeButtonDisabled: false
                ),
                reducer: counterViewReducer)
        )
    }
)
