import SwiftUI
import ComposableArchitecture
import Combine

public struct FavoritePrimesView: View {
  @ObservedObject var store: Store<FavoritePrimesState, FavoritePrimesAction>

  public init(store: Store<FavoritePrimesState, FavoritePrimesAction>) {
    self.store = store
  }

    public var body: some View {
        List {
            ForEach(self.store.value.favoritePrimes, id: \.self) { prime in
                    Text("\(prime)")
                }
                .onDelete { indexSet in
                    self.store.send(.deleteFavoritePrimes(indexSet))
                }
        }
        .navigationBarTitle("Favorite Primes")
        .navigationBarItems(
            trailing: HStack {
            Button("Save") {
                self.store.send(.saveButtonTapped)
            }
            Button("Load") {
                self.store.send(.loadButtonTapped)
            }
        })
        .alert(isPresented:
            self.store.send(
                { .setLoadFailure($0) },
                bind: \.loadFavoritePrimesFailed
            )
        ) {
            Alert(title: Text("Error loading primes"))
        }
    }
}

public struct FavoritePrimesState: Equatable {
    public var favoritePrimes: [Int]
    var loadFavoritePrimesFailed: Bool = false

    public init(favoritePrimes: [Int]) {
        self.favoritePrimes = favoritePrimes
    }
}

public enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
    case loadedFavoritePrimes([Int])
    case loadButtonTapped
    case saveButtonTapped
    case setLoadFailure(Bool)

    var deleteFavoritePrimes: IndexSet? {
        get {
            guard case let .deleteFavoritePrimes(value) = self else { return nil }
            return value
        }
    set {
            guard case .deleteFavoritePrimes = self, let newValue = newValue else { return }
            self = .deleteFavoritePrimes(newValue)
        }
    }

    var setLoadFailure: Bool? {
        get {
            guard case let .setLoadFailure(value) = self else { return nil }
            return value
        }
        set {
            guard case .setLoadFailure = self, let newValue = newValue else { return }
            self = .setLoadFailure(newValue)
        }
    }
}

public func favoritePrimesReducer(state: inout FavoritePrimesState, action: FavoritePrimesAction) -> [Effect<FavoritePrimesAction>] {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.favoritePrimes.remove(at: index)
        }
        return []

    case let .loadedFavoritePrimes(newPrimes):
        state.favoritePrimes = newPrimes
        return []

    case .saveButtonTapped:
        return [
            Current.fileClient
                .save("favorite-primes.json", try! JSONEncoder().encode(state.favoritePrimes))
                .fireAndForget()
        ]

    case .loadButtonTapped:
        return [
            Current.fileClient
                .load("favorite-primes.json")
                .compactMap { $0 }
                .decode(type: [Int].self, decoder: JSONDecoder())
                .catch { _ in
                    Empty(completeImmediately: true)
                }
                .map(FavoritePrimesAction.loadedFavoritePrimes)
                .eraseToEffect()
        ]

    case let .setLoadFailure(failed):
        state.loadFavoritePrimesFailed = failed
        return []
    }
}

extension Publisher where Output == Never, Failure == Never {
    func fireAndForget<A>() -> Effect<A> {
        return self.map(absurd).eraseToEffect()
    }
}

func absurd<A>(_ never: Never) -> A {}

struct FileClient {
    var load: (String) -> Effect<Data?>
    var save: (String, Data) -> Effect<Never>
}

extension FileClient {
    static let live = FileClient(
        load: { fileName -> Effect<Data?> in
            return .sync {
                let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let documentsUrl = URL(fileURLWithPath: documentPath)
                let favoritePrimesUrl = documentsUrl.appendingPathComponent(fileName)
                return try? Data(contentsOf: favoritePrimesUrl)
            }
        },
        save: { (fileName, data) -> Effect<Never> in
            return .fireAndForget {
                let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let documentsUrl = URL(fileURLWithPath: documentPath)
                let favoritePrimesUrl = documentsUrl.appendingPathComponent(fileName)
                try! data.write(to: favoritePrimesUrl)
            }
        })
}

struct FavoritePrimesEnvironment {
    var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
    static let live = FavoritePrimesEnvironment(fileClient: .live)
}

#if DEBUG
extension FavoritePrimesEnvironment {
    static let mock = FavoritePrimesEnvironment(
        fileClient: FileClient(
            load: { _ in Effect<Data?>.sync {
                try! JSONEncoder().encode([2, 31])
                }
            },
            save: { _, _ in
                .fireAndForget { }
            }
        )
    )
}
#endif

#if DEBUG
var Current = FavoritePrimesEnvironment.live
#else
let Current = FavoritePrimesEnvironment.live
#endif

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritePrimesView(
                store: Store(
                    initialValue: FavoritePrimesState(favoritePrimes: [1, 2, 3]),
                    reducer: favoritePrimesReducer
                )
            )
        }
    }
}
