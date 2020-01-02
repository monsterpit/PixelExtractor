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
    
    @IBOutlet weak var colorView: UIView!
    
    var frameExtractor: FrameExtractor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        frameExtractor = FrameExtractor()
        
        frameExtractor.delegate = self
    }

    
    private  func getPixelColorAtPoint(point: CGPoint, sourceView: UIView) -> UIColor {
        let pixel = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        context!.translateBy(x: -point.x, y: -point.y)

        sourceView.layer.render(in: context!)
        let color: UIColor = UIColor(red: CGFloat(pixel[0])/255.0,
                                     green: CGFloat(pixel[1])/255.0,
                                     blue: CGFloat(pixel[2])/255.0,
                                     alpha: CGFloat(pixel[3])/255.0)
        pixel.deallocate()
        return color
    }
    
      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
          if let firstTouch = touches.first{
              let point = firstTouch.location(in: self.view)
              colorView.backgroundColor = getPixelColorAtPoint(point: point, sourceView: imageView)
          }
      }
}

extension ViewController : FrameExtractorDelegate{
    func captured(image: UIImage) {
        imageView.image = image
    }
}
