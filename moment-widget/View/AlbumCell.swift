//
//  AlbumCell.swift
//  moment-widget
//
//  Created by Walter J on 2022/11/06.
//

import UIKit

class AlbumCell: UICollectionViewCell {
    @IBOutlet weak var imgView: UIImageView!
    
    func prepare(image: UIImage?) {
        guard let img = image else { return }
        self.imgView.image = img
    }
    
    func getImage() -> UIImage {
        return self.imgView.image!
    }
}
