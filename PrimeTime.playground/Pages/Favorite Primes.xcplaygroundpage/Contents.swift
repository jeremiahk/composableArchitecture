import ComposableArchitecture
@testable import FavoritePrimes
import SwiftUI
import PlaygroundSupport

//Current = .mock
//
//Current.fileClient.load = { _ in
//    Effect.sync {
//        try! JSONEncoder().encode(Array(1...100))
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(
//    rootView: NavigationView {
//        FavoritePrimesView(
//            store: Store(
//                initialValue: FavoritePrimesState(favoritePrimes: [1, 2, 3]),
//                reducer: favoritePrimesReducer
//            )
//        )
//    }
//)


func pullback<GlobalValue, LocalValue, GlobalAction, LocalAction>(
    reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else {
            return []
        }

        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        return localEffects
                .map { localEffect in
                    localEffect.map { localAction in
                        var globalAction = globalAction
                        globalAction[keyPath: action] = localAction
                        return globalAction
                    }
                    .eraseToEffect()
                }
    }
}
