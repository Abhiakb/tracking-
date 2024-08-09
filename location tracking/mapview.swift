import SwiftUI
import GoogleMaps
import CoreLocation
import FirebaseFirestore

struct MapView: UIViewRepresentable {
    @ObservedObject var customerLocationManager: LocationManager
    @ObservedObject var deliveryPersonLocationManager: LocationManager

    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView()
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        
        // Update customer marker
        if let customerCoordinate = customerLocationManager.location {
            let customerMarker = GMSMarker(position: customerCoordinate)
            customerMarker.title = "Customer"
            customerMarker.icon = GMSMarker.markerImage(with: .blue)
            customerMarker.map = mapView
        }

        // Update delivery person marker
        if let deliveryCoordinate = deliveryPersonLocationManager.location {
            let deliveryMarker = GMSMarker(position: deliveryCoordinate)
            deliveryMarker.title = "Delivery Person"
            deliveryMarker.icon = GMSMarker.markerImage(with: .red)
            deliveryMarker.map = mapView
        }

        // Fetch and display route
        fetchAndDisplayRoute(mapView: mapView)
    }

    func fetchAndDisplayRoute(mapView: GMSMapView) {
        guard let customerCoordinate = customerLocationManager.location,
              let deliveryCoordinate = deliveryPersonLocationManager.location else {
            return
        }
        
        // Construct the URL for the Directions API request
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(customerCoordinate.latitude),\(customerCoordinate.longitude)&destination=\(deliveryCoordinate.latitude),\(deliveryCoordinate.longitude)&key=YOUR_API_KEY"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching directions: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data returned")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let routes = json["routes"] as? [[String: Any]],
                   let overviewPolyline = routes.first?["overview_polyline"] as? [String: Any],
                   let points = overviewPolyline["points"] as? String {
                    
                    DispatchQueue.main.async {
                        self.drawRoute(on: mapView, from: points)
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        task.resume()
    }

    func drawRoute(on mapView: GMSMapView, from encodedPoints: String) {
        guard let path = GMSPath(fromEncodedPath: encodedPoints) else {
            print("Failed to decode path")
            return
        }

        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5.0
        polyline.strokeColor = .blue
        polyline.map = mapView

        // Optionally adjust the camera to fit the route
        let bounds = GMSCoordinateBounds(path: path)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
        mapView.moveCamera(update)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        // Add delegate methods if needed
    }
}

