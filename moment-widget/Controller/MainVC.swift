//
//  ViewController.swift
//  moment-widget
//
//  Created by Walter J on 2022/11/06.
//

import UIKit
import Photos

class MainVC: UIViewController {
    
    //MARK: - IBOutlet
    @IBOutlet weak var albumList: UICollectionView!
    
    //컬렉션뷰 셀 간격을 정의한 enum클래스
    private enum Const {
        static let numberOfColumns = 4.0
        static let cellSpace = 1.0
        static let length = (UIScreen.main.bounds.size.width - cellSpace * (numberOfColumns - 1)) / numberOfColumns
        static let cellSize = CGSize(width: length, height: length)
        static let scale = UIScreen.main.scale
    }
    
    private var albums: [AlbumData] = []
    private var currentAlbumIndex = 1 {
        didSet {
            PhotoService.shared.getPHAssets(album: self.albums[self.currentAlbumIndex].album) { [weak self] phAssets in
                self?.phAssets = phAssets
            }
        }
    }
    private var currentAlbum: PHFetchResult<PHAsset>? {
        guard self.currentAlbumIndex <= self.albums.count - 1 else { return nil }
        return self.albums[self.currentAlbumIndex].album
    }
    private var phAssets = [PHAsset]() {
        didSet {
            DispatchQueue.main.async {
                self.albumList.reloadData()
            }
        }
    }
    
    //MARK: - viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        PhotoService.shared.delegate = self
        self.albumList.delegate = self
        self.albumList.dataSource = self
        
        //Set Title in NavigationController
        self.navigationBarSetUp()
        
        //Make Bar Buttons in NavigationController
        self.makeNavigationBarButtons()
        
        //Init CollectionView - albumList
        self.setUpCollectionView()
        
        self.requestAlbumAuthorization { isAuthorized in
            if isAuthorized {
                PhotoService.shared.getAlbums(mediaType: .image, completion: { [weak self] albums in
                    DispatchQueue.main.sync {
                        self?.albums = albums
                        self?.getPhotos()
                    }
                })
            } else {
                self.showAlertGoToSetting(
                    title: "현재 앨범 사용에 대한 접근 권한이 없습니다.",
                    message: "설정 > {앱 이름} 탭에서 접근을 활성화 할 수 있습니다."
                )
            }
        }
    }
    
    //PhotoService를 통해 앨범의 사진 가져오기
    private func getPhotos() {
        if !self.albums.isEmpty {
            PhotoService.shared.getPHAssets(album: self.albums[self.currentAlbumIndex].album) { [weak self] phAssets in
                self?.phAssets = phAssets
            }
        }
    }
    
    //앨범 접근 권한 요청
    func requestAlbumAuthorization(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                completion([.authorized, .limited].contains(where: { $0 == status }))
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        }
    }
    
    //오류 Alert
    func showAlertGoToSetting(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let cancelAlert = UIAlertAction(
            title: "취소",
            style: .cancel
        ) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        let goToSettingAlert = UIAlertAction(
            title: "설정으로 이동하기",
            style: .default) { _ in
                guard
                    let settingURL = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(settingURL)
                else { return }
                UIApplication.shared.open(settingURL, options: [:])
            }
        [cancelAlert, goToSettingAlert]
            .forEach(alertController.addAction(_:))
        DispatchQueue.main.async {
            self.present(alertController, animated: true) // must be used from main thread only
        }
    }
    
    //NavigationBar title 위치 지정
    private func navigationBarSetUp() {
        //스택뷰
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 0
        
        //타이틀
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.black
        titleLabel.text = "찰나의 순간"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        
        //부재
        let subTitleLabel = UILabel()
        subTitleLabel.textColor = UIColor.lightGray
        subTitleLabel.text = "사진메모 & 위젯"
        subTitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTitleLabel)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: stackView)
    }
    
    //Navigation Bar Button 이미지, 위치 및 Selector 연결
    private func makeNavigationBarButtons() {
        let calendarBtn = self.navigationItem.makeSFSymbolButton(
            self,
            action: #selector(showCalendar(_:)),
            symbolName: "calendar"
        )
        
        
        let sideMenuBtn = self.navigationItem.makeSFSymbolButton(
            self,
            action: #selector(showSideMenu(_:)),
            symbolName: "line.3.horizontal.decrease.circle"
        )

        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 13
        
        self.navigationItem.rightBarButtonItems = [sideMenuBtn, spacer, calendarBtn]
    }
    
    @objc
    private func showCalendar(_ sender: UINavigationItem) {
        
    }
    
    @objc
    private func showSideMenu(_ sender: UINavigationItem) {
        
    }
    
    //카메라 사용 권한 요청 응답 enum클래스
    private enum SessionSetUpResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private var setupResult: SessionSetUpResult = .notAuthorized
    
    //카메라 실행 버튼
    @IBAction func openCameraBtn(_ sender: UIButton) {
        //권한 확인 및 요청
        checkPermissionOfCamera()
    }
    
    //카메라 사용 권한 요청
    private func checkPermissionOfCamera() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined:
            print("권한 요청 전")
