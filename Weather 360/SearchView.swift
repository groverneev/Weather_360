import SwiftUI

struct SearchView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showingLocationAlert = false
    @State private var locationAlertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search header
                VStack(spacing: 10) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Weather 360")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Get current weather for any city")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Enter city name...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            if !searchText.isEmpty {
                                weatherService.fetchWeather(for: searchText)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                
                // Search button
                Button(action: {
                    if !searchText.isEmpty {
                        weatherService.fetchWeather(for: searchText)
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
                    .background(searchText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(15)
                }
                .disabled(searchText.isEmpty)
                .padding(.horizontal, 20)
                
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
                
                // Location status info
                if locationManager.authorizationStatus != .notDetermined {
                    locationStatusView
                }
                
                // Loading state
                if weatherService.isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Fetching weather data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
                
                // Error state
                if let errorMessage = weatherService.errorMessage {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onReceive(locationManager.$location) { location in
            if let location = location {
                weatherService.fetchWeatherByCoordinates(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            }
        }
        .alert("Location Access", isPresented: $showingLocationAlert) {
            Button("OK") { }
            if locationManager.authorizationStatus == .denied {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        } message: {
            Text(locationAlertMessage)
        }
        .sheet(item: $weatherService.weather) { weather in
            WeatherView(weather: weather)
        }
    }
    
    // MARK: - Computed Properties
    
    private var locationButtonIcon: String {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return "location.slash.fill"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        default:
            return "location.fill"
        }
    }
    
    private var locationButtonText: String {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return "Location Access Denied"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Use Current Location"
        default:
            return "Use Current Location"
        }
    }
    
    private var locationButtonColor: Color {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .authorizedWhenInUse, .authorizedAlways:
            return .blue
        default:
            return .blue
        }
    }
    
    private var locationStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: locationStatusIcon)
                    .foregroundColor(locationStatusColor)
                Text(locationStatusText)
                    .font(.caption)
                    .foregroundColor(locationStatusColor)
            }
            
            if locationManager.authorizationStatus == .denied {
                Text("Tap 'Open Settings' in the alert to enable location access")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var locationStatusIcon: String {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return "exclamationmark.triangle.fill"
        case .authorizedWhenInUse, .authorizedAlways:
            return "checkmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        default:
            return .orange
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .denied:
            return "Location access denied"
        case .restricted:
            return "Location access restricted"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Location access granted"
        default:
            return "Location permission not determined"
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLocationRequest() {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            locationAlertMessage = "Location access is required to get weather for your current location. Please enable location access in Settings."
            showingLocationAlert = true
        case .notDetermined:
            locationManager.requestLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            locationManager.requestLocation()
        }
    }
}

// Extension to make WeatherDisplay conform to Identifiable for sheet presentation
extension WeatherDisplay: Identifiable {
    var id: String { cityName }
}

#Preview {
    SearchView()
}
