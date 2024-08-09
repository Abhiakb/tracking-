import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var selectedRole: String = "customer" // Default role
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMapView = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Create Your Account")
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

                Picker("Select Role", selection: $selectedRole) {
                    Text("Customer").tag("customer")
                    Text("Delivery Person").tag("delivery_person")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 20)

                Button(action: register) {
                    Text("Register")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Registration"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                        if alertMessage == "Registration successful!" {
                            navigateToMapView = true
                        }
                    })
                }
                .padding(.horizontal, 20)

                NavigationLink(destination: LogInView(), isActive: $navigateToMapView) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .padding()
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            } else if let user = authResult?.user {
                // Save user role and location to Firestore
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "email": email,
                    "role": selectedRole,
                    "location": [0.0, 0.0] // Default location
                ]) { error in
                    if let error = error {
                        alertMessage = "Error saving data: \(error.localizedDescription)"
                    } else {
                        alertMessage = "Registration successful!"
                    }
                    showingAlert = true
                }
            }
        }
    }
}

