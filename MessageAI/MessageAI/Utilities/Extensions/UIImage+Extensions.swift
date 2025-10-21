//
//  UIImage+Extensions.swift
//  MessageAI
//
//  Image processing utilities for photo compression and resizing
//

import UIKit

extension UIImage {
    
    /// Compresses image to target size using JPEG compression
    /// - Parameter maxBytes: Maximum file size in bytes
    /// - Returns: Compressed image data, or nil if compression fails
    /// - Note: Iteratively reduces quality to meet size constraint
    func compress(to maxBytes: Int) -> Data? {
        // Start with high quality and reduce until size is acceptable
        var compression: CGFloat = 1.0
        var imageData = self.jpegData(compressionQuality: compression)
        
        // Iteratively reduce quality until under maxBytes
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    /// Resizes image to square dimensions with center cropping
    /// - Parameter size: Target side length in points
    /// - Returns: Resized square image, or nil if resizing fails
    /// - Note: Center-crops to square before resizing
    func resizeToSquare(size: CGFloat) -> UIImage? {
        // Calculate square crop rect (center crop)
        let minDimension = min(self.size.width, self.size.height)
        let cropRect = CGRect(
            x: (self.size.width - minDimension) / 2,
            y: (self.size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        // Crop to square
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        let squareImage = UIImage(cgImage: cgImage)
        
        // Resize to target size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
    }
}

