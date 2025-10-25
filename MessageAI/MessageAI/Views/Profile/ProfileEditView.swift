//
//  ProfileEditView.swift
//  MessageAI
//
//  View for editing user profile
//

import SwiftUI
import PhotosUI

/// Profile editing view for updating name and photo
struct ProfileEditView: View {
    
    // MARK: - State Objects
    
    @StateObject private var viewModel = ProfileViewModel()
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    
    @State private var displayName: String = ""
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var showPhotoPickerSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // MARK: - Computed Properties
    
    private var characterCount: Int {
        displayName.count
    }
    
    private var isValid: Bool {
        characterCount >= Constants.Validation.displayNameMinLength &&
        characterCount <= Constants.Validation.displayNameMaxLength
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: AppTheme.largeSpacing) {
                        // Profile photo with camera icon
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(alignment: .bottomTrailing) {
                                    cameraIcon
                                }
                                .onTapGesture {
                                    showPhotoPickerSheet = true
                                }
                        } else {
                            ProfilePhotoView(
                                photoURL: viewModel.user?.profilePhotoURL,
                                displayName: displayName.isEmpty ? (viewModel.user?.displayName ?? "?") : displayName,
                                size: 120
                            ) {
                                showPhotoPickerSheet = true
                            }
                        }
                        
                        // Display name field
                        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                            Text("Display Name")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.primaryTextColor)
                            
                            TextField("Enter your name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                            
                            HStack {
                                Text("\(characterCount)/\(Constants.Validation.displayNameMaxLength)")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(isValid ? AppTheme.secondaryTextColor : AppTheme.errorColor)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, AppTheme.mediumSpacing)
                        
                        Spacer()
                    }
                    .padding(.top, AppTheme.largeSpacing)
                }
                
                // Upload progress overlay
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AppTheme.mediumSpacing) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                            
                            Text(viewModel.uploadProgress < 1.0 ? "Uploading..." : "Saving...")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(.white)
                        }
                        .padding(AppTheme.largeSpacing)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.mediumRadius)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!isValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showPhotoPickerSheet) {
                ProfilePhotoPicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let newValue = newValue {
                    print("🔄 ProfileEditView: Image selected, starting auto-save...")
                    Task {
                        await autoSaveProfilePhoto(newValue)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await viewModel.loadProfile(authService: authService)
                if let user = viewModel.user {
                    displayName = user.displayName
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Camera icon overlay
    private var cameraIcon: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primaryColor)
                .frame(width: 30, height: 30)
            
            Image(systemName: "camera.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .offset(x: -6, y: -6)
    }
    
    /// Photo picker view
    private var photoPickerView: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text("Select Photo")
        }
        .photosPickerStyle(.inline)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let newValue = newValue {
                    print("📸 Photo item selected, loading image...")
                    // Load the selected image
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        print("✅ Image loaded successfully, size: \(uiImage.size)")
                        selectedImage = uiImage
                        
                        // Auto-save the profile photo
                        await autoSaveProfilePhoto(uiImage)
                    } else {
                        print("❌ Failed to load image from selected item")
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Auto-saves profile photo when selected and closes the picker
    private func autoSaveProfilePhoto(_ image: UIImage) async {
        print("🔄 Starting auto-save profile photo...")
        do {
            // Upload the profile photo
            try await viewModel.uploadProfilePhoto(image: image, authService: authService)
            print("✅ Profile photo uploaded successfully, closing picker...")
            
            // Close the photo picker sheet first
            showPhotoPickerSheet = false
            
            // Small delay to ensure view model is updated, then clear selected image
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            selectedImage = nil
            
        } catch {
            print("❌ Failed to upload profile photo: \(error.localizedDescription)")
            // Show error but don't close the picker so user can try again
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    /// Saves profile changes
    private func saveProfile() async {
        do {
            // Only upload photo if selected and not already auto-saved
            // (auto-save clears selectedImage, so if it's still set, we need to upload)
            if let image = selectedImage {
                print("🔄 Save: Uploading selected image...")
                try await viewModel.uploadProfilePhoto(image: image, authService: authService)
                // Small delay to ensure view model is updated, then clear selected image
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                selectedImage = nil
            } else {
                print("✅ Save: No new image to upload (already auto-saved)")
            }
            
            // Update display name if changed
            if let user = viewModel.user, displayName != user.displayName {
                print("🔄 Save: Updating display name...")
                try await viewModel.updateProfile(displayName: displayName, authService: authService)
            } else {
                print("✅ Save: Display name unchanged")
            }
            
            // Dismiss on success
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - PhotoPicker View Wrapper

/// Custom photo picker for better UX
struct ProfilePhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfilePhotoPicker
        
        init(_ parent: ProfilePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print("📸 ProfilePhotoPicker: Photo selection completed")
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { 
                print("❌ ProfilePhotoPicker: No valid image provider found")
                parent.dismiss()
                return 
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ ProfilePhotoPicker: Failed to load image: \(error.localizedDescription)")
                        self.parent.dismiss()
                        return
                    }
                    
                    if let uiImage = image as? UIImage {
                        print("✅ ProfilePhotoPicker: Image loaded successfully, size: \(uiImage.size)")
                        self.parent.selectedImage = uiImage
                        self.parent.dismiss()
                    } else {
                        print("❌ ProfilePhotoPicker: Failed to cast to UIImage")
                        self.parent.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(AuthService())
}

