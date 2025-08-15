import Foundation

// MARK: - Weather Response Models
struct WeatherResponse: Codable {
    let coord: Coordinates
    let weather: [Weather]
    let base: String
    let main: MainWeather
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: System
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coordinates: Codable {
    let lon: Double
    let lat: Double
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp, pressure, humidity
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int
}

struct System: Codable {
    let type: Int?
    let id: Int?
    let country: String
    let sunrise: Int
    let sunset: Int
}

// MARK: - Weather Display Models
struct WeatherDisplay {
    let cityName: String
    let temperature: Double
    let feelsLike: Double
    let highTemp: Double
    let lowTemp: Double
    let humidity: Int
    let pressure: Int
    let windSpeed: Double
    let windDirection: Int
    let description: String
    let icon: String
    let sunrise: Date
    let sunset: Date
    let timezoneOffset: Int // Timezone offset in seconds from UTC
    
    init(from response: WeatherResponse) {
        self.cityName = response.name
        self.temperature = response.main.temp
        self.feelsLike = response.main.feelsLike
        self.highTemp = response.main.tempMax
        self.lowTemp = response.main.tempMin
        self.humidity = response.main.humidity
        self.pressure = response.main.pressure
        self.windSpeed = response.wind.speed
        self.windDirection = response.wind.deg
        self.description = response.weather.first?.description ?? ""
        self.icon = response.weather.first?.icon ?? ""
        self.timezoneOffset = response.timezone
        
        // Convert UTC times to city's local timezone
        let cityTimezone = TimeZone(secondsFromGMT: response.timezone) ?? TimeZone.current
        self.sunrise = Date(timeIntervalSince1970: TimeInterval(response.sys.sunrise))
        self.sunset = Date(timeIntervalSince1970: TimeInterval(response.sys.sunset))
    }
    
    // Custom initializer for previews and testing
    init(cityName: String, temperature: Double, feelsLike: Double, highTemp: Double, lowTemp: Double, humidity: Int, pressure: Int, windSpeed: Double, windDirection: Int, description: String, icon: String, sunrise: Date, sunset: Date, timezoneOffset: Int = 0) {
        self.cityName = cityName
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.humidity = humidity
        self.pressure = pressure
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.description = description
        self.icon = icon
        self.sunrise = sunrise
        self.sunset = sunset
        self.timezoneOffset = timezoneOffset
    }
}

// MARK: - Temperature Conversion
extension Double {
    func toCelsius() -> Double {
        return self - 273.15
    }
    
    func toFahrenheit() -> Double {
        return (self - 273.15) * 9/5 + 32
    }
    
    func formatTemperature(unit: TemperatureUnit) -> String {
        let temp: Double
        switch unit {
        case .celsius:
            temp = self.toCelsius()
        case .fahrenheit:
            temp = self.toFahrenheit()
        }
        return String(format: "%.1f°", temp)
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
}

// MARK: - Wind Direction Helper
extension Int {
    func windDirection() -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(Double(self) / 22.5)) % 16
        return directions[index]
    }
}
