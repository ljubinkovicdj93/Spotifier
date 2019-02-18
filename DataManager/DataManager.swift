//
//  DataManager.swift
//  Spotifier
//
//  Created by Aleksandar Vacić on 5/8/18.
//  Copyright © 2018 Radiant Tap. All rights reserved.
//

import Foundation
import Marshal

final class DataManager {
	private var spotify: Spotify

	init(spotify: Spotify) {
		self.spotify = spotify
	}

	//	Local dummy cache

	private var artists: Set<Artist> = []
	private var albums: Set<Album> = []
	private var tracks: Set<Track> = []
	private var playlists: Set<Playlist> = []
}

extension DataManager {
	func search(for q: String,
				type: Spotify.SearchType,
				market: String? = nil,
				limit: Int? = nil,
				offset: Int? = nil,
				callback: @escaping ([SearchResult], DataError?) -> Void)
	{
		let path: Spotify.Endpoint = .search(q: q,
											 type: type,
											 market: market,
											 limit: limit,
											 offset: offset)
		spotify.call(endpoint: path) {
			[unowned self] json, spotifyError in

			//	validate
			if let spotifyError = spotifyError {
				print(spotifyError)
				callback([], .spotifyError(spotifyError))
				return
			}

			guard let json = json else {
				callback([], nil)
				return
			}

			//	process and convert into model object
			let result = self.processSearchResult(json, forSearchType: type)

			//	execute callback
			callback( result.items, result.dataError)
		}
	}

	func createPlaylist(_ playlist: Playlist,
						callback: ( Playlist?, DataError? ) -> Void)
	{

	}

	func removeTracks(_ tracks: [Track],
					  from playlist: Playlist,
					  callback: ( Playlist, DataError? ) -> Void)
	{

	}
}


private extension DataManager {
	func processSearchResult(_ json: JSON, forSearchType type: Spotify.SearchType) -> (items: [SearchResult], dataError: DataError?) {
		do {
			switch type {
			case .artist:
				let artists = try processArtists(from: json, at: "artists.items")
				return (Array(artists), nil)

			case .album:
				let albums = try processAlbums(from: json, at: "albums.items")
				return (Array(albums), nil)

			case .track:
				break
			case .playlist:
				break
			}
			return ([], nil)

		} catch let err as MarshalError {
			print(err)
			return ([], .jsonError(err))

		} catch let err {
			print(err)
			return ([], .generalError(err))

		}
	}

	func processArtists(from json: JSON, at key: String) throws -> Set<Artist> {
		let artists: Set<Artist> = try json.value(for: key)

		//	here, you should check what we already have in local cache
		//	then update those objects with possibly newer data
		//	+ anything that's new should be inserted
		//
		//	also write into CoreData or wherever
		//	for this training, simply just insert O:)
		self.artists.formUnion(artists)

		return artists
	}

	func processAlbums(from json: JSON, at key: String) throws -> Set<Album> {
		let albums: Set<Album> = try json.value(for: key)

		//	this JSON, for each album, also have the list of artists
		//	so naturally, we should check do we already have that Artist object in cache
		//	pick it up and connect with appropriate Album instance
		//	and vice-versa - add that Album instance to appropriate Artist.albums
		//	etc.
		//
		//	for this training, skipping that
		self.albums.formUnion(albums)

		return albums
	}
}