import Foundation
import Combine
import os.log
import Network
import CoreLocation

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    init() {
        // Check if user has set a preference
        if let savedTheme = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            isDarkMode = savedTheme
        } else {
            // Default to light mode
            isDarkMode = false
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

// MARK: - Weather Service
class WeatherService: ObservableObject {
    @Published var weather: WeatherDisplay?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = Config.openWeatherMapAPIKey
    private let baseURL = Config.openWeatherMapBaseURL
    private let logger = Logger(subsystem: "com.weatherapp", category: "WeatherService")
    private let networkMonitor = NWPathMonitor()
    private var isNetworkReachable = false
    let locationManager = LocationManager()
    
    init() {
        // Test temperature conversions on initialization
        testTemperatureConversions()
        
        // Setup network monitoring
        setupNetworkMonitoring()
        
        // Test API connectivity
        testAPIConnectivity()
        
        // Connect location updates to weather fetching
        locationManager.onLocationReceived = { [weak self] location in
            print("📍 [DEBUG] WeatherService: Location received, fetching weather...")
            self?.fetchWeatherByCoordinates(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkReachable = path.status == .satisfied
                print("🌐 [DEBUG] Network status: \(path.status)")
                print("🌐 [DEBUG] Network reachable: \(self?.isNetworkReachable ?? false)")
                
                if path.status == .satisfied {
                    print("✅ [DEBUG] Network connection is available")
                } else {
                    print("❌ [DEBUG] Network connection is unavailable")
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global())
    }
    
    private func testAPIConnectivity() {
        print("🧪 [DEBUG] Testing API connectivity...")
        
        // Test basic URL construction
        let testURL = "\(baseURL)?q=London&appid=\(apiKey)"
        print("🧪 [DEBUG] Test URL: \(testURL)")
        
        // Test if URL is valid
        if let url = URL(string: testURL) {
            print("✅ [DEBUG] URL is valid")
            print("🧪 [DEBUG] URL components:")
            print("   - Scheme: \(url.scheme ?? "nil")")
            print("   - Host: \(url.host ?? "nil")")
            print("   - Path: \(url.path)")
            print("   - Query: \(url.query ?? "nil")")
        } else {
            print("❌ [DEBUG] URL is invalid")
        }
        
        // Test API key format
        print("🧪 [DEBUG] API Key length: \(apiKey.count)")
        print("🧪 [DEBUG] API Key starts with: \(String(apiKey.prefix(4)))...")
        print("🧪 [DEBUG] API Key ends with: ...\(String(apiKey.suffix(4)))")
        
        // Test if we can reach the API host
        if let host = URL(string: baseURL)?.host {
            print("🧪 [DEBUG] Testing connection to host: \(host)")
            
            let hostMonitor = NWPathMonitor()
            hostMonitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    print("✅ [DEBUG] Can reach host: \(host)")
                } else {
                    print("❌ [DEBUG] Cannot reach host: \(host)")
                }
                hostMonitor.cancel()
            }
            hostMonitor.start(queue: DispatchQueue.global())
        }
    }
    
    // Test function to manually test the API
    func testAPIWithKnownCity() {
        print("\n🧪 [DEBUG] MANUAL API TEST - Testing with 'London'")
        fetchWeather(for: "London")
    }
    
    private func testTemperatureConversions() {
        print("🧪 [DEBUG] Testing temperature conversions...")
        
        let testTempK = 293.15 // 20°C
        print("🧪 [DEBUG] Test temperature: \(testTempK)K")
        print("🧪 [DEBUG] To Celsius: \(testTempK.toCelsius())°C")
        print("🧪 [DEBUG] To Fahrenheit: \(testTempK.toFahrenheit())°F")
        
        let testTempK2 = 273.15 // 0°C
        print("🧪 [DEBUG] Test temperature: \(testTempK2)K")
        print("🧪 [DEBUG] To Celsius: \(testTempK2.toCelsius())°C")
        print("🧪 [DEBUG] To Fahrenheit: \(testTempK2.toFahrenheit())°F")
        
        let testTempK3 = 310.15 // 37°C
        print("🧪 [DEBUG] Test temperature: \(testTempK3)K")
        print("🧪 [DEBUG] To Celsius: \(testTempK3.toCelsius())°C")
        print("🧪 [DEBUG] To Fahrenheit: \(testTempK3.toFahrenheit())°F")
    }
    
    func fetchWeather(for city: String) {
        print("\n" + String(repeating: "=", count: 50))
        print("🚀 [DEBUG] STARTING NEW WEATHER REQUEST")
        print(String(repeating: "=", count: 50))
        
        isLoading = true
        errorMessage = nil
        
        // Check network connectivity first
        guard isNetworkReachable else {
            print("❌ [DEBUG] Network is not reachable!")
            errorMessage = "No internet connection available"
            isLoading = false
            return
        }
        
        logger.info("🌤️ Fetching weather for city: \(city)")
        print("🌤️ [DEBUG] Fetching weather for city: \(city)")
        
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("❌ Failed to encode city name: \(city)")
            print("❌ [DEBUG] Failed to encode city name: \(city)")
            errorMessage = "Invalid city name"
            isLoading = false
            return
        }
        
        let urlString = "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)"
        logger.info("🔗 API URL: \(urlString)")
        print("🔗 [DEBUG] API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("❌ Invalid URL: \(urlString)")
            print("❌ [DEBUG] Invalid URL: \(urlString)")
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        print("🚀 [DEBUG] Starting API request...")
        print("🚀 [DEBUG] Request URL: \(url)")
        print("🚀 [DEBUG] Request method: GET")
        print("🚀 [DEBUG] Request headers: Default")
        
        let startTime = Date()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                print("⏱️ [DEBUG] Request completed in: \(String(format: "%.2f", duration)) seconds")
                
                if let error = error {
                    self?.logger.error("❌ Network error: \(error.localizedDescription)")
                    print("❌ [DEBUG] Network error: \(error.localizedDescription)")
                    print("❌ [DEBUG] Error domain: \(error._domain)")
                    print("❌ [DEBUG] Error code: \(error._code)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    self?.logger.info("📡 HTTP Response Status: \(httpResponse.statusCode)")
                    print("📡 [DEBUG] HTTP Response Status: \(httpResponse.statusCode)")
                    print("📡 [DEBUG] HTTP Response Headers:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("   \(key): \(value)")
                    }
                    
                    // Check for specific HTTP status codes
                    switch httpResponse.statusCode {
                    case 200:
                        print("✅ [DEBUG] HTTP 200 - Success")
                    case 401:
                        print("❌ [DEBUG] HTTP 401 - Unauthorized (check API key)")
                        self?.errorMessage = "API key is invalid or expired"
                        return
                    case 404:
                        print("❌ [DEBUG] HTTP 404 - City not found")
                        self?.errorMessage = "City not found"
                        return
                    case 429:
                        print("❌ [DEBUG] HTTP 429 - Rate limit exceeded")
                        self?.errorMessage = "API rate limit exceeded"
                        return
                    case 500...599:
                        print("❌ [DEBUG] HTTP \(httpResponse.statusCode) - Server error")
                        self?.errorMessage = "Weather service is temporarily unavailable"
                        return
                    default:
                        print("⚠️ [DEBUG] HTTP \(httpResponse.statusCode) - Unexpected status")
                    }
                } else {
                    print("⚠️ [DEBUG] No HTTP response received")
                }
                
                guard let data = data else {
                    self?.logger.error("❌ No data received")
                    print("❌ [DEBUG] No data received")
                    self?.errorMessage = "No data received"
                    return
                }
                
                self?.logger.info("📦 Received data size: \(data.count) bytes")
                print("📦 [DEBUG] Received data size: \(data.count) bytes")
                
                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    self?.logger.info("📄 Raw API Response: \(jsonString)")
                    print("📄 [DEBUG] Raw API Response:")
                    print(jsonString)
                    
                    // Check if response looks like JSON
                    if jsonString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
                        print("✅ [DEBUG] Response appears to be valid JSON")
                    } else {
                        print("⚠️ [DEBUG] Response doesn't look like JSON")
                    }
                } else {
                    print("❌ [DEBUG] Could not decode response as UTF-8 string")
                }
                
                do {
                    let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    self?.logger.info("✅ Successfully decoded weather response")
                    print("✅ [DEBUG] Successfully decoded weather response")
                    print("✅ [DEBUG] City: \(response.name)")
                    print("✅ [DEBUG] Country: \(response.sys.country)")
                    print("✅ [DEBUG] Weather ID: \(response.weather.first?.id ?? 0)")
                    print("✅ [DEBUG] Weather main: \(response.weather.first?.main ?? "N/A")")
                    print("✅ [DEBUG] Weather description: \(response.weather.first?.description ?? "N/A")")
                    
                    // Log API response timestamp if available
                    let responseDate = Date(timeIntervalSince1970: TimeInterval(response.dt))
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .medium
                    print("🕐 [DEBUG] API Response Timestamp: \(formatter.string(from: responseDate))")
                    print("🕐 [DEBUG] Current Local Time: \(formatter.string(from: Date()))")
                    
                    let timeDifference = Date().timeIntervalSince(responseDate)
                    print("🕐 [DEBUG] Data Age: \(String(format: "%.0f", timeDifference/60)) minutes old")
                    
                    // Log exact location data
                    print("📍 [DEBUG] Exact Coordinates: lat=\(response.coord.lat), lon=\(response.coord.lon)")
                    print("📍 [DEBUG] City Name: \(response.name)")
                    print("📍 [DEBUG] Country: \(response.sys.country)")
                    print("📍 [DEBUG] Timezone Offset: \(response.timezone) seconds")
                    
                    // Log timezone conversion details
                    let cityTimezone = TimeZone(secondsFromGMT: response.timezone) ?? TimeZone.current
                    let sunriseUTC = Date(timeIntervalSince1970: TimeInterval(response.sys.sunrise))
                    let sunsetUTC = Date(timeIntervalSince1970: TimeInterval(response.sys.sunset))
                    
                    // Show UTC times
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    print("🕐 [DEBUG] Sunrise (UTC): \(formatter.string(from: sunriseUTC))")
                    print("🕐 [DEBUG] Sunset (UTC): \(formatter.string(from: sunsetUTC))")
                    
                    // Show city local times
                    formatter.timeZone = cityTimezone
                    print("🕐 [DEBUG] Sunrise (City Local): \(formatter.string(from: sunriseUTC))")
                    print("🕐 [DEBUG] Sunset (City Local): \(formatter.string(from: sunsetUTC))")
                    print("🕐 [DEBUG] City Timezone: \(cityTimezone.identifier)")
                    
                    self?.logger.info("🌡️ Temperature (K): \(response.main.temp)")
                    print("🌡️ [DEBUG] Temperature (K): \(response.main.temp)")
                    self?.logger.info("🌡️ Temperature (C): \(response.main.temp.toCelsius())")
                    print("🌡️ [DEBUG] Temperature (C): \(response.main.temp.toCelsius())")
                    self?.logger.info("🌡️ Temperature (F): \(response.main.temp.toFahrenheit())")
                    print("🌡️ [DEBUG] Temperature (F): \(response.main.temp.toFahrenheit())")
                    
                    // Additional debugging for temperature discrepancy
                    let tempF = response.main.temp.toFahrenheit()
                    let tempC = response.main.temp.toCelsius()
                    print("🔍 [DEBUG] TEMPERATURE ANALYSIS:")
                    print("🔍 [DEBUG] Raw Kelvin: \(response.main.temp)K")
                    print("🔍 [DEBUG] Converted Celsius: \(String(format: "%.2f", tempC))°C")
                    print("🔍 [DEBUG] Converted Fahrenheit: \(String(format: "%.2f", tempF))°F")
                    print("🔍 [DEBUG] Expected: ~72°F, Actual: \(String(format: "%.1f", tempF))°F")
                    print("🔍 [DEBUG] Difference: \(String(format: "%.1f", 72 - tempF))°F")
                    
                    self?.logger.info("🌡️ Feels like (K): \(response.main.feelsLike)")
                    print("🌡️ [DEBUG] Feels like (K): \(response.main.feelsLike)")
                    self?.logger.info("🌡️ High temp (K): \(response.main.tempMax)")
                    print("🌡️ [DEBUG] High temp (K): \(response.main.tempMax)")
                    self?.logger.info("🌡️ Low temp (K): \(response.main.tempMin)")
                    print("🌡️ [DEBUG] Low temp (K): \(response.main.tempMin)")
                    self?.logger.info("💧 Humidity: \(response.main.humidity)%")
                    print("💧 [DEBUG] Humidity: \(response.main.humidity)%")
                    self?.logger.info("🌪️ Wind speed: \(response.wind.speed) m/s")
                    print("🌪️ [DEBUG] Wind speed: \(response.wind.speed) m/s")
                    self?.logger.info("🌪️ Wind direction: \(response.wind.deg)°")
                    print("🌪️ [DEBUG] Wind direction: \(response.wind.deg)°")
                    self?.logger.info("☁️ Weather description: \(response.weather.first?.description ?? "N/A")")
                    print("☁️ [DEBUG] Weather description: \(response.weather.first?.description ?? "N/A")")
                    
                    // Create weather display object
                    let weatherDisplay = WeatherDisplay(from: response)
                    
                    // Fetch air quality and forecast data, then update the display
                    let group = DispatchGroup()
                    var airQualityIndex = 3
                    var hourlyForecasts: [HourlyForecast] = []
                    
                    group.enter()
                    self?.fetchAirQuality(lat: response.coord.lat, lon: response.coord.lon) { aqi in
                        airQualityIndex = aqi
                        group.leave()
                    }
                    
                    group.enter()
                    self?.fetchForecast(lat: response.coord.lat, lon: response.coord.lon) { forecasts in
                        hourlyForecasts = forecasts
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        // Create a new WeatherDisplay with all the data
                        let updatedWeatherDisplay = WeatherDisplay(
                            cityName: weatherDisplay.cityName,
                            temperature: weatherDisplay.temperature,
                            feelsLike: weatherDisplay.feelsLike,
                            highTemp: weatherDisplay.highTemp,
                            lowTemp: weatherDisplay.lowTemp,
                            humidity: weatherDisplay.humidity,
                            airQualityIndex: airQualityIndex,
                            windSpeed: weatherDisplay.windSpeed,
                            windDirection: weatherDisplay.windDirection,
                            description: weatherDisplay.description,
                            icon: weatherDisplay.icon,
                            sunrise: weatherDisplay.sunrise,
                            sunset: weatherDisplay.sunset,
                            timezoneOffset: weatherDisplay.timezoneOffset,
                            hourlyForecast: hourlyForecasts
                        )
                        
                        self?.weather = updatedWeatherDisplay
                        self?.isLoading = false
                        self?.errorMessage = nil
                    }
                    
                    self?.logger.info("🎉 Weather data successfully processed and displayed")
                    print("🎉 [DEBUG] Weather data successfully processed and displayed")
                    
                } catch {
                    self?.logger.error("❌ Failed to decode weather response: \(error)")
                    print("❌ [DEBUG] Failed to decode weather response: \(error)")
                    print("❌ [DEBUG] Decoding error details: \(error.localizedDescription)")
                    
                    // Check if it's an API error response
                    if let errorResponse = try? JSONDecoder().decode(WeatherErrorResponse.self, from: data) {
                        self?.logger.error("❌ API Error: \(errorResponse.message)")
                        print("❌ [DEBUG] API Error: \(errorResponse.message)")
                        print("❌ [DEBUG] API Error Code: \(errorResponse.cod)")
                        self?.errorMessage = errorResponse.message
                    } else {
                        self?.logger.error("❌ Unknown parsing error")
                        print("❌ [DEBUG] Unknown parsing error")
                        print("❌ [DEBUG] This might be a malformed JSON response")
                        self?.errorMessage = "Failed to parse weather data"
                    }
                }
                
                print(String(repeating: "=", count: 50))
                print("🏁 [DEBUG] WEATHER REQUEST COMPLETED")
                print(String(repeating: "=", count: 50) + "\n")
            }
        }.resume()
    }
    
    func fetchWeatherByCoordinates(lat: Double, lon: Double) {
        isLoading = true
        errorMessage = nil
        
        logger.info("📍 Fetching weather for coordinates: lat=\(lat), lon=\(lon)")
        
        let urlString = "\(baseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        logger.info("🔗 API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("❌ Invalid URL: \(urlString)")
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        logger.info("🚀 Starting API request for coordinates...")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.logger.error("❌ Network error: \(error.localizedDescription)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    self?.logger.info("📡 HTTP Response Status: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    self?.logger.error("❌ No data received")
                    self?.errorMessage = "No data received"
                    return
                }
                
                self?.logger.info("📦 Received data size: \(data.count) bytes")
                
                // Log raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    self?.logger.info("📄 Raw API Response: \(jsonString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    self?.logger.info("✅ Successfully decoded weather response for coordinates")
                    self?.logger.info("🌡️ Temperature (K): \(response.main.temp)")
                    self?.logger.info("🌡️ Temperature (C): \(response.main.temp.toCelsius())")
                    self?.logger.info("🌡️ Temperature (F): \(response.main.temp.toFahrenheit())")
                    
                    // Create weather display object
                    let weatherDisplay = WeatherDisplay(from: response)
                    
                    // Fetch air quality data and update the display
                    self?.fetchAirQuality(lat: response.coord.lat, lon: response.coord.lon) { aqi in
                        DispatchQueue.main.async {
                            // Create a new WeatherDisplay with the air quality data
                            let updatedWeatherDisplay = WeatherDisplay(
                                cityName: weatherDisplay.cityName,
                                temperature: weatherDisplay.temperature,
                                feelsLike: weatherDisplay.feelsLike,
                                highTemp: weatherDisplay.highTemp,
                                lowTemp: weatherDisplay.lowTemp,
                                humidity: weatherDisplay.humidity,
                                airQualityIndex: aqi,
                                windSpeed: weatherDisplay.windSpeed,
                                windDirection: weatherDisplay.windDirection,
                                description: weatherDisplay.description,
                                icon: weatherDisplay.icon,
                                sunrise: weatherDisplay.sunrise,
                                sunset: weatherDisplay.sunset,
                                timezoneOffset: weatherDisplay.timezoneOffset
                            )
                            
                            self?.weather = updatedWeatherDisplay
                            self?.isLoading = false
                            self?.errorMessage = nil
                        }
                    }
                    
                    self?.logger.info("🎉 Weather data successfully processed and displayed")
                    
                } catch {
                    self?.logger.error("❌ Failed to decode weather response: \(error)")
                    
                    if let errorResponse = try? JSONDecoder().decode(WeatherErrorResponse.self, from: data) {
                        self?.logger.error("❌ API Error: \(errorResponse.message)")
                        self?.errorMessage = errorResponse.message
                    } else {
                        self?.logger.error("❌ Unknown parsing error")
                        self?.errorMessage = "Failed to parse weather data"
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Air Quality Methods
    
    private func fetchAirQuality(lat: Double, lon: Double, completion: @escaping (Int) -> Void) {
        let urlString = "\(Config.airQualityBaseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ [DEBUG] Invalid air quality URL")
            completion(3) // Default to moderate air quality
            return
        }
        
        print("🌬️ [DEBUG] Fetching air quality from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [DEBUG] Air quality fetch error: \(error.localizedDescription)")
                    completion(3) // Default to moderate air quality
                    return
                }
                
                guard let data = data else {
                    print("❌ [DEBUG] No air quality data received")
                    completion(3) // Default to moderate air quality
                    return
                }
                
                do {
                    let airQualityResponse = try JSONDecoder().decode(AirQualityResponse.self, from: data)
                    if let firstReading = airQualityResponse.list.first {
                        let aqi = firstReading.main.aqi
                        print("🌬️ [DEBUG] Air Quality Index: \(aqi)")
                        completion(aqi)
                    } else {
                        print("❌ [DEBUG] No air quality readings in response")
                        completion(3) // Default to moderate air quality
                    }
                } catch {
                    print("❌ [DEBUG] Air quality JSON decode error: \(error)")
                    completion(3) // Default to moderate air quality
                }
            }
        }.resume()
    }
    
    // MARK: - Forecast Methods
    
    private func fetchForecast(lat: Double, lon: Double, completion: @escaping ([HourlyForecast]) -> Void) {
        let urlString = "\(Config.forecastBaseURL)?lat=\(lat)&lon=\(lon)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ [DEBUG] Invalid forecast URL")
            completion([])
            return
        }
        
        print("📊 [DEBUG] Fetching forecast from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [DEBUG] Forecast fetch error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let data = data else {
                    print("❌ [DEBUG] No forecast data received")
                    completion([])
                    return
                }
                
                do {
                    let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)
                    print("📊 [DEBUG] Raw forecast response: \(forecastResponse.list.count) data points")
                    
                    // Process forecast data to get the 5 key time points we need for the chart
                    let processedForecasts = self.processForecastForChart(
                        forecastData: forecastResponse.list,
                        timezoneOffset: forecastResponse.city.timezone
                    )
                    
                    print("📊 [DEBUG] Processed \(processedForecasts.count) chart data points")
                    completion(processedForecasts)
                } catch {
                    print("❌ [DEBUG] Forecast JSON decode error: \(error)")
                    completion([])
                }
            }
        }.resume()
    }
    
    // MARK: - Chart Data Processing
    
    private func processForecastForChart(forecastData: [ForecastItem], timezoneOffset: Int) -> [HourlyForecast] {
        let now = Date()
        let calendar = Calendar.current
        
        // We need 5 data points: 12h ago, 6h ago, current, 6h ahead, 12h ahead
        var chartData: [HourlyForecast] = []
        
        // 1. 12 hours ago
        if let twelveHoursAgo = calendar.date(byAdding: .hour, value: -12, to: now) {
            let temp = getTemperatureForTime(twelveHoursAgo, from: forecastData, timezoneOffset: timezoneOffset)
            chartData.append(HourlyForecast(time: twelveHoursAgo, temperature: temp))
        }
        
        // 2. 6 hours ago
        if let sixHoursAgo = calendar.date(byAdding: .hour, value: -6, to: now) {
            let temp = getTemperatureForTime(sixHoursAgo, from: forecastData, timezoneOffset: timezoneOffset)
            chartData.append(HourlyForecast(time: sixHoursAgo, temperature: temp))
        }
        
        // 3. Current time (use current weather temperature)
        let currentTemp = getCurrentTemperature(from: forecastData, timezoneOffset: timezoneOffset)
        chartData.append(HourlyForecast(time: now, temperature: currentTemp))
        
        // 4. 6 hours ahead
        if let sixHoursAhead = calendar.date(byAdding: .hour, value: 6, to: now) {
            let temp = getTemperatureForTime(sixHoursAhead, from: forecastData, timezoneOffset: timezoneOffset)
            chartData.append(HourlyForecast(time: sixHoursAhead, temperature: temp))
        }
        
        // 5. 12 hours ahead
        if let twelveHoursAhead = calendar.date(byAdding: .hour, value: 12, to: now) {
            let temp = getTemperatureForTime(twelveHoursAhead, from: forecastData, timezoneOffset: timezoneOffset)
            chartData.append(HourlyForecast(time: twelveHoursAhead, temperature: temp))
        }
        
        print("📊 [DEBUG] Chart data points:")
        for (index, forecast) in chartData.enumerated() {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            print("   \(index): \(formatter.string(from: forecast.time)) - \(forecast.temperature.toCelsius())°C")
        }
        
        return chartData
    }
    
    private func getTemperatureForTime(_ targetTime: Date, from forecastData: [ForecastItem], timezoneOffset: Int) -> Double {
        // Find the closest forecast data point to the target time
        var closestItem: ForecastItem?
        var smallestTimeDifference = Double.greatestFiniteMagnitude
        
        for item in forecastData {
            let itemTime = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let timeDifference = abs(targetTime.timeIntervalSince(itemTime))
            
            if timeDifference < smallestTimeDifference {
                smallestTimeDifference = timeDifference
                closestItem = item
            }
        }
        
        // Return the temperature from the closest forecast item, or a default if none found
        return closestItem?.main.temp ?? 293.15 // Default to 20°C (293.15K)
    }
    
    private func getCurrentTemperature(from forecastData: [ForecastItem], timezoneOffset: Int) -> Double {
        let now = Date()
        return getTemperatureForTime(now, from: forecastData, timezoneOffset: timezoneOffset)
    }
    
    // MARK: - Location Services
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - API Methods
}

