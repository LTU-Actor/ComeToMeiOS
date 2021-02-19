//
//  MapView.swift
//  VehicleSummonSystem
//
//  Created by Justin.Dombecki on 11/18/20.
//  Copyright © 2020 Justin.Dombecki. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    @Binding var centerCoord: CLLocationCoordinate2D
    @Binding var locationCoordinate: CLLocationCoordinate2D
    @Binding var isLocationPermissionSettingsAppLinkPresented: Bool
    @Binding var isLocationFollowingEnabled: Bool
    @Binding var isFirstTimeShowingMap: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        print(mapView.userLocation.coordinate)
        mapView.setCameraZoomRange(MKMapView.CameraZoomRange(minCenterCoordinateDistance: 100,
                                                             maxCenterCoordinateDistance: 600), animated: true)
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if (isLocationFollowingEnabled || isFirstTimeShowingMap) {
            view.centerCoordinate = locationCoordinate
            print("setting center: \(view.userLocation.coordinate)")
        }
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var map: MapView
        var locationManager: CLLocationManager
        var centerCoord: CLLocationCoordinate2D?

        init(_ parent: MapView) {
            self.map = parent
            self.locationManager = CLLocationManager()
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        }
        
        func updateFirstMapLoadComplete() {
            guard map.centerCoord.isOrigin() else { return }
            map.isFirstTimeShowingMap = false
            map.centerCoord = map.locationCoordinate
        }

        /// MKMapViewDelegate
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            centerCoord = mapView.centerCoordinate
        }

        /// CLLocationManagerDelegate
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
            locationManager.requestLocation()
        }
        
        /// Coordinating Coordinates
        
        func updateCoordinate(_ coordinate: CLLocationCoordinate2D) {
            if CLLocationCoordinate2DIsValid(coordinate) {
                print(coordinate)
                updateFirstMapLoadComplete()
                map.locationCoordinate = coordinate
                updateCenter()
            }
        }
        
        func updateCenter() {
            guard let centerCoord = centerCoord else { return }
            map.centerCoord = centerCoord
        }
        
        /// Coordinating Permissions
        
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

                updateCoordinate(knownLocation.coordinate)
                locationManager.requestLocation(); break
                
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

extension CLLocationCoordinate2D {
    func isOrigin() -> Bool {
        return self.latitude != 0.0 && self.longitude != 0.0
    }
}

/// Preview

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
        MapView(centerCoord: .constant(MKPointAnnotation.example.coordinate),
                locationCoordinate: .constant(MKPointAnnotation.example.coordinate),
                isLocationPermissionSettingsAppLinkPresented: .constant(false),
                isLocationFollowingEnabled: .constant(true),
                isFirstTimeShowingMap: .constant(true))
    }
}
