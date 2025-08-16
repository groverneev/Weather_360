import SwiftUI

// MARK: - Hourly Forecast View
struct HourlyForecastView: View {
    let forecasts: [HourlyForecast]
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Hourly Forecast")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecasts) { forecast in
                        HourlyForecastItem(forecast: forecast, isCelsius: isCelsius)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HourlyForecastItem: View {
    let forecast: HourlyForecast
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Time
            Text(timeString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Weather Icon
            if forecast.isSunset {
                Image(systemName: "sunset.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            } else {
                WeatherIconView(iconCode: forecast.icon)
                    .frame(width: 30, height: 30)
            }
            
            // Temperature
            Text("\(isCelsius ? forecast.temperature : forecast.temperature.toFahrenheit(), specifier: "%.0f")°")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.locale = Locale(identifier: "en_US")
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: forecast.time)
        
        if hour == calendar.component(.hour, from: Date()) {
            return "Now"
        } else {
            return formatter.string(from: forecast.time)
        }
    }
}

// MARK: - Daily Forecast View
struct DailyForecastView: View {
    let forecasts: [DailyForecast]
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("5-Day Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(forecasts) { forecast in
                    DailyForecastItem(forecast: forecast, isCelsius: isCelsius)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct DailyForecastItem: View {
    let forecast: DailyForecast
    let isCelsius: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            // Day name
            Text(forecast.dayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .leading)
            
            // Weather icon
            WeatherIconView(iconCode: forecast.icon)
                .frame(width: 25, height: 25)
            
            // Temperature range bar
            TemperatureRangeBar(
                lowTemp: forecast.lowTemp,
                highTemp: forecast.highTemp,
                isCelsius: isCelsius
            )
            .frame(height: 20)
            
            // High and low temperatures
            HStack(spacing: 20) {
                Text("\(isCelsius ? forecast.lowTemp : forecast.lowTemp.toFahrenheit(), specifier: "%.0f")°")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("\(isCelsius ? forecast.highTemp : forecast.highTemp.toFahrenheit(), specifier: "%.0f")°")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            .frame(width: 80)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(themeManager.isDarkMode ? Color(.systemGray6) : Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: themeManager.isDarkMode ? .clear : .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Temperature Range Bar
struct TemperatureRangeBar: View {
    let lowTemp: Double
    let highTemp: Double
    let isCelsius: Bool
    
    private var lowTempF: Double { lowTemp.toFahrenheit() }
    private var highTempF: Double { highTemp.toFahrenheit() }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Temperature range bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .yellow, .orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width, height: 4)
                    .cornerRadius(2)
                
                // Current temperature indicator (white dot)
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .position(
                        x: currentTempPosition(in: geometry.size.width),
                        y: geometry.size.height / 2
                    )
            }
        }
    }
    
    private func currentTempPosition(in width: CGFloat) -> CGFloat {
        // Calculate position based on current temperature relative to low/high range
        let currentTemp = isCelsius ? (lowTemp + highTemp) / 2 : (lowTempF + highTempF) / 2
        let low = isCelsius ? lowTemp : lowTempF
        let high = isCelsius ? highTemp : highTempF
        
        let range = high - low
        let position = (currentTemp - low) / range
        
        return position * width
    }
}

// MARK: - Weather Icon View
struct WeatherIconView: View {
    let iconCode: String
    
    var body: some View {
        // This is a placeholder - you can integrate with a weather icon system
        // For now, using SF Symbols based on weather conditions
        Image(systemName: weatherIconName)
            .font(.title2)
            .foregroundColor(weatherIconColor)
    }
    
    private var weatherIconName: String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d", "03d", "04d": return "cloud.sun.fill"
        case "02n", "03n", "04n": return "cloud.moon.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
    
    private var weatherIconColor: Color {
        switch iconCode {
        case "01d": return .yellow
        case "01n": return .gray
        case "02d", "03d", "04d": return .orange
        case "02n", "03n", "04n": return .gray
        case "09d", "09n", "10d", "10n": return .blue
        case "11d", "11n": return .purple
        case "13d", "13n": return .cyan
        case "50d", "50n": return .gray
        default: return .gray
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HourlyForecastView(forecasts: [
            HourlyForecast(from: ForecastItem(dt: Int(Date().timeIntervalSince1970), main: ForecastMain(temp: 293.15, feelsLike: 291.15, tempMin: 288.15, tempMax: 298.15, pressure: 1013, humidity: 65, seaLevel: nil, grndLevel: nil), weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")], clouds: Clouds(all: 0), wind: Wind(speed: 5.2, deg: 180, gust: nil), visibility: 10000, pop: 0.0, sys: ForecastSys(pod: "d"), dtTxt: ""), timezoneOffset: -28800),
            HourlyForecast(from: ForecastItem(dt: Int(Date().timeIntervalSince1970 + 3600 * 3), main: ForecastMain(temp: 295.15, feelsLike: 293.15, tempMin: 288.15, tempMax: 298.15, pressure: 1013, humidity: 60, seaLevel: nil, grndLevel: nil), weather: [Weather(id: 801, main: "Clouds", description: "few clouds", icon: "02d")], clouds: Clouds(all: 20), wind: Wind(speed: 4.8, deg: 175, gust: nil), visibility: 10000, pop: 0.0, sys: ForecastSys(pod: "d"), dtTxt: ""), timezoneOffset: -28800)
        ], isCelsius: true)
        
        DailyForecastView(forecasts: [
            DailyForecast(from: [ForecastItem(dt: Int(Date().timeIntervalSince1970), main: ForecastMain(temp: 293.15, feelsLike: 291.15, tempMin: 288.15, tempMax: 298.15, pressure: 1013, humidity: 65, seaLevel: nil, grndLevel: nil), weather: [Weather(id: 800, main: "Clear", description: "clear sky", icon: "01d")], clouds: Clouds(all: 0), wind: Wind(speed: 5.2, deg: 180, gust: nil), visibility: 10000, pop: 0.0, sys: ForecastSys(pod: "d"), dtTxt: "")], timezoneOffset: -28800),
            DailyForecast(from: [ForecastItem(dt: Int(Date().timeIntervalSince1970 + 3600 * 24), main: ForecastMain(temp: 295.15, feelsLike: 293.15, tempMin: 289.15, tempMax: 299.15, pressure: 1013, humidity: 60, seaLevel: nil, grndLevel: nil), weather: [Weather(id: 801, main: "Clouds", description: "few clouds", icon: "02d")], clouds: Clouds(all: 20), wind: Wind(speed: 4.8, deg: 175, gust: nil), visibility: 10000, pop: 0.0, sys: ForecastSys(pod: "d"), dtTxt: "")], timezoneOffset: -28800)
        ], isCelsius: true)
    }
    .padding()
    .background(Color.blue.opacity(0.1))
    .environmentObject(ThemeManager())
}
