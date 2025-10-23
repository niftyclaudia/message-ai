//
//  ProfilePhotoView.swift
//  MessageAI
//
//  Avatar view with camera icon for photo editing
//

import SwiftUI

/// Profile photo view with camera icon overlay for editing
struct ProfilePhotoView: View {
    
    // MARK: - Properties
    
    let photoURL: String?
    let displayName: String
    let size: CGFloat
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarView(
                photoURL: photoURL,
                displayName: displayName,
                size: size
            )
            
            // Camera icon overlay
            ZStack {
                Circle()
                    .fill(AppTheme.primaryColor)
                    .frame(width: size * 0.25, height: size * 0.25)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(.white)
            }
            .offset(x: -size * 0.05, y: -size * 0.05)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ProfilePhotoView(
        photoURL: nil,
        displayName: "John Doe",
        size: 120
    ) {
    }
}

