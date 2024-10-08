import Buy
import JWTKit
import KSCrashInstallations
import Pay
import SwiftUI

struct ContentView: View {
    init() {
        // Use Mobile Buy SDK
        _ = Card.CreditCard(firstName: "", lastName: "", number: "", expiryMonth: "", expiryYear: "")
        _ = PayAddress()
        // Use KSCrash
        _ = CrashInstallationStandard()
        // Use JWTKit
        _ = JWTKit.ES256PrivateKey()
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
