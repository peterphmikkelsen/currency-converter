//  Currency Converter
//  Created by Peter Mikkelsen on 20/04/2022.

import SwiftUI

struct ContentView: View {
    @State private var currency = (from: "EUR", to: "DKK")
    @State private var amount = (from: "", to: "")
    
    @State private var showAmount = (from: "", to: "")
    @State private var showOverlay = false
    
    // Used for focusing the correct TextField
    @FocusState private var fromFocus: Bool
    @FocusState private var toFocus: Bool
    
    @ObservedObject var currencyRates = CurrencyRates()
    
    private var textfieldWidth: CGFloat = 120
    @State private var isLoadingAnimation = false
    @Environment(\.colorScheme) var colorScheme
    
    let currencies = [
        "AUD":"Australian Dollar",
        "BGN":"Bulgarian Lev",
        "BRL":"Brazilian Real",
        "CAD":"Canadian Dollar",
        "CHF":"Swiss Franc",
        "CNY":"Chinese Renminbi Yuan",
        "CZK":"Czech Koruna",
        "DKK":"Danish Krone",
        "EUR":"Euro",
        "GBP":"British Pound",
        "HKD":"Hong Kong Dollar",
        "HRK":"Croatian Kuna",
        "HUF":"Hungarian Forint",
        "IDR":"Indonesian Rupiah",
        "ILS":"Israeli New Sheqel",
        "INR":"Indian Rupee",
        "ISK":"Icelandic Króna",
        "JPY":"Japanese Yen",
        "KRW":"South Korean Won",
        "MXN":"Mexican Peso",
        "MYR":"Malaysian Ringgit",
        "NOK":"Norwegian Krone",
        "NZD":"New Zealand Dollar",
        "PHP":"Philippine Peso",
        "PLN":"Polish Złoty",
        "RON":"Romanian Leu",
        "SEK":"Swedish Krona",
        "SGD":"Singapore Dollar",
        "THB":"Thai Baht",
        "TRY":"Turkish Lira",
        "USD":"United States Dollar",
        "ZAR":"South African Rand"
    ]
    
