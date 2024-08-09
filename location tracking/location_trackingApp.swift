import SwiftUI
import GoogleMaps
import Firebase

@main
struct location_trackingApp: App {
    // You might need a persistence controller if using Core Data
    let persistenceController = PersistenceController.shared

    init() {
        // Initialize Google Maps API key
        GMSServices.provideAPIKey("AIzaSyBW9uqYNuGUoDRW5LLU3VYEHDBfL0JEZXE")
        
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

