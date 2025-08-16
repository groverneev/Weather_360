import SwiftUI

struct SearchView: View {
    @StateObject private var weatherService = WeatherService()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var cityInput = ""
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top bar with current location and theme toggle
                HStack {
                    // Current location display
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(weatherService.locationManager.currentCity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Refresh location button
                        Button(action: {
                            weatherService.locationManager.requestLocation()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Theme toggle
                    Button(action: {
                        themeManager.toggleTheme()
                    }) {
                        Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.isDarkMode ? .yellow : .purple)
                            .padding(8)
                            .background(themeManager.isDarkMode ? Color.yellow.opacity(0.2) : Color.purple.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))
                
                // Main content
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App title
                    VStack(spacing: 10) {
                        Text("Weather 360")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Get accurate weather information for any city")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Search input
                    VStack(spacing: 15) {
                        TextField("Enter city name", text: $cityInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            if !cityInput.isEmpty {
                                weatherService.fetchWeather(for: cityInput)
                            }
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Weather")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                        }
                        .disabled(cityInput.isEmpty)
                        .padding(.horizontal, 20)
                    }
                    
                    // Current Location Button
                    Button(action: {
                        handleLocationRequest()
                    }) {
                        HStack {
                            Image(systemName: locationButtonIcon)
                            Text(locationButtonText)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(locationButtonColor)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, 20)
                    
                    // Location status info removed - was showing "location access granted" text
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
            .sheet(item: $weatherService.weather) { weather in
                WeatherView(weather: weather)
                    .environmentObject(themeManager)
            }
            .alert("Location Access Required", isPresented: $showingLocationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Location access is required to get weather for your current location. Please enable location access in Settings.\n\n1. Tap 'Open Settings'\n2. Tap 'Privacy & Security'\n3. Tap 'Location Services'\n4. Find 'Weather 360' and enable it")
            }
        }
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    
    private var locationButtonIcon: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        @unknown default:
            return "location"
        }
    }
    
    private var locationButtonText: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Location Access Denied"
        case .notDetermined:
            return "Use Current Location"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Use Current Location"
        @unknown default:
            return "Use Current Location"
        }
    }
    
    private var locationButtonColor: Color {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .blue
        case .authorizedWhenInUse, .authorizedAlways:
            return .blue
        @unknown default:
            return .blue
        }
    }
    
    private var locationStatusIcon: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "questionmark.circle"
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var locationStatusColor: Color {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        @unknown default:
            return .orange
        }
    }
    
    private var locationStatusText: String {
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Location access denied"
        case .notDetermined:
            return "Location permission not determined"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access granted"
        @unknown default:
            return "Location permission unknown"
        }
    }
    
    private var locationStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: locationStatusIcon)
                .foregroundColor(locationStatusColor)
                .font(.caption)
            Text(locationStatusText)
                .font(.caption)
                .foregroundColor(locationStatusColor)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Methods
    
    private func handleLocationRequest() {
        print("📍 [DEBUG] SearchView: Handling location request...")
        print("📍 [DEBUG] Current authorization status: \(weatherService.locationManager.authorizationStatus.rawValue)")
        
        switch weatherService.locationManager.authorizationStatus {
        case .denied, .restricted:
            print("📍 [DEBUG] Location access denied, showing settings alert")
            locationAlertMessage = "Location access is required to get weather for your current location. Please enable location access in Settings."
            showingLocationAlert = true
        case .notDetermined:
            print("📍 [DEBUG] Permission not determined, requesting permission")
            weatherService.locationManager.requestLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 [DEBUG] Permission granted, requesting location")
            weatherService.locationManager.requestLocation()
        @unknown default:
            print("📍 [DEBUG] Unknown status, requesting permission")
            weatherService.locationManager.requestLocation()
        }
    }
}

#Preview {
    SearchView()
}
