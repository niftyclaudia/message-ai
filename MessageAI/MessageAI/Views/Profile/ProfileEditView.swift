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
                                displayName: displayName.isEmpty ? "?" : displayName,
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
    
    
    // MARK: - Private Methods
    
    /// Saves profile changes
    private func saveProfile() async {
        // Prevent double-saves
        guard !viewModel.isLoading else { return }
        
        do {
            // Upload photo if selected
            if let image = selectedImage {
                try await viewModel.uploadProfilePhoto(image: image, authService: authService)
            }
            
            // Update display name if changed
            if let user = viewModel.user, displayName != user.displayName {
                try await viewModel.updateProfile(displayName: displayName, authService: authService)
            }
            
            // Wait a moment for Firebase to propagate the changes
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Dismiss on success
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
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
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    ProfileEditView()
        .environmentObject(AuthService())
}

