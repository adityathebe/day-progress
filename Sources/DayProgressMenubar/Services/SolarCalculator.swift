import CoreLocation
import Foundation

struct SolarTimes {
    let sunrise: Date
    let sunset: Date
}

/// Computes sunrise and sunset using the NOAA / Wikipedia sunrise equation.
/// https://en.wikipedia.org/wiki/Sunrise_equation
enum SolarCalculator {
    // Earth's axial tilt
    private static let obliquity: Double = 23.4397 * .pi / 180
    // Altitude correction: atmospheric refraction + solar disc radius ≈ -0.833°
    private static let altitudeCorrection: Double = -0.8333 * .pi / 180

    /// Returns sunrise and sunset in the device's local time zone.
    /// Returns nil for polar regions (midnight sun / polar night).
    static func solarTimes(for date: Date, coordinate: CLLocationCoordinate2D) -> SolarTimes? {
        let jd = julianDay(from: date)
        let latRad = coordinate.latitude * .pi / 180
        let lon = coordinate.longitude  // degrees, east positive

        // Julian days since J2000.0 epoch (2000-01-01T12:00:00 UTC)
        // shifted to the observer's meridian
        let n = (jd - 2_451_545.0 + 0.0008).rounded()
        let jStar = n - lon / 360.0

        // Solar mean anomaly (degrees → radians)
        let mDeg = (357.5291 + 0.98560028 * jStar)
            .truncatingRemainder(dividingBy: 360)
        let mRad = mDeg * .pi / 180

        // Equation of center
        let c = 1.9148 * sin(mRad) + 0.0200 * sin(2 * mRad) + 0.0003 * sin(3 * mRad)

        // Ecliptic longitude of the sun (degrees → radians)
        let lambdaDeg = (mDeg + c + 180 + 102.9372)
            .truncatingRemainder(dividingBy: 360)
        let lambdaRad = lambdaDeg * .pi / 180

        // Julian date of solar noon
        let jTransit =
            2_451_545.0 + jStar + 0.0053 * sin(mRad) - 0.0069 * sin(2 * lambdaRad)

        // Solar declination
        let sinDelta = sin(lambdaRad) * sin(obliquity)
        let cosDelta = sqrt(1 - sinDelta * sinDelta)  // cos(arcsin(sinDelta))

        // Hour angle at sunrise / sunset
        let cosOmega =
            (sin(altitudeCorrection) - sin(latRad) * sinDelta) / (cos(latRad) * cosDelta)

        // cosOmega outside [-1, 1] means polar day or polar night
        guard cosOmega >= -1.0, cosOmega <= 1.0 else { return nil }

        let omegaDeg = acos(cosOmega) * 180 / .pi
        let jRise = jTransit - omegaDeg / 360
        let jSet = jTransit + omegaDeg / 360

        let sunrise = Date(timeIntervalSince1970: (jRise - 2_440_587.5) * 86400)
        let sunset = Date(timeIntervalSince1970: (jSet - 2_440_587.5) * 86400)

        return SolarTimes(sunrise: sunrise, sunset: sunset)
    }

    // Unix epoch (1970-01-01T00:00:00 UTC) = JD 2 440 587.5
    private static func julianDay(from date: Date) -> Double {
        date.timeIntervalSince1970 / 86400 + 2_440_587.5
    }
}
