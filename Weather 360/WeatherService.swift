import Foundation
import Combine
import os.log
import Network

class WeatherService: ObservableObject {
    @Published var weather: WeatherDisplay?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = Config.openWeatherMapAPIKey
    private let baseURL = Config.openWeatherMapBaseURL
    private let logger = Logger(subsystem: "com.weatherapp", category: "WeatherService")
    private let networkMonitor = NWPathMonitor()
    private var isNetworkReachable = false
    
    init() {
        // Test temperature conversions on initialization
        testTemperatureConversions()
        
        // Setup network monitoring
        setupNetworkMonitoring()
        
        // Test API connectivity
        testAPIConnectivity()
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
                    
                    self?.logger.info("🌡️ Temperature (K): \(response.main.temp)")
                    print("🌡️ [DEBUG] Temperature (K): \(response.main.temp)")
                    self?.logger.info("🌡️ Temperature (C): \(response.main.temp.toCelsius())")
                    print("🌡️ [DEBUG] Temperature (C): \(response.main.temp.toCelsius())")
                    self?.logger.info("🌡️ Temperature (F): \(response.main.temp.toFahrenheit())")
                    print("🌡️ [DEBUG] Temperature (F): \(response.main.temp.toFahrenheit())")
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
                    
                    let weatherDisplay = WeatherDisplay(from: response)
                    self?.weather = weatherDisplay
                    
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
                    
                    let weatherDisplay = WeatherDisplay(from: response)
                    self?.weather = weatherDisplay
                    
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
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}
