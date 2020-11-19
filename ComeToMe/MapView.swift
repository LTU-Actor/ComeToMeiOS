//
//  MapView.swift
//  ComeToMe
//
//  Created by Justin.Dombecki on 11/18/20.
//  Copyright © 2020 Justin.Dombecki. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var isLocationPermissionSettingsAppLinkPresented: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setCameraZoomRange(MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 1000), animated: true)
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.centerCoordinate = centerCoordinate
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var map: MapView
        var locationManager: CLLocationManager
        
        init(_ parent: MapView) {
            self.map = parent
            self.locationManager = CLLocationManager()
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            tryHandlingLocationPermissions(from: manager)
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            tryHandlingLocationPermissions(from: manager)
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            updateCoordinate(
                locations.reduce(CLLocationCoordinate2D(), { (result, location) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude + result.latitude / 2.0,
                    longitude: location.coordinate.longitude + result.longitude / 2.0)
            }))
        }
        
        func updateCoordinate(_ coordinate: CLLocationCoordinate2D) {
            map.centerCoordinate = coordinate
        }
        
        func tryHandlingLocationPermissions(from manager: CLLocationManager) -> Void  {
            do {
                try handleLocationPermissions(from: manager)
            } catch let error {
                print(error)
                fatalError("location not usable")
            }
        }
        
        func handleLocationPermissions(from manager: CLLocationManager) throws -> Void  {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                map.isLocationPermissionSettingsAppLinkPresented = false
                guard let knownLocation = manager.location else { throw LocationsErrors.LocationNotUsable }

                updateCoordinate(knownLocation.coordinate); break
                
            case .notDetermined:
                locationManager.requestLocation()
                locationManager.requestWhenInUseAuthorization(); break
                
            case .restricted, .denied:
                map.isLocationPermissionSettingsAppLinkPresented = true; break
                
            @unknown default:
                fatalError("unknown values for permission")
            }
        }
        
        enum LocationsErrors: Error {
            case LocationNotUsable
        }
    }
}

extension MKPointAnnotation {
    static var example: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = "London"
        annotation.subtitle = "Home to the 2012 Summer Olympics."
        annotation.coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.13)
        return annotation
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(centerCoordinate: .constant(MKPointAnnotation.example.coordinate), isLocationPermissionSettingsAppLinkPresented: .constant(false))
    }
}
