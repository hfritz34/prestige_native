//
//  SpotifyPlaybackService.swift
//  Spotify Playback Integration
//
//  Handles opening Spotify content using deep links and web fallbacks.
//

import UIKit

class SpotifyPlaybackService {
    static let shared = SpotifyPlaybackService()
    private init() {}
    
    /// Play a track on Spotify
    /// - Parameter trackId: Spotify track ID
    func playTrack(_ trackId: String) {
        let spotifyAppURL = URL(string: "spotify://track/\(trackId)")
        let spotifyWebURL = URL(string: "https://open.spotify.com/track/\(trackId)")
        
        openSpotifyContent(appURL: spotifyAppURL, webURL: spotifyWebURL)
    }
    
    /// Open an album on Spotify
    /// - Parameter albumId: Spotify album ID
    func openAlbum(_ albumId: String) {
        // Clean the album ID in case it has extra formatting
        let cleanAlbumId = albumId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let spotifyAppURL = URL(string: "spotify://album/\(cleanAlbumId)")
        let spotifyWebURL = URL(string: "https://open.spotify.com/album/\(cleanAlbumId)")
        
        print("🔍 Album ID: '\(cleanAlbumId)'")
        print("🔍 Original Album ID: '\(albumId)'")
        
        openSpotifyContent(appURL: spotifyAppURL, webURL: spotifyWebURL)
    }
    
    /// Open an artist on Spotify
    /// - Parameter artistId: Spotify artist ID
    func openArtist(_ artistId: String) {
        let spotifyAppURL = URL(string: "spotify://artist/\(artistId)")
        let spotifyWebURL = URL(string: "https://open.spotify.com/artist/\(artistId)")
        
        openSpotifyContent(appURL: spotifyAppURL, webURL: spotifyWebURL)
    }
    
    /// Play content from PrestigeDisplayItem
    /// - Parameter item: The prestige item to play
    func playPrestigeItem(_ item: PrestigeDisplayItem) {
        playContent(spotifyId: item.spotifyId, type: item.contentType)
    }
    
    /// Play content from track response
    /// - Parameter track: UserTrackResponse containing track data
    func playTrack(from trackResponse: UserTrackResponse) {
        playTrack(trackResponse.track.id)
    }
    
    /// Open album from album response
    /// - Parameter album: UserAlbumResponse containing album data
    func openAlbum(from albumResponse: UserAlbumResponse) {
        openAlbum(albumResponse.album.id)
    }
    
    /// Open artist from artist response
    /// - Parameter artist: UserArtistResponse containing artist data
    func openArtist(from artistResponse: UserArtistResponse) {
        openArtist(artistResponse.artist.id)
    }
    
    // MARK: - Private Methods
    
    private func openSpotifyContent(appURL: URL?, webURL: URL?) {
        guard let appURL = appURL, let webURL = webURL else {
            print("❌ Invalid Spotify URLs - appURL: \(String(describing: appURL)), webURL: \(String(describing: webURL))")
            return
        }
        
        print("🎵 Attempting to open Spotify content:")
        print("   App URL: \(appURL)")
        print("   Web URL: \(webURL)")
        print("   Can open app URL: \(UIApplication.shared.canOpenURL(appURL))")
        
        if UIApplication.shared.canOpenURL(appURL) {
            // Spotify app is installed, use deep link
            print("🎵 Opening Spotify app...")
            UIApplication.shared.open(appURL) { success in
                print("🎵 Spotify app open result: \(success)")
                if !success {
                    print("❌ Failed to open Spotify app, falling back to web")
                    self.openWebFallback(webURL)
                }
            }
        } else {
            // Spotify app not installed, open in browser
            print("🎵 Spotify app not available, opening web fallback...")
            openWebFallback(webURL)
        }
    }
    
    private func openWebFallback(_ webURL: URL) {
        print("🌐 Opening web fallback: \(webURL)")
        UIApplication.shared.open(webURL) { success in
            print("🌐 Web fallback result: \(success)")
            if !success {
                print("❌ Failed to open Spotify web URL")
            }
        }
    }
}

// MARK: - Extensions for ContentType Detection

extension SpotifyPlaybackService {
    /// Determine content type and play accordingly
    /// - Parameters:
    ///   - spotifyId: Spotify ID
    ///   - contentType: Type of content (track, album, artist)
    func playContent(spotifyId: String, type: ContentType) {
        print("🎵 SpotifyPlaybackService: Playing content type: \(type), ID: \(spotifyId)")
        switch type {
        case .tracks:
            print("🎵 Playing track: \(spotifyId)")
            playTrack(spotifyId)
        case .albums:
            print("🎵 Opening album: \(spotifyId)")
            openAlbum(spotifyId)
        case .artists:
            print("🎵 Opening artist: \(spotifyId)")
            openArtist(spotifyId)
        }
    }
}