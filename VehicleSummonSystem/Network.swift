//
//  Network.swift
//  VehicleSummonSystem
//
//  Created by Justin.Dombecki on 11/19/20.
//  Copyright © 2020 Justin.Dombecki. All rights reserved.
//

import Foundation
import MapKit

struct NetworkStatus: Error {
    var success: Bool
    var error: Error?

    init(success: Bool, error: Error?) {
        self.success = success
        self.error = error
     }
}

struct Network {
    static let vehicle_ip = "http://192.168.99.5:8642"

    static func tryToSendCoordinate(_ coordinate: CLLocationCoordinate2D, callback: @escaping (NetworkStatus)->Void) {
        do {
            try sendCoordinate(coordinate, successCallback: {
                callback(NetworkStatus(success: true, error: nil))
            })
        } catch let error {
            callback(NetworkStatus(success: false, error: error))
        }
    }

    static func sendCoordinate(_ coordinate: CLLocationCoordinate2D, successCallback: @escaping ()->Void) throws {
        guard let url = URL(string: vehicle_ip) else { throw NetworkErrors.UrlUnusable }

        let throwClosure: (Error) throws -> Void = { error in
            throw error
        }

        let locationJson = [
            "coord" : [
                "lat" : coordinate.latitude,
                "long" : coordinate.longitude
            ]
        ]
        let locationData = try JSONSerialization.data(withJSONObject: locationJson, options: .prettyPrinted)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = locationData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                try? throwClosure(error)
            }
            successCallback()
        }
        task.resume()
    }

    enum NetworkErrors: Error {
        case UrlUnusable
        case ResponseUnusable

    }
}
