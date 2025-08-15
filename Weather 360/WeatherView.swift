import SwiftUI

struct WeatherView: View {
    let weather: WeatherDisplay
    @State private var temperatureUnit: TemperatureUnit = .celsius
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with city name and current temperature
                VStack(spacing: 8) {
                    Text(weather.cityName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(weather.temperature.formatTemperature(unit: temperatureUnit))
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.primary)
                    
                    // Debug info - show raw values
                    VStack(spacing: 4) {
                        Text("Raw: \(String(format: "%.2f", weather.temperature))K")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("C: \(String(format: "%.1f", weather.temperature.toCelsius()))°C")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("F: \(String(format: "%.1f", weather.temperature.toFahrenheit()))°F")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text(weather.description.capitalized)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Temperature unit toggle
                    Picker("Temperature Unit", selection: $temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text("°\(unit.rawValue)").tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
                .padding(.top, 20)
                
                // High/Low temperature
                HStack(spacing: 30) {
                    VStack {
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(weather.highTemp.formatTemperature(unit: temperatureUnit))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(weather.lowTemp.formatTemperature(unit: temperatureUnit))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 10)
                
                // Feels like temperature
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("Feels like \(weather.feelsLike.formatTemperature(unit: temperatureUnit))")
                        .font(.title3)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                
                // Weather details grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    WeatherDetailCard(
                        icon: "humidity",
                        title: "Humidity",
                        value: "\(weather.humidity)%",
                        color: .blue
                    )
                    
                    WeatherDetailCard(
                        icon: "gauge",
                        title: "Pressure",
                        value: "\(weather.pressure) hPa",
                        color: .green
                    )
                    
                    WeatherDetailCard(
                        icon: "wind",
                        title: "Wind Speed",
                        value: String(format: "%.1f m/s", weather.windSpeed),
                        color: .cyan
                    )
                    
                    WeatherDetailCard(
                        icon: "location.north",
                        title: "Wind Direction",
                        value: weather.windDirection.windDirection(),
                        color: .purple
                    )
                }
                .padding(.horizontal, 20)
                
                // Sunrise and Sunset
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "sunrise")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Sunrise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(weather.sunrise, style: .time)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Image(systemName: "sunset")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Sunset")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(weather.sunset, style: .time)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(15)
                
                Spacer(minLength: 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let sampleWeather = WeatherDisplay(
        cityName: "San Francisco",
        temperature: 293.15,
        feelsLike: 291.15,
        highTemp: 298.15,
        lowTemp: 288.15,
        humidity: 65,
        pressure: 1013,
        windSpeed: 5.2,
        windDirection: 180,
        description: "partly cloudy",
        icon: "02d",
        sunrise: Date(),
        sunset: Date().addingTimeInterval(3600 * 12)
    )
    
    WeatherView(weather: sampleWeather)
}
