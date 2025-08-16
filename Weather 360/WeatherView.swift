import SwiftUI

struct WeatherView: View {
    let weather: WeatherDisplay
    @State private var isCelsius = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // City name and current temperature
                VStack(spacing: 10) {
                    Text(weather.cityName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 15) {
                        Text("\(isCelsius ? weather.temperature.toCelsius() : weather.temperature.toFahrenheit(), specifier: "%.0f")°")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Button(action: {
                                isCelsius.toggle()
                            }) {
                                HStack(spacing: 5) {
                                    Text(isCelsius ? "°C" : "°F")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Text(weather.description.capitalized)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 20)
                
                // High and Low temperatures
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "thermometer.sun.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(isCelsius ? weather.highTemp.toCelsius() : weather.highTemp.toFahrenheit(), specifier: "%.0f")°")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Image(systemName: "thermometer.snowflake")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(isCelsius ? weather.lowTemp.toCelsius() : weather.lowTemp.toFahrenheit(), specifier: "%.0f")°")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 20)
                
                // Temperature Chart
                VStack(spacing: 15) {
                    Text("24-Hour Temperature Trend")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TemperatureChart(
                        currentTemp: weather.temperature,
                        isCelsius: isCelsius,
                        timezoneOffset: weather.timezoneOffset,
                        hourlyForecast: weather.hourlyForecast
                    )
                }
                .padding(.horizontal, 20)
                
                // Weather detail cards
                HStack(spacing: 20) {
                    WeatherDetailCard(
                        icon: "thermometer",
                        title: "Feels Like",
                        value: String(format: "%.0f°", isCelsius ? weather.feelsLike.toCelsius() : weather.feelsLike.toFahrenheit()),
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
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(themeManager.isDarkMode ? Color(.systemGray5) : Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Temperature Chart Component
struct TemperatureChart: View {
    let currentTemp: Double
    let isCelsius: Bool
    let timezoneOffset: Int
    let hourlyForecast: [HourlyForecast]
    
    // Use real forecast data if available, otherwise generate sample data
    private var temperatureData: [TemperaturePoint] {
        if !hourlyForecast.isEmpty {
            // Use real forecast data
            return hourlyForecast.map { forecast in
                TemperaturePoint(time: forecast.time, temperature: forecast.temperature)
            }
        } else {
            // Fallback to realistic sample data (only when no API data available)
            let now = Date()
            let calendar = Calendar.current
            
            var data: [TemperaturePoint] = []
            
            // Generate 25 data points (12h ago to 12h ahead, including current)
            for hour in stride(from: -12, through: 12, by: 1) {
                let time = calendar.date(byAdding: .hour, value: hour, to: now) ?? now
                // More realistic temperature variation based on time of day
                let baseVariation = sin(Double(hour) * .pi / 12) * 3 // Natural daily cycle
                let temp = currentTemp + baseVariation
                data.append(TemperaturePoint(time: time, temperature: temp))
            }
            
            return data
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Chart container
            ZStack {
                // Background grid with temperature labels
                let minTemp = temperatureData.map { $0.temperature }.min() ?? 0
                let maxTemp = temperatureData.map { $0.temperature }.max() ?? 1
                let tempRange = maxTemp - minTemp
                
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { index in
                        HStack {
                            // Temperature label on the left
                            let tempValue = maxTemp - (tempRange * Double(index) / 5.0)
                            
                            Text(isCelsius ? String(format: "%.0f°C", tempValue.toCelsius()) : String(format: "%.0f°F", tempValue.toFahrenheit()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                            
                            Divider()
                                .opacity(0.3)
                        }
                        Spacer()
                    }
                }
                
                // Vertical time grid lines (5 lines: 12h ago, 6h ago, current, 6h ahead, 12h ahead)
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack {
                            Divider()
                                .opacity(0.2)
                                .rotationEffect(.degrees(90))
                                .frame(height: 120)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                // Temperature line
                Path { path in
                    let width: CGFloat = 300 // Fixed width for simplicity
                    let height: CGFloat = 120
                    
                    guard temperatureData.count >= 5 else { return }
                    
                    // We have exactly 5 data points: 12h ago, 6h ago, current, 6h ahead, 12h ahead
                    let xStep = width / 4.0 // 4 intervals between 5 points
                    let minTemp = temperatureData.map { $0.temperature }.min() ?? 0
                    let maxTemp = temperatureData.map { $0.temperature }.max() ?? 0
                    let tempRange = maxTemp - minTemp
                    
                    // Start with the first point (12h ago)
                    let startX: CGFloat = 0
                    let startY = height - (CGFloat(temperatureData[0].temperature - minTemp) / CGFloat(tempRange)) * height
                    path.move(to: CGPoint(x: startX, y: startY))
                    
                    // Plot all 5 data points
                    for (index, point) in temperatureData.enumerated() {
                        let x = CGFloat(index) * xStep
                        let y = height - (CGFloat(point.temperature - minTemp) / CGFloat(tempRange)) * height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .cyan, .green]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Current temperature indicator (positioned at current time point)
                let currentY = 60 - (CGFloat(currentTemp - minTemp) / CGFloat(tempRange)) * 120
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .shadow(color: .orange.opacity(0.5), radius: 4)
                    .position(x: 150, y: currentY) // Center position (index 2 of 5 points)
            }
            .frame(width: 300, height: 120)
            .background(Color(.systemBackground).opacity(0.8))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Time labels (5 points: 12h ago, 6h ago, current, 6h ahead, 12h ahead)
            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    VStack {
                        if index == 0 {
                            Text("12h ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if index == 1 {
                            Text("6h ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else if index == 2 {
                            Text("Now")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        } else if index == 3 {
                            Text("6h ahead")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("12h ahead")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Temperature Point Model
struct TemperaturePoint {
    let time: Date
    let temperature: Double
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
        timezoneOffset: -28800, // Pacific Time (UTC-8)
        hourlyForecast: [] // Empty for preview
    )
    
    WeatherView(weather: sampleWeather)
        .environmentObject(ThemeManager())
}
