//
//  DetailVC.swift
//  moment-widget
//
//  Created by Walter J on 2022/11/06.
//

import UIKit
import SwiftUI
import SnapKit

class DetailVC: UIViewController {
    //MARK: - IBOutlet
    @IBOutlet weak var bigImgView: UIImageView!
    @IBOutlet weak var bottomMemoBtn: UIButton!
    
    private var albumImg: UIImage!
    
    //MARK: - ViewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let img = self.albumImg {
            self.bigImgView.image = img
        }
    }
    
    func setImageToView(img: UIImage) {
        self.albumImg = img
    }
    
    @IBAction func memoEditBtn(_ sender: UIButton) {
        createTextViewForMemo()
    }
    
    //키보드 위로 뜨는 텍스트뷰 만들기
    private func createTextViewForMemo() {
        //가장 큰 틀이 되는 stackView : vertical
        let backStackView = UIStackView()
        backStackView.axis = .vertical
        backStackView.alignment = .fill
        backStackView.distribution = .fill
        backStackView.spacing = 0
        backStackView.layer.cornerRadius = 10
        backStackView.layer.masksToBounds = true
        backStackView.backgroundColor = .darkGray
        backStackView.layer.opacity = 0.9
        
        let topStackView = UIStackView()
        topStackView.axis = .horizontal
        topStackView.alignment = .fill
        topStackView.distribution = .fill
        topStackView.spacing = 0
        topStackView.backgroundColor = .clear
        
        //topStackView에 들어갈 작성일 레이블, 즐겨찾기 버튼, 메모삭제 버튼
        let regDateLable = UILabel()
        regDateLable.text = "작성일 : ~~~"
        regDateLable.font = .systemFont(ofSize: 17)
        regDateLable.textColor = .white
        regDateLable.numberOfLines = 1
        
        let favoriteBtn = UIButton()
        favoriteBtn.setImage(UIImage(systemName: "star"), for: .normal)
        
        let deleteBtn = UIButton()
        deleteBtn.setTitle("메모 삭제", for: .normal)
        
        topStackView.addArrangedSubview(regDateLable)
        topStackView.addArrangedSubview(favoriteBtn)
        topStackView.addArrangedSubview(deleteBtn)
        
        //메모를 입력할 TextView
        let textView = UITextView()
        textView.backgroundColor = .clear
        
        backStackView.addArrangedSubview(topStackView)
        backStackView.addArrangedSubview(textView)
        
        self.view.addSubview(backStackView)
        
        backStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.bottomMemoBtn.snp.top).offset(-2)
            $0.width.equalTo(self.view.frame.width)
            $0.height.equalTo(200)
        }
        
        topStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(5)
//            $0.height.equalTo(25)
        }
    }
}
