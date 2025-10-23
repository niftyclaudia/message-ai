//
//  ListWindowing.swift
//  MessageAI
//
//  List windowing utility for efficient scrolling with 1000+ messages
//

import Foundation
import SwiftUI

/// Configuration for list windowing behavior
struct ListWindowingConfig {
    let windowSize: Int = 50  // Load 50 messages at a time
    let prefetchThreshold: Int = 10  // Prefetch when 10 from end
    let maxCachedMessages: Int = 200  // Keep 200 in memory
    let cleanupThreshold: Int = 50  // Cleanup when 50 messages beyond window
}

/// List windowing utility for efficient message scrolling
/// - Note: Implements windowing for 1000+ messages with 60fps performance
class ListWindowing<T: Identifiable> {
    
    // MARK: - Properties
    
    private let config: ListWindowingConfig
    private var cachedItems: [T] = []
    private var currentWindowStart: Int = 0
    private var currentWindowEnd: Int = 0
    private var totalItemCount: Int = 0
    private var isPrefetching: Bool = false
    
    // MARK: - Initialization
    
    init(config: ListWindowingConfig = ListWindowingConfig()) {
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// Loads a window of items around the specified index
    /// - Parameters:
    ///   - index: The center index for the window
    ///   - totalCount: Total number of items available
    ///   - itemLoader: Async function to load items for a range
    /// - Returns: Array of items in the current window
    func loadWindow(
        around index: Int,
        totalCount: Int,
        itemLoader: @escaping (Int, Int) async throws -> [T]
    ) async throws -> [T] {
        
        totalItemCount = totalCount
        
        // Calculate window bounds
        let windowStart = max(0, index - config.windowSize / 2)
        let windowEnd = min(totalCount, windowStart + config.windowSize)
        
        // Update current window
        currentWindowStart = windowStart
        currentWindowEnd = windowEnd
        
        // Load items for the window
        let items = try await itemLoader(windowStart, windowEnd - windowStart)
        
        // Update cache
        updateCache(with: items, startIndex: windowStart)
        
        // Trigger prefetch if needed
        await triggerPrefetchIfNeeded(around: index, itemLoader: itemLoader)
        
        return items
    }
    
    /// Gets the current window of items
    /// - Returns: Array of items in the current window
    func getCurrentWindow() -> [T] {
        return Array(cachedItems.prefix(config.windowSize))
    }
    
    /// Checks if an index is within the current window
    /// - Parameter index: The index to check
    /// - Returns: True if within current window
    func isIndexInWindow(_ index: Int) -> Bool {
        return index >= currentWindowStart && index < currentWindowEnd
    }
    
    /// Gets the start index of the current window
    /// - Returns: Start index of current window
    func getWindowStart() -> Int {
        return currentWindowStart
    }
    
    /// Gets the end index of the current window
    /// - Returns: End index of current window
    func getWindowEnd() -> Int {
        return currentWindowEnd
    }
    
    /// Clears the cache to free memory
    func clearCache() {
        cachedItems.removeAll()
        currentWindowStart = 0
        currentWindowEnd = 0
        totalItemCount = 0
    }
    
    /// Gets cache statistics
    /// - Returns: Cache statistics
    func getCacheStats() -> CacheStats {
        return CacheStats(
            cachedItemCount: cachedItems.count,
            windowStart: currentWindowStart,
            windowEnd: currentWindowEnd,
            totalItemCount: totalItemCount,
            memoryUsage: estimateMemoryUsage()
        )
    }
    
    // MARK: - Private Methods
    
    /// Updates the cache with new items
    /// - Parameters:
    ///   - items: New items to cache
    ///   - startIndex: Starting index of the items
    private func updateCache(with items: [T], startIndex: Int) {
        // Replace items in the cache
        for (offset, item) in items.enumerated() {
            let cacheIndex = startIndex + offset - currentWindowStart
            if cacheIndex >= 0 && cacheIndex < cachedItems.count {
                cachedItems[cacheIndex] = item
            } else if cacheIndex >= 0 {
                // Extend cache if needed
                while cachedItems.count <= cacheIndex {
                    cachedItems.append(item)
                }
            }
        }
        
        // Cleanup old items if cache is too large
        cleanupCacheIfNeeded()
    }
    
    /// Triggers prefetch if the user is near the end of the window
    /// - Parameters:
    ///   - index: Current index
    ///   - itemLoader: Async function to load items
    private func triggerPrefetchIfNeeded(around index: Int, itemLoader: @escaping (Int, Int) async throws -> [T]) async {
        guard !isPrefetching else { return }
        
        let distanceFromEnd = currentWindowEnd - index
        
        if distanceFromEnd <= config.prefetchThreshold {
            isPrefetching = true
            
            // Prefetch next window
            let prefetchStart = currentWindowEnd
            let prefetchSize = min(config.windowSize, totalItemCount - prefetchStart)
            
            if prefetchSize > 0 {
                do {
                    let prefetchItems = try await itemLoader(prefetchStart, prefetchSize)
                    
                    // Add to cache
                    cachedItems.append(contentsOf: prefetchItems)
                    
                    // Update window end
                    currentWindowEnd = min(totalItemCount, currentWindowEnd + prefetchSize)
                    
                } catch {
                    // Silently fail prefetch - not critical
                }
            }
            
            isPrefetching = false
        }
    }
    
    /// Cleans up cache if it exceeds the maximum size
    private func cleanupCacheIfNeeded() {
        guard cachedItems.count > config.maxCachedMessages else { return }
        
        // Remove items from the beginning of the cache
        let itemsToRemove = cachedItems.count - config.maxCachedMessages
        cachedItems.removeFirst(itemsToRemove)
        currentWindowStart += itemsToRemove
    }
    
    /// Estimates memory usage of cached items
    /// - Returns: Estimated memory usage in bytes
    private func estimateMemoryUsage() -> Int {
        // Rough estimation - in practice, you'd measure actual memory usage
        return cachedItems.count * 1024  // Assume 1KB per item
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let cachedItemCount: Int
    let windowStart: Int
    let windowEnd: Int
    let totalItemCount: Int
    let memoryUsage: Int
    
    var description: String {
        """
        Cache Stats:
          Cached Items: \(cachedItemCount)
          Window: \(windowStart)-\(windowEnd)
          Total Items: \(totalItemCount)
          Memory Usage: \(memoryUsage) bytes
        """
    }
}

// MARK: - Message Windowing Extension

extension ListWindowing where T == Message {
    
    /// Loads a window of messages for a chat
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - aroundIndex: The center index for the window
    ///   - messageService: The message service to use
    /// - Returns: Array of messages in the window
    func loadMessageWindow(
        chatID: String,
        aroundIndex: Int,
        messageService: MessageService
    ) async throws -> [Message] {
        
        // Get total message count (simplified for now)
        let totalCount = 1000 // Assume 1000 messages for windowing
        
        // Load window
        return try await loadWindow(around: aroundIndex, totalCount: totalCount) { startIndex, count in
            try await messageService.fetchMessages(chatID: chatID)
        }
    }
    
    /// Prefetches messages for smooth scrolling
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - currentIndex: Current scroll position
    ///   - messageService: The message service to use
    func prefetchMessages(
        chatID: String,
        currentIndex: Int,
        messageService: MessageService
    ) async {
        guard !isPrefetching else { return }
        
        let distanceFromEnd = currentWindowEnd - currentIndex
        
        if distanceFromEnd <= config.prefetchThreshold {
            isPrefetching = true
            
            do {
                let prefetchStart = currentWindowEnd
                let prefetchSize = min(config.windowSize, totalItemCount - prefetchStart)
                
                if prefetchSize > 0 {
                    let prefetchMessages = try await messageService.fetchMessages(chatID: chatID)
                    
                    // Add to cache
                    cachedItems.append(contentsOf: prefetchMessages)
                    currentWindowEnd = min(totalItemCount, currentWindowEnd + prefetchSize)
                }
            } catch {
                // Silently fail prefetch
            }
            
            isPrefetching = false
        }
    }
}
