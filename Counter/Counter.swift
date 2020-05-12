import SwiftUI
import ComposableArchitecture
import Combine
import PrimeModal
import CasePaths

public struct CounterState {
    var count: Int
    var alertNthPrime: PrimeAlert?
    var isNthPrimeButtonDisabled: Bool

    public init(count: Int, alertNthPrime: PrimeAlert?, isNthPrimeButtonDisabled: Bool) {
        self.count = count
        self.alertNthPrime = alertNthPrime
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }
}

public struct CounterView: View {
  @ObservedObject var store: Store<CounterViewState, CounterViewAction>
  @State var isPrimeModalShown = false

  public init(store: Store<CounterViewState, CounterViewAction>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      TextField("Title",
        text: self.store.send({ .counter(.counterTextFieldChange($0)) },
        bind: \.count.description )
      )
      HStack {
        Button("-") { self.store.send(.counter(.decrTapped)) }
        Text("\(self.store.value.count)")
        Button("+") { self.store.send(.counter(.incrTapped)) }
      }
        Button("Is this prime?") { self.isPrimeModalShown = true }
      Button(
        "What is the \(ordinal(self.store.value.count)) prime?",
        action: self.nthPrimeButtonAction
      )
        .disabled(self.store.value.isNthPrimeButtonDisabled)
    }
    .font(.title)
    .navigationBarTitle("Counter demo")
    .sheet(isPresented: self.$isPrimeModalShown) {
      IsPrimeModalView(
        store: self.store.view(
          value: { PrimeModalState(count: $0.count, favoritePrimes: $0.favoritePrimes) },
          action: { .primeModal($0) }
        )
      )
    }
    .alert(
        item: self.store.send({ _ in .counter(.closeNthPrimeAlert) }, bind: \CounterViewState.alertNthPrime)
    ) { alert in
      Alert(
        title: Text("The \(ordinal(self.store.value.count)) prime is \(alert.prime)"),
        dismissButton: .default(Text("Ok"))
      )
    }
  }

  func nthPrimeButtonAction() {
    self.store.send(.counter(.nthPrimeButtonTapped))
  }
}

public struct CounterViewState: Equatable {
    public var count: Int
    public var favoritePrimes: [Int]
    public var alertNthPrime: PrimeAlert?
    public var isNthPrimeButtonDisabled: Bool

    public init(
        count: Int = 0,
        favoritePrimes: [Int] = [],
        alertNthPrime: PrimeAlert? = nil,
        isNthPrimeButtonDisabled: Bool = false
    ) {
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.alertNthPrime = alertNthPrime
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }

    var primeModalState: PrimeModalState {
        get {
            PrimeModalState(
                count: self.count,
                favoritePrimes: self.favoritePrimes
            )
        }
        set {
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
        }
    }

    var counterState: CounterState {
        get {
            CounterState(
                count: self.count,
                alertNthPrime: self.alertNthPrime,
                isNthPrimeButtonDisabled: self.isNthPrimeButtonDisabled
            )
        }
        set {
            self.count = newValue.count
            self.alertNthPrime = newValue.alertNthPrime
            self.isNthPrimeButtonDisabled = newValue.isNthPrimeButtonDisabled
        }
    }
}

struct CounterEnvironment {
    var nthPrime: (Int) -> Effect<Int?>
}

extension CounterEnvironment {
    static let live = CounterEnvironment(nthPrime: Counter.nthPrime)
    static let mock = CounterEnvironment(nthPrime: { _ in Effect.sync { 17 }})
}

#if DEBUG
var Current = CounterEnvironment.live
#else
let Current = CounterEnvironment.live
#endif

public enum CounterViewAction: Equatable {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
}

public enum CounterAction: Equatable {
    case decrTapped
    case incrTapped
    case counterTextFieldChange(String)
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case closeNthPrimeAlert
}

public func counterReducer(state: inout CounterState, action: CounterAction) -> [Effect<CounterAction>]{
    switch action {
    case let .counterTextFieldChange(newValue):
        guard let intValue = Int(newValue) else { return [] }
        state.count = intValue
        return []

    case .decrTapped:
        state.count -= 1

        let count = state.count
        return [
            .fireAndForget {
                print(count)
            },
            Just(CounterAction.incrTapped)
                .delay(for: 1, scheduler: DispatchQueue.main)
                .eraseToEffect()
        ]


    case .incrTapped:
        state.count += 1
        return []

    case .nthPrimeButtonTapped:
        state.isNthPrimeButtonDisabled = true

        return [
            Current.nthPrime(state.count)
                .map(CounterAction.nthPrimeResponse)
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]

    case let .nthPrimeResponse(prime):
        state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        state.isNthPrimeButtonDisabled = false
        return []

    case .closeNthPrimeAlert:
        state.alertNthPrime = nil
        return []
    }
}

public let counterViewReducer: (inout CounterViewState, CounterViewAction) -> [Effect<CounterViewAction>] = combine(
    pullback(
        counterReducer,
        value: \CounterViewState.counterState,
        action: CasePath.case(CounterViewAction.counter)
    ),
    pullback(
        primeModalReducer,
        value: \CounterViewState.primeModalState,
        action: CasePath.case(CounterViewAction.primeModal)
    )
)

public struct PrimeAlert: Identifiable, Equatable {
    let prime: Int
    public var id: Int { self.prime }
}

func ordinal(_ n: Int) -> String {
  let formatter = NumberFormatter()
  formatter.numberStyle = .ordinal
  return formatter.string(for: n) ?? ""
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    CounterView(
      store: Store(
        initialValue: CounterViewState(
            count: 3,
            favoritePrimes: [3, 5],
            alertNthPrime: nil,
            isNthPrimeButtonDisabled: false
        ),
        reducer: logging(counterViewReducer)
      )
    )
  }
}
