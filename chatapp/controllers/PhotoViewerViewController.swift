//
//  PhotoViewerViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 11/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {
    
    private let url: URL
    
    init(with url : URL){
        self.url = url
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView : UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
        
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "photo"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        view.addSubview(imageView)
        self.imageView.sd_setImage(with: self.url, completed: nil)

        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }

    
}