    var body: some View {
        let mainColor = self.colorScheme == .dark ? Color.gray : Color.black
        
        if (currencyRates.dataIsLoaded) {
            Button(action: { currencyRates.dataIsLoaded = false; currencyRates.loadRates() }, label: {
                Image(systemName: "gobackward")
                    .renderingMode(.template)
                    .foregroundColor(.gray)
                    .font(Font.system(size: 20, weight: .medium))
            }).frame(maxWidth: .infinity, alignment: .topTrailing).padding(15).onAppear {
                // Show keyboard immediately
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    fromFocus = true
                }
            }
            
            let rates = currencyRates.currencyModel?.rates
            VStack(alignment: .center) {
                Spacer().frame(height: 200)
                Text("Currency Converter").font(.title).bold()
                Spacer().frame(height: 50)
                HStack {
                    VStack {
                        Picker("Select a from currency", selection: $currency.from) {
                            ForEach(currencies.sorted(by: <), id: \.key) { key, _ in
                                Text(key)
                            }
                        }.onChange(of: currency.from) {
                            $0 // Leaving this out wont compile
                            
                            // Recalculate both sides when any one currency is changed
                            convertCurrency(newAmount: amount.from)
                            inverseConvertCurrency(newAmount: amount.to)
                        }
                        if (showOverlay) {
                            TextField(currencies[currency.from]!, text: $showAmount.from)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: textfieldWidth)
                                .onTapGesture {
                                    amount = ("", "")
                                    showAmount = ("", "")
                                    showOverlay.toggle()
                                    fromFocus.toggle()
                                }
                        } else {
                            TextField(currencies[currency.from]!, text: $amount.from)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: textfieldWidth)
                                .onChange(of: amount.from, perform: convertCurrency)
                                .focused($fromFocus)
                        }
                    }
                    Spacer().frame(width: 40)
                    Button(action: reverseButton, label: {
                        Image(systemName: "repeat").font(Font.system(size: 18, weight: .medium))
                    })
                    Spacer().frame(width: 40)
                    VStack {
                        Picker("Select a to currency", selection: $currency.to) {
                            ForEach(currencies.sorted(by: <), id: \.key) { key, _ in
                                Text(key)
                            }
                        }.onChange(of: currency.to) {
                            $0 // Leaving this out wont compile
                            
                            // Recalculate both sides when any one currency is changed
                            convertCurrency(newAmount: amount.from)
                            inverseConvertCurrency(newAmount: amount.to)
                        }
                        if (!showOverlay) {
                            TextField(currencies[currency.to]!, text: $showAmount.to)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: textfieldWidth)
                                .onTapGesture {
                                    amount = ("", "")
                                    showAmount = ("", "")
                                    showOverlay.toggle()
                                    toFocus.toggle()
                                }
                        } else {
                            TextField(currencies[currency.to]!, text: $amount.to)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: textfieldWidth)
                                .onChange(of: amount.to, perform: inverseConvertCurrency)
                                .focused($toFocus)
                        }
                    }
                }
                Spacer().frame(height: 40)
                
                // TODO: Very messy but it works.
                if (currency.to == "EUR") {
                    if (currency.from == currency.to) {
                        Text("1 EUR = 1 EUR")
                            .font(.footnote)
                            .foregroundColor(mainColor)
                        Text("1 EUR = 1 EUR")
                            .font(.footnote)
                            .foregroundColor(mainColor)
                    } else {
                        Text("1 \(currency.from) = \(1/rates![currency.from]!) \(currency.to)")
                            .font(.footnote)
                            .foregroundColor(mainColor)
                        Text("1 \(currency.to) = \(rates![currency.from]!) \(currency.from)")
                            .font(.footnote)
                            .foregroundColor(mainColor)
                    }
                } else if (currency.from == "EUR") {
                    Text("1 \(currency.from) = \(rates![currency.to]!) \(currency.to)")
                        .font(.footnote)
                        .foregroundColor(mainColor)
                    Text("1 \(currency.to) = \(1/rates![currency.to]!) \(currency.from)")
                        .font(.footnote)
                        .foregroundColor(mainColor)
                } else {
                    Text("1 \(currency.from) = \(rates![currency.to]! / rates![currency.from]!) \(currency.to)")
                        .font(.footnote)
                        .foregroundColor(mainColor)
                    Text("1 \(currency.to) = \(rates![currency.from]! / rates![currency.to]!) \(currency.from)")
                        .font(.footnote)
                        .foregroundColor(mainColor)
                }
                Spacer()
            }.ignoresSafeArea(.keyboard)
        } else {
            Spacer()
            VStack {
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 5)
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: isLoadingAnimation ? 360 : 0))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                            isLoadingAnimation = true
                        }
                    }
                    Spacer().frame(height: 30)
                    Text("Loading conversion rates...")
                        .font(.footnote)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            Spacer()
        }
    }
    
    func reverseButton() {
        currency = (currency.to, currency.from)
    }
    
    func convertCurrency(newAmount: String) {
        if (newAmount == "") {
            showAmount.to = ""
            return
        }
        
        let changedAmount = newAmount.replacingOccurrences(of: ",", with: ".")
        let rates = currencyRates.currencyModel?.rates
        if (amount.from == "" && amount.to == "" || amount.from == "0" && amount.to == "0") {
            return
        }
        if (currency.from == currency.to) {
            showAmount.to = changedAmount
            return
        }

        if (rates!.contains(where: { $0.key == currency.to })) {
            let amountInEuros = convertToEuro(amount: changedAmount, currency: currency.from)
            showAmount.to = String(format: "%.2f", amountInEuros * rates![currency.to]!)
        } else if (currency.to == "EUR") {
            let amount = Double(changedAmount) ?? 1
            showAmount.to = String(format: "%.2f", amount * (1/rates![currency.from]!))
        } else {
            showAmount.to = ""
        }
    }
    
    func inverseConvertCurrency(newAmount: String) {
        if (newAmount == "") {
            showAmount.from = ""
            return
        }
        
        let changedAmount = newAmount.replacingOccurrences(of: ",", with: ".")
        let rates = currencyRates.currencyModel?.rates
        if (amount.from == "" && amount.to == "" || amount.from == "0" && amount.to == "0") {
            return
        }
        if (currency.from == currency.to) {
            showAmount.from = changedAmount
            return
        }
       
        // TODO: Very messy! But it works.
        if (fromFocus) {
            if (rates!.contains(where: { $0.key == currency.to })) {
                let amountInEuros = convertToEuro(amount: changedAmount, currency: currency.to)
                showAmount.from = String(format: "%.2f", amountInEuros * (1/rates![currency.to]!))
            } else if (currency.to == "EUR") {
                let amount = Double(changedAmount) ?? 1
                showAmount.from = String(format: "%.2f", amount * (1/rates![currency.from]!))
            } else {
                showAmount.from = ""
            }
        } else {
            if (rates!.contains(where: { $0.key == currency.from })) {
                let amountInEuros = convertToEuro(amount: changedAmount, currency: currency.to)
                showAmount.from = String(format: "%.2f", amountInEuros * rates![currency.from]!)
            } else if (currency.from == "EUR") {
                let amount = Double(changedAmount) ?? 1
                showAmount.from = String(format: "%.2f", amount * (1/rates![currency.to]!))
            } else {
                showAmount.from = ""
            }
        }
    }
    
    func convertToEuro(amount: String, currency: String) -> Double {
        let rates = currencyRates.currencyModel?.rates
        if (currency == "EUR") {
            return Double(amount) ?? 1
        }
        return (Double(amount) ?? 1) * (1/(rates![currency] ?? 1))
    }
}

class CurrencyRates: ObservableObject {
    @Published var dataIsLoaded: Bool = false
    @Published var currencyModel: CurrencyModel? = nil
    let userDefaults = UserDefaults.standard
    let dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        loadRates()
    }
    
    func loadRates() {
        let rates = userDefaults.object(forKey: "CurrencyRates") as? Data
        if (rates == nil) {
            loadRatesFromURL()
        } else {
            loadRatesFromStorage(rates: rates)
        }
    }
    
    func loadRatesFromURL() {
        let url = URL(string: "https://api.frankfurter.app/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard error == nil else {
                print ("error: \(error!)")
                return
            }
            
            guard let content = data else {
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self.userDefaults.set(content, forKey: "CurrencyRates")
                    self.currencyModel = try JSONDecoder().decode(CurrencyModel.self, from: content)
                    self.dataIsLoaded = true
                } catch {
                    print("Something went wrong: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func loadRatesFromStorage(rates: Data?) {
        do {
            self.currencyModel = try JSONDecoder().decode(CurrencyModel.self, from: rates!)
            
            let dateFromData = dateFormatter.date(from: self.currencyModel!.date)!
            
            // Weird bug - we have to add one day to the date from the data
            let date = Calendar.current.date(byAdding: .day, value: 1, to: dateFromData)!
            let now = dateFormatter.date(from: dateFormatter.string(from: Date()))!
            
            
            if (date < now) {
                loadRatesFromURL()
                return
            }
            
            self.dataIsLoaded = true
            
        } catch {
            print("Something went wrong: \(error)")
        }
    }
}

struct CurrencyModel: Codable, Hashable {
    let base: String
    let date: String
    let rates: [String: Double]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
    }
}


