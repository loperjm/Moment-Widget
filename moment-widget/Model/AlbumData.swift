//
//  AlbumData.swift
//  moment-widget
//
//  Created by Walter J on 2022/11/06.
//

import Foundation
import Photos

struct AlbumData: Identifiable {
  let id: String?
  let name: String
  let count: Int
  let album: PHFetchResult<PHAsset>
}
