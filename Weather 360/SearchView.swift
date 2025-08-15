import SwiftUI

struct SearchView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showingLocationAlert = false
    
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
                
                // Current location button
                Button(action: {
                    locationManager.requestLocation()
                    showingLocationAlert = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                
                // Test API button (for debugging)
                Button(action: {
                    weatherService.testAPIWithKnownCity()
                }) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                        Text("Test API (London)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                
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
        } message: {
            Text("Please allow location access in Settings to use your current location for weather.")
        }
        .sheet(item: $weatherService.weather) { weather in
            WeatherView(weather: weather)
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
