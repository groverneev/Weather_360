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
                        
                        // Note about potential discrepancy
                        Text("Note: API data may be 5-15 min old")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.top, 2)
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
                        icon: "thermometer",
                        title: "Feels Like",
                        value: String(format: "%.0f°", weather.feelsLike.toFahrenheit()),
                        color: .orange
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
                
                // Humidity and Air Quality
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "humidity")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Humidity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(weather.humidity)%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Image(systemName: airQualityIcon)
                            .font(.title2)
                            .foregroundColor(airQualityColor)
                        Text("Air Quality")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(airQualityText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(airQualityColor)
                    }
                }
                
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
                            .environment(\.timeZone, TimeZone(secondsFromGMT: weather.timezoneOffset) ?? TimeZone.current)
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
                            .environment(\.timeZone, TimeZone(secondsFromGMT: weather.timezoneOffset) ?? TimeZone.current)
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
    
    // MARK: - Computed Properties
    
    private var airQualityIcon: String {
        switch weather.airQualityIndex {
        case 1:
            return "leaf.fill"
        case 2:
            return "leaf"
        case 3:
            return "exclamationmark.triangle"
        case 4:
            return "exclamationmark.triangle.fill"
        case 5:
            return "xmark.octagon.fill"
        default:
            return "questionmark.circle"
        }
    }
    
    private var airQualityColor: Color {
        switch weather.airQualityIndex {
        case 1:
            return .green
        case 2:
            return .yellow
        case 3:
            return .orange
        case 4:
            return .red
        case 5:
            return .purple
        default:
            return .gray
        }
    }
    
    private var airQualityText: String {
        switch weather.airQualityIndex {
        case 1:
            return "Good"
        case 2:
            return "Fair"
        case 3:
            return "Moderate"
        case 4:
            return "Poor"
        case 5:
            return "Very Poor"
        default:
            return "Unknown"
        }
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
        airQualityIndex: 2,
        windSpeed: 5.2,
        windDirection: 180,
        description: "partly cloudy",
        icon: "02d",
        sunrise: Date(),
        sunset: Date().addingTimeInterval(3600 * 12),
        timezoneOffset: -28800 // Pacific Time (UTC-8)
    )
    
    WeatherView(weather: sampleWeather)
}
