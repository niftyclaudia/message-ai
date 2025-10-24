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
    /// - Note: Center-crops to square before resizing, preserves orientation
    func resizeToSquare(size: CGFloat) -> UIImage? {
        // Fix orientation first to prevent rotation issues
        let fixedImage = fixOrientation()
        
        // Calculate square crop rect (center crop)
        let minDimension = min(fixedImage.size.width, fixedImage.size.height)
        let cropRect = CGRect(
            x: (fixedImage.size.width - minDimension) / 2,
            y: (fixedImage.size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        // Crop to square
        guard let cgImage = fixedImage.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        let squareImage = UIImage(cgImage: cgImage)
        
        // Resize to target size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            squareImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
    }
    
    /// Fixes image orientation by redrawing if needed
    /// - Returns: Image with corrected orientation
    /// - Note: Removes EXIF orientation metadata by baking it into pixels
    private func fixOrientation() -> UIImage {
        // If already in correct orientation, return self
        if imageOrientation == .up {
            return self
        }
        
        // Redraw image in correct orientation
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Draw the image with correct orientation
        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: newCGImage)
    }
}

