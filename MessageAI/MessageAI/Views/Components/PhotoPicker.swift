//
//  PhotoPicker.swift
//  MessageAI
//
//  SwiftUI wrapper for native photo picker
//

import SwiftUI
import PhotosUI

/// SwiftUI wrapper for PhotosPicker to select images
struct PhotoPicker: View {
    
    // MARK: - Bindings
    
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    // MARK: - State
    
    @State private var selectedItem: PhotosPickerItem?
    
    // MARK: - Body
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text("Select Photo")
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
                isPresented = false
            }
        }
    }
}

