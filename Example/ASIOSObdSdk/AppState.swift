import Foundation
import ReSwift
import ASIOSObdSdk

struct AppState: StateType {
    var rpm: String = ""
    var currentLocation: Location?
    var locations: [Location] = []
    var totalEvents: Int = 0
    var totalMeters: Double = 0.0
    var velocityKmHours: Double = 0.0
}

struct RpmNumberRead: Action {
    var value: String
    init(value: String) { self.value = value }
}

struct LocationRead: Action {
    var value: Location
    init(value: Location) { self.value = value }
}

struct EventRead: Action {
    init() {}
}

struct DistanceEvaluated: Action {
    var velocityMetersPerSecond: Double
    var travelledInMeters: Double
    init(velocityMetersPerSecond: Double, travelledInMeters: Double) {
        self.velocityMetersPerSecond = velocityMetersPerSecond
        self.travelledInMeters = travelledInMeters
    }
}

func obdReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()
    switch action {
        case let action as RpmNumberRead:
            state.rpm = action.value
        case let action as LocationRead:
            state.currentLocation = action.value
            state.locations.append(action.value)
        case let action as DistanceEvaluated:
            state.velocityKmHours = action.velocityMetersPerSecond * 3.6
            state.totalMeters = state.totalMeters + action.travelledInMeters
        case let action as EventRead:
            state.totalEvents = state.totalEvents + 1
        default:
            break
    }
    return state
}