//            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.setupResult = .notAuthorized
                    }
                }
//                self.sessionQueue.resume()
            })
        case .authorized:
            print("승인된 상태")
            self.setupResult = .success
            self.openCamera()
            break
        default:
            //거부된 상태, 엑세스 불가 등
            setupResult = .notAuthorized
        }
    }
    
    // UIImagePickerController의 인스턴스 변수 생성
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    // 사진 저장 여부를 나타낼 변수
    var flagImageSave = false
    
    private func openCamera() {
        if setupResult != .success {
            return
        }
        
        // 카메라를 사용할 수 있다면(카메라의 사용 가능 여부 확인)
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            // 사진 저장 플래그를 true로 설정
            flagImageSave = true
            
            // 이미지 피커의 델리케이트 self로 설정
            imagePicker.delegate = self
            // 이미지 피커의 소스 타입을 camera로 설정
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = ["public.image"]
            
//            imagePicker.mediaTypes = ["public.movie"]     //비디오 촬영
//            imagePicker.videoQuality = .typeHigh
            
            // 편집을 허용하지 않음
            imagePicker.allowsEditing = false
            
            // 현재 뷰 컨트롤러를 imagePicker로 대체. 즉 뷰에 imagePicker가 보이게 함
            present(imagePicker, animated: true, completion: nil)
        } else {
            // 카메라를 사용할 수 없을 때는 경고창을 나타냄
//            alert("Camera inaccessable", message: "Application cannot access the camera.")
        }
    }
    
    //CollectionView 설정
    private func setUpCollectionView() {
        self.albumList.isScrollEnabled = true
        self.albumList.showsHorizontalScrollIndicator = false
        self.albumList.showsVerticalScrollIndicator = true
        self.albumList.contentInset = .zero
        self.albumList.backgroundColor = .clear
        self.albumList.clipsToBounds = true
        self.albumList.translatesAutoresizingMaskIntoConstraints = false
    }
}

//MARK: - UICollectionViewDataSource
extension MainVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.phAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //앨범 사진 Section에서 보여줄 Cell
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Keys.CellIds.albumListCell, for: indexPath) as? AlbumCell else { return UICollectionViewCell() }
        
        PhotoService.shared.fetchImage(
            asset: self.phAssets[indexPath.item],
            size: .init(width: Const.length * Const.scale, height: Const.length * Const.scale),
            contentMode: .aspectFit
        ) { [weak cell] image in
            DispatchQueue.main.async {
                cell?.prepare(image: image)
            }
        }
        return cell
    }
}

//MARK: - AddVC로 이동
extension MainVC: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Const.cellSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Const.cellSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = collectionView.cellForItem(at: indexPath)
        
        if let item = item {
            if let detailVC = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: Keys.VCIds.detailVC) as? DetailVC {

                let img = (item as! AlbumCell).getImage()
                detailVC.setImageToView(img: img)
                detailVC.modalPresentationStyle = .fullScreen
                present(detailVC, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Const.cellSize
    }
}

//MARK: - UIImagePicker... 확장
extension MainVC: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    //사진 처리
}

//MARK: - UINavigationBar 확장
extension UINavigationBar {
    func setBackgroundColor() {
        self.barTintColor = UIColor.white
        self.isTranslucent = false
    }
}

//MARK: - UINavigationItem 확장
extension UINavigationItem {
    func makeSFSymbolButton(_ target: Any?, action: Selector, symbolName: String) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.tintColor = .black
            
        let barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        barButtonItem.customView?.heightAnchor.constraint(equalToConstant: 24).isActive = true
        barButtonItem.customView?.widthAnchor.constraint(equalToConstant: 24).isActive = true
            
        return barButtonItem
    }
}

//MARK: - Bundle 확장
extension Bundle {
    /// 앱 이름
    class var appName: String {
        if let value = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return value
        }
        return ""
    }
    
    /// 앱 버전
    class var appVersion: String {
        if let value = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return value
        }
        return ""
    }
    
    /// 앱 빌드 버전
    class var appBuildVersion: String {
        if let value = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return value
        }
        return ""
    }
    
    /// 앱 번들 ID
    class var bundleIdentifier: String {
        if let value = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            return value
        }
        return ""
    }
}

//MARK: - PhotoService 확장
extension MainVC: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("change!")
    }
}
