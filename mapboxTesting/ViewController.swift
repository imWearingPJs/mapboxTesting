//
//  ViewController.swift
//  mapboxTesting
//
//  Created by Michael Kozub on 2/26/19.
//  Copyright © 2019 Michael Kozub. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class ViewController: UIViewController, MGLMapViewDelegate {
    var mapView: NavigationMapView!
    var directionsRoute: Route?
    
    var userCoordinates: [CLLocationCoordinate2D] = []
    var recordRoute = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = NavigationMapView(frame: view.bounds)
        
        view.addSubview(mapView)
        
        let button = UIButton(frame: CGRect(x: 160, y: 760, width: 130, height: 50))
            button.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.4666666667, blue: 0.3294117647, alpha: 1)
            button.setTitle("Start Tracking", for: .normal)
            button.addTarget(self, action: #selector(action(sender:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        // Set the map view's delegate
        mapView.delegate = self
        
        // Allow the map to display the user's location
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        
        // Add a gesture recognizer to the map view
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        
        mapView.addGestureRecognizer(longPress)
        
    }
    
    @objc fileprivate func action(sender: Button) {
        print("button tapped")
        if sender.currentTitle == "Start Tracking" {
            sender.setTitle("Stop Tracking", for: .normal)
//            mapView.setUserTrackingMode(.follow, animated: true)
            recordRoute = true
        } else {
            sender.setTitle("Start Tracking", for: .normal)
//            mapView.setUserTrackingMode(.none, animated: true)
            recordRoute = false
        }
    }
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        print("User location updated!" )
        let coordinates = mapView.userLocation!.coordinate

        if recordRoute == true {
            userCoordinates.append(coordinates)
        }
        print(userCoordinates)
        if userCoordinates.count > 0 {
            let routeLine = MGLPolyline(coordinates: userCoordinates, count: UInt(userCoordinates.count))
            mapView.add(routeLine)
        }

    }
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation and add it to the map
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Start navigation"
        mapView.addAnnotation(annotation)
        
        // Calculate the route from the user's location to the set destination
        calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
    }
    
    // Calculate route to be used for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (Route?, Error?) -> ()) {
        
        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        
        // Specify that the route is intended for automobiles avoiding traffic
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // Draw the route on the map after creating it
            self.drawRoute(route: self.directionsRoute!)
        }
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route’s coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and width
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = NSExpression(forConstantValue: 4)
            
            // Add the source and style layer of the route line to the map
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // Present the navigation view controller when the callout is selected
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        let navigationViewController = NavigationViewController(for: directionsRoute!)
        self.present(navigationViewController, animated: true, completion: nil)
    }

}
