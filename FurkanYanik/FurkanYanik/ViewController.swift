//
//  ViewController.swift
//  FurkanYanik
//
//  Created by Furkan Yanik on 25.03.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mkMap: MKMapView!
    @IBOutlet var btnTracker: UIButton!
    @IBOutlet var btnStart: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var btnReset: UIButton!
    
    var locationManager: CLLocationManager!
    var userLocations: [CLLocation] = []
    var lastLocation: CLLocation?
    var isUserTrackingEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
        loadUserLocations()
        drawUserRoute()
    }
    
    @IBAction func btnStart(_ sender: Any) {
        locationManager.startUpdatingLocation()
        btnStart.backgroundColor = UIColor.gray
        btnStop.backgroundColor = UIColor.white
        btnTracker.backgroundColor = UIColor.gray
        isUserTrackingEnabled = true
    }
    
    @IBAction func btnStop(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        btnStart.backgroundColor = UIColor.white
        btnStop.backgroundColor = UIColor.gray
        btnTracker.backgroundColor = UIColor.white
        isUserTrackingEnabled = false
    }
    
    @IBAction func btnReset(_ sender: Any) {
        userLocations.removeAll()
        mkMap.removeOverlays(mkMap.overlays)
        mkMap.removeAnnotations(mkMap.annotations)
        saveUserLocations()
        
        btnStart.backgroundColor = UIColor.white
        btnTracker.backgroundColor = UIColor.white
        btnStop.backgroundColor = UIColor.white
    }
    
    @IBAction func btnSeeLocation(_ sender: Any) {
        
        if isUserTrackingEnabled {
            isUserTrackingEnabled = false
            btnTracker.backgroundColor = UIColor.white
        } else {
            isUserTrackingEnabled = true
            btnTracker.backgroundColor = UIColor.gray
        }
        if let location = locationManager.location {
            render(location)
        }
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        if let location = locationManager.location {
            render(location)
        }
        mkMap.delegate = self
        mkMap.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        if let lastLocation = lastLocation, lastLocation.distance(from: newLocation) >= 1 {
            addMarker(at: newLocation)
            userLocations.append(newLocation)
            saveUserLocations()
            self.lastLocation = newLocation
            drawUserRoute()
        } else if lastLocation == nil {
            lastLocation = newLocation
        }
        
        if isUserTrackingEnabled {
            let center = CLLocationCoordinate2D(latitude: lastLocation?.coordinate.latitude ?? 0, longitude: lastLocation?.coordinate.longitude ?? 0)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mkMap.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "MyPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coordinate = view.annotation?.coordinate else { return }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                return
            }

            if let placemark = placemarks?.first {
                let address = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality, placemark.administrativeArea, placemark.country].compactMap { $0 }.joined(separator: "\n")
                
                let detailLabel = UILabel()
                detailLabel.numberOfLines = 0
                detailLabel.text = address
                view.detailCalloutAccessoryView = detailLabel
            }
        }
    }
    
    func addMarker(at location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mkMap.addAnnotation(annotation)
    }
    
    func saveUserLocations() {
        let locationsData = userLocations.map { ["latitude": $0.coordinate.latitude, "longitude": $0.coordinate.longitude] }
        UserDefaults.standard.set(locationsData, forKey: "UserLocations")
    }
    
    func loadUserLocations() {
        guard let locationsData = UserDefaults.standard.array(forKey: "UserLocations") as? [[String: Double]] else { return }
        userLocations = locationsData.map {
            CLLocation(latitude: $0["latitude"]!, longitude: $0["longitude"]!)
        }
        
        for location in userLocations {
            addMarker(at: location)
        }
    }
    
    func drawUserRoute() {
        let coordinates = userLocations.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mkMap.addOverlay(polyline)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func render(_ location: CLLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01 )
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mkMap.setRegion(region, animated: true)
    }
}

