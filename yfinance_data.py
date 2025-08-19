import yfinance as yf

nse_data = yf.Ticker("^NSEI")

print(nse_data.info)

def get_nse_historical_data():
    nse_historical = nse_data.history(start='2020-01-01', end='2025-08-01', interval='1d')

    nse_historical.to_csv('nse_historical_data.csv')
    print("NSE historical data saved to 'nse_historical_data.csv'")

    sensex_data = yf.Ticker("^BSESN")

    sensex_historical = sensex_data.history(start='2020-01-01', end='2025-08-01', interval='1d')
    sensex_historical.to_csv('sensex_historical_data.csv')
    print("Sensex historical data saved to 'sensex_historical_data.csv'")