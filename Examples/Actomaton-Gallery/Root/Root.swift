import Actomaton
import Counter
import Todo
import StateDiagram
import Stopwatch
import GitHub

/// Root namespace.
/// - Todo: Move to Swift Package (but compile doesn't work well in Xcode 13 beta 5)
enum Root {}

extension Root
{
    public enum Action
    {
        case changeCurrent(State.Current?)
        case debugToggle(Bool)

        case counter(Counter.Action)
        case stopwatch(Stopwatch.Action)
        case stateDiagram(StateDiagram.Action)
        case todo(Todo.Action)
        case github(GitHub.Action)
//        case lifegame(LifeGame.Action)
    }

    public struct State: Equatable
    {
        /// Current example state.
        var current: Current?

        /// Flag to show DebugRoot.
        var isDebug: Bool
    }

    public static var reducer: Reducer<Action, State, Environment>
    {
        .combine(
            debugToggleReducer(),
            previousEffectCancelReducer(),

            Counter.reducer
                .contramap(action: /Action.counter)
                .contramap(state: /State.Current.counter)
                .contramap(state: \State.current)
                .contramap(environment: { _ in () }),

            Todo.reducer
                .contramap(action: /Action.todo)
                .contramap(state: /State.Current.todo)
                .contramap(state: \State.current)
                .contramap(environment: { _ in () }),

            StateDiagram.reducer
                .contramap(action: /Action.stateDiagram)
                .contramap(state: /State.Current.stateDiagram)
                .contramap(state: \State.current)
                .contramap(environment: { _ in () }),

            Stopwatch.reducer
                .contramap(action: /Action.stopwatch)
                .contramap(state: /State.Current.stopwatch)
                .contramap(state: \State.current)
                .contramap(environment: { $0.stopwatch }),

            GitHub.reducer
                .contramap(action: /Action.github)
                .contramap(state: /State.Current.github)
                .contramap(state: \State.current)
                .contramap(environment: { $0.github })

//            LifeGame.reducer
//                .contramapEnvironment { .init(fileScheduler: $0.fileScheduler) }
//                .transform(action: .fromEnum(\.lifegame))
//                .transform(state: Lens(\.current) >>> some() >>> .fromEnum(\.lifegame))
//                .transform(id: Prism(tryGet: { $0.lifegame }, inject: EffectID.lifegame))
//                .mapQueue { _ in .defaultEffectQueue }
        )
    }

    private static func debugToggleReducer() -> Reducer<Action, State, Environment>
    {
        .init { action, state, environment in
            switch action {
            case let .debugToggle(isDebug):
                state.isDebug = isDebug
                return .empty
            default:
                return .empty
            }
        }
    }

    /// When navigating to example, cancel its previous running effects.
    private static func previousEffectCancelReducer() -> Reducer<Action, State, Environment>
    {
        .init { action, state, environment in
            switch action {
            case let .changeCurrent(current):
                state.current = current

                // Cancel previous effects when revisiting the same screen.
                //
                // NOTE:
                // We sometimes don't want to cancel previous effects at example screen's
                // `onAppear`, `onDisappear`, `init`, `deinit`, etc,
                // because we want to keep them running
                // (e.g. Stopwatch temporarily visiting child screen),
                // so `.changeCurrent` (revisiting the same screen) is
                // the best timing to cancel them.
                return current
                    .map { Effect.cancel(ids: $0.cancelAllEffectsPredicate) } ?? .empty

            default:
                return .empty
            }
        }
    }

    typealias Environment = RootEnvironment
}

// MARK: - Enum Properties

extension Root.Action
{
    var changeCurrent: Root.State.Current??
    {
        get {
            guard case let .changeCurrent(value) = self else { return nil }
            return value
        }
        set {
            guard case .changeCurrent = self, let newValue = newValue else { return }
            self = .changeCurrent(newValue)
        }
    }

    var counter: Counter.Action?
    {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }

    var stopwatch: Stopwatch.Action?
    {
        get {
            guard case let .stopwatch(value) = self else { return nil }
            return value
        }
        set {
            guard case .stopwatch = self, let newValue = newValue else { return }
            self = .stopwatch(newValue)
        }
    }

    var stateDiagram: StateDiagram.Action?
    {
        get {
            guard case let .stateDiagram(value) = self else { return nil }
            return value
        }
        set {
            guard case .stateDiagram = self, let newValue = newValue else { return }
            self = .stateDiagram(newValue)
        }
    }

    var todo: Todo.Action?
    {
        get {
            guard case let .todo(value) = self else { return nil }
            return value
        }
        set {
            guard case .todo = self, let newValue = newValue else { return }
            self = .todo(newValue)
        }
    }

    var github: GitHub.Action?
    {
        get {
            guard case let .github(value) = self else { return nil }
            return value
        }
        set {
            guard case .github = self, let newValue = newValue else { return }
            self = .github(newValue)
        }
    }

//    var lifegame: LifeGame.Action?
//    {
//        get {
//            guard case let .lifegame(value) = self else { return nil }
//            return value
//        }
//        set {
//            guard case .lifegame = self, let newValue = newValue else { return }
//            self = .lifegame(newValue)
//        }
//    }
}