// MARK: - Error Response Model
struct WeatherErrorResponse: Codable {
    let cod: String
    let message: String
}

// MARK: - Location Manager for getting current location
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentCity: String = "Getting location..."
    
    // Add completion handler for location updates
    var onLocationReceived: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Better for city-level accuracy
        locationManager.distanceFilter = 1000 // Update location when user moves 1km
        
        // Check current authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocation() {
        print("📍 [DEBUG] Requesting location...")
        currentCity = "Getting location..."
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 [DEBUG] Location received: \(location.coordinate)")
        print("📍 [DEBUG] Location accuracy: \(location.horizontalAccuracy) meters")
        print("📍 [DEBUG] Location timestamp: \(location.timestamp)")
        
        // Only use location if it's recent and accurate
        let timeSinceUpdate = Date().timeIntervalSince(location.timestamp)
        if timeSinceUpdate < 30 && location.horizontalAccuracy <= 1000 {
            self.location = location
            print("📍 [DEBUG] Location accepted and stored")
            
            // Reverse geocode to get city name
            reverseGeocodeLocation(location)
            
            // Notify the weather service that location was received
            onLocationReceived?(location)
        } else {
            print("📍 [DEBUG] Location rejected - too old or inaccurate")
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        print("📍 [DEBUG] Starting reverse geocoding for coordinates: \(location.coordinate)")
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("📍 [DEBUG] Reverse geocoding error: \(error.localizedDescription)")
                    self?.currentCity = "Location error"
                    return
                }
                
                if let placemarks = placemarks, !placemarks.isEmpty {
                    let placemark = placemarks[0]
                    print("📍 [DEBUG] Received placemark: \(placemark)")
                    
                    // Try to get the most specific city name
                    let city = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea ?? "Unknown City"
                    let state = placemark.administrativeArea ?? ""
                    let country = placemark.country ?? ""
                    _ = placemark.postalCode ?? ""
                    
                    print("📍 [DEBUG] Placemark details:")
                    print("   - Locality: \(placemark.locality ?? "nil")")
                    print("   - SubLocality: \(placemark.subLocality ?? "nil")")
                    print("   - AdministrativeArea: \(placemark.administrativeArea ?? "nil")")
                    print("   - Country: \(placemark.country ?? "nil")")
                    print("   - PostalCode: \(placemark.postalCode ?? "nil")")
                    
                    self?.currentCity = city
                    print("📍 [DEBUG] Final city name set to: \(city)")
                    print("📍 [DEBUG] Full location: \(city), \(state), \(country)")
                } else {
                    print("📍 [DEBUG] No placemarks received")
                    self?.currentCity = "Unknown location"
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [DEBUG] Location error: \(error.localizedDescription)")
        print("📍 [DEBUG] Error domain: \(error as NSError).domain")
        print("📍 [DEBUG] Error code: \(error as NSError).code")
        
        DispatchQueue.main.async {
            self.currentCity = "Location error"
        }
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("📍 [DEBUG] Location access denied by user")
                DispatchQueue.main.async {
                    self.currentCity = "Access denied"
                }
            case .locationUnknown:
                print("📍 [DEBUG] Location temporarily unavailable")
                DispatchQueue.main.async {
                    self.currentCity = "Location unavailable"
                }
            case .network:
                print("📍 [DEBUG] Network error")
                DispatchQueue.main.async {
                    self.currentCity = "Network error"
                }
            case .headingFailure:
                print("📍 [DEBUG] Heading failure")
                DispatchQueue.main.async {
                    self.currentCity = "Location error"
                }
            default:
                print("📍 [DEBUG] Other Core Location error: \(clError.code)")
                DispatchQueue.main.async {
                    self.currentCity = "Location error"
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 [DEBUG] Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("📍 [DEBUG] Permission granted, requesting location...")
            locationManager.requestLocation()
        }
    }
}

// MARK: - Air Quality Models
struct AirQualityResponse: Codable {
    let list: [AirQualityData]
}

struct AirQualityData: Codable {
    let main: AirQualityMain
    let components: AirQualityComponents
    let dt: Int
}

struct AirQualityMain: Codable {
    let aqi: Int // Air Quality Index (1-5)
}

struct AirQualityComponents: Codable {
    let co: Double // Carbon monoxide
    let no2: Double // Nitrogen dioxide
    let o3: Double // Ozone
    let so2: Double // Sulphur dioxide
    let pm2_5: Double // Fine particulate matter
    let pm10: Double // Coarse particulate matter
    
    enum CodingKeys: String, CodingKey {
        case co, no2, o3, so2
        case pm2_5 = "pm2_5"
        case pm10
    }
}

// MARK: - Weather Response Models
