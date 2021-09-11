import Foundation
import Actomaton

// MARK: - Action

public enum Action
{
    case start
    case _didStart(Date)
    case _didResume
    case _update(start: Date, current: Date)
    case lap
    case stop
    case reset
}

// MARK: - State

public struct State: Equatable
{
    var status: Status
    var laps: [Lap]

    fileprivate var currentLapID: Int = 1
    fileprivate var previousElapsedTime: TimeInterval = 0
    fileprivate(set) var fastestLapID: Int?
    fileprivate(set) var slowestLapID: Int?

    public init(status: Status = .idle, laps: [Lap] = [])
    {
        self.status = status
        self.laps = laps
    }

    mutating func recordLap()
    {
        let elapsedTime = self.status.elapsedTime

        let lap = Lap(
            id: self.currentLapID,
            time: elapsedTime - self.previousElapsedTime
        )
        self.laps.append(lap)

        if self.laps.count >= 2 {
            var fastest = Lap(id: -1, time: .greatestFiniteMagnitude)
            var slowest = Lap(id: -1, time: .leastNormalMagnitude)
            for lap in self.laps {
                if lap.time < fastest.time { fastest = lap }
                if lap.time > slowest.time { slowest = lap }
            }
            self.fastestLapID = fastest.id
            self.slowestLapID = slowest.id
        }

        self.currentLapID += 1
        self.previousElapsedTime = elapsedTime
    }

    mutating func reset()
    {
        self.currentLapID = 0
        self.previousElapsedTime = 0
        self.laps = []
        self.status = .idle
    }

    public enum Status: Equatable
    {
        case idle
        case preparing(time: TimeInterval)

        /// - Parameter time: Accumulated time until the last pause.
        case running(time: TimeInterval, startDate: Date, currentDate: Date)

        case paused(time: TimeInterval)

        var isIdle: Bool {
            switch self {
            case .idle, .preparing:
                return true
            default:
                return false
            }
        }

        var isRunning: Bool {
            guard case .running = self else { return false }
            return true
        }

        var isPaused: Bool {
            guard case .paused = self else { return false }
            return true
        }

        var elapsedTime: TimeInterval
        {
            switch self {
            case .idle:
                return 0
            case let .preparing(time),
                let .paused(time):
                return time
            case let .running(time, startDate, currentDate):
                return time + currentDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
            }
        }
    }

    public struct Lap: Identifiable, Equatable
    {
        public var id: Int
        public var time: TimeInterval
    }
}

// MARK: - Environment

public struct Environment
{
    public let getDate: () -> Date
    public let timer: () -> AsyncStream<Date>

    public init(
        getDate: @escaping () -> Date,
        timer: @escaping () -> AsyncStream<Date>
    )
    {
        self.getDate = getDate
        self.timer = timer
    }
}

// MARK: - EffectID

public struct GetStartDateID: EffectIDProtocol {}
public struct TimerID: EffectIDProtocol {}

public func cancelAllEffectsPredicate(id: EffectID) -> Bool
{
    return id is GetStartDateID || id is TimerID
}

// MARK: - Reducer

public var reducer: Reducer<Action, State, Environment>
{
    .init { action, state, environment in
        switch (action, state.status) {
        case (.start, .idle):
            state.status = .preparing(time: 0)

            // NOTE:
            // `Date()` is a side-effect that should not be directly called inside `Reducer`,
            // so always wrap date creation inside `Publisher` to maintain this whole scope as a pure function.
            // Then, it can be replaced with a mocked effect for future improvements.
            return Effect(id: GetStartDateID()) {
                Action._didStart(environment.getDate())
            }

        case let (.start, .paused(time)):
            state.status = .preparing(time: time)

            return Effect(id: GetStartDateID()) {
                Action._didStart(environment.getDate())
            }

        case let (._didStart(date), .preparing(time)):
            state.status = .running(time: time, startDate: date, currentDate: date)

            return Effect(
                id: TimerID(),
                sequence: environment.timer()
                    .map {
                        Action._update(start: date, current: $0)
                    }
            )

        case let (._update(startDate, currentDate), .running(time, _, _)):
            state.status = .running(time: time, startDate: startDate, currentDate: currentDate)
            return .empty

        case (.lap, .running):
            state.recordLap()
            return .empty

        case let (.stop, .running(time, startDate, currentDate)):
            state.status = .paused(time: time + currentDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
            return Effect.cancel(id: TimerID())

        case (.reset, .paused):
            state.reset()
            return Effect.cancel(id: TimerID())

        default:
            return .empty
        }
    }
}