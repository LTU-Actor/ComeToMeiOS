//
//  ContentView.swift
//  ComeToMe
//
//  Created by Justin.Dombecki on 11/18/20.
//  Copyright © 2020 Justin.Dombecki. All rights reserved.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var centerCoordinate = CLLocationCoordinate2D()
    @State private var isLocationPermissionSettingsAppLinkPresented = false
    @State private var isNetworkErrorPresented = false
    @State private var networkStatus: NetworkStatus?
    
    var body: some View {
        ZStack {
            MapView(centerCoordinate: $centerCoordinate, isLocationPermissionSettingsAppLinkPresented: $isLocationPermissionSettingsAppLinkPresented)
                .edgesIgnoringSafeArea(.all)
            Circle()
                .fill(Color.blue)
                .opacity(0.3)
                .frame(width: 32, height: 32)
            VStack {
                HStack {
                    Button(action: {
                        Network.tryToSendCoordinate(centerCoordinate) { networkResult in
                            if !networkResult.success {
                                networkStatus = networkResult
                                isNetworkErrorPresented = true
                            }
                        }
                    }) {
                        Text("Come to Me")
                    }
                    .padding()
                    .font(.title)
                    .padding(.trailing)
                    Spacer()
                }
                Spacer()
            }
        }.alert(isPresented: $isLocationPermissionSettingsAppLinkPresented, content: {
            Alert(title: Text("Location Needed!"),
                  message: Text("Please, go to Settings and turn on the permissions"),
                  primaryButton: .default(Text("Settings"), action: {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                  }), secondaryButton: .cancel())
        })
        .alert(isPresented: $isNetworkErrorPresented, content: {
            Alert(title: Text("Network Error"),
                  message: Text("\(networkStatus?.error?.localizedDescription ?? "No message.")"),
                  dismissButton: .cancel())
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
