import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct LogInView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMapView = false

    @StateObject private var customerLocationManager = LocationManager()
    @StateObject private var deliveryPersonLocationManager = LocationManager()

    var body: some View {
        NavigationView {
            VStack {
                Text("Log In")
                    .font(.largeTitle)
                    .padding(.bottom, 40)

                TextField("Enter your email", text: $email)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .padding(.bottom, 20)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Enter your password", text: $password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .padding(.bottom, 20)

                NavigationLink(destination: MapView(
                    customerLocationManager: customerLocationManager,
                    deliveryPersonLocationManager: deliveryPersonLocationManager
                ).navigationBarBackButtonHidden(true), isActive: $navigateToMapView) {
                    EmptyView()
                }

                Button(action: logIn) {
                    Text("Log In")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Log In"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                        if alertMessage == "Log In successful!" {
                            navigateToMapView = true
                            fetchUsersAndUpdateMap() // Fetch users and set up listeners
                        }
                    })
                }
                .padding(.horizontal, 20)
            }
            .padding()
        }
    }

    func logIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            } else {
                alertMessage = "Log In successful!"
                showingAlert = true
            }
        }
    }

    func fetchUsersAndUpdateMap() {
        let db = Firestore.firestore()

        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No users found")
                return
            }

            for document in documents {
                let data = document.data()
                let role = data["role"] as? String ?? ""
                let location = data["location"] as? [Double] ?? [0.0, 0.0]
                let coordinate = CLLocationCoordinate2D(latitude: location[0], longitude: location[1])

                if role == "customer" {
                    updateCustomerLocation(coordinate)
                } else if role == "delivery_person" {
                    updateDeliveryPersonLocation(coordinate)
                }

                // Debug print
                print("Fetched \(role) location: \(coordinate)")
            }
        }
    }

    func updateCustomerLocation(_ coordinate: CLLocationCoordinate2D) {
        customerLocationManager.location = coordinate
    }

    func updateDeliveryPersonLocation(_ coordinate: CLLocationCoordinate2D) {
        deliveryPersonLocationManager.location = coordinate
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

