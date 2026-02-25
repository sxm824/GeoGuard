//
//  AddressAutocompleteField.swift
//  GeoGuard
//
//  Created by Saleh Mukbil on 2026-02-25.
//

import SwiftUI
// TODO: Uncomment after adding GooglePlaces package
import GooglePlaces

struct AddressAutocompleteField: View {
    @Binding var address: String
    @Binding var city: String
    @Binding var country: String
    
    // TODO: Re-enable after GooglePlaces is added
    /*
    @State private var predictions: [GMSAutocompletePrediction] = []
    @State private var showingPredictions = false
    @FocusState private var isFocused: Bool
    
    private let placesClient = GMSPlacesClient.shared()
    */
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Temporary: Just a text field until GooglePlaces is added
            TextField("Street Address", text: $address)
                .textFieldStyle(.roundedBorder)
            
            Text("⚠️ Google Places SDK not yet installed. Add it to enable autocomplete.")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 4)
            
            /* TODO: Uncomment after GooglePlaces package is added
            TextField("Street Address", text: $address)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onChange(of: address) { oldValue, newValue in
                    if !newValue.isEmpty {
                        fetchPredictions(query: newValue)
                    } else {
                        predictions = []
                        showingPredictions = false
                    }
                }
            
            if showingPredictions && !predictions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(predictions, id: \.placeID) { prediction in
                        Button {
                            selectPrediction(prediction)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prediction.attributedPrimaryText.string)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(prediction.attributedSecondaryText?.string ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                        
                        if prediction.placeID != predictions.last?.placeID {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 4)
            }
            */
        }
    }
    
    /* TODO: Uncomment after GooglePlaces package is added
    private func fetchPredictions(query: String) {
        let filter = GMSAutocompleteFilter()
        filter.types = ["address"]
        
        placesClient.findAutocompletePredictions(
            fromQuery: query,
            filter: filter,
            sessionToken: nil
        ) { results, error in
            if let error = error {
                print("Autocomplete error: \(error.localizedDescription)")
                return
            }
            
            predictions = results ?? []
            showingPredictions = !predictions.isEmpty
        }
    }
    
    private func selectPrediction(_ prediction: GMSAutocompletePrediction) {
        // Fetch place details to get structured address
        placesClient.fetchPlace(
            fromPlaceID: prediction.placeID,
            placeFields: [.formattedAddress, .addressComponents],
            sessionToken: nil
        ) { place, error in
            if let error = error {
                print("Place details error: \(error.localizedDescription)")
                // Fallback: use the prediction text
                address = prediction.attributedPrimaryText.string
                showingPredictions = false
                isFocused = false
                return
            }
            
            guard let place = place else { return }
            
            // Set the full address
            address = place.formattedAddress ?? prediction.attributedPrimaryText.string
            
            // Extract city and country from address components
            if let components = place.addressComponents {
                for component in components {
                    if component.types.contains("locality") {
                        city = component.name
                    } else if component.types.contains("country") {
                        country = component.name
                    }
                }
            }
            
            showingPredictions = false
            isFocused = false
        }
    }
    */
}

struct ManualAddressFields: View {
    @Binding var city: String
    @Binding var country: String
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("City", text: $city)
                .textFieldStyle(.roundedBorder)
            
            TextField("Country", text: $country)
                .textFieldStyle(.roundedBorder)
        }
    }
}
