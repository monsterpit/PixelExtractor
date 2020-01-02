//
//  ViewController.swift
//  PixelExtractor
//
//  Created by Vikas Salian (MBFang) on 02/01/20.
//  Copyright © 2020 Vikas Salian (MBFang). All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var frameExtractor: FrameExtractor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        frameExtractor = FrameExtractor()
        
        frameExtractor.delegate = self
    }

}

extension ViewController : FrameExtractorDelegate{
    
    func captured(image: UIImage) {
        imageView.image = image
    }
    
}
