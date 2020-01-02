//
//  FrameExtractor.swift
//  PixelExtractor
//
//  Created by Mojave on 02/01/20.
//  Copyright © 2020 Mojave. All rights reserved.
//

import UIKit
import AVFoundation

protocol FrameExtractorDelegate : class {
    func captured(image: UIImage)
}

class FrameExtractor : NSObject{
    
    //The session coordinates the flow of data from the input to the output.
    private let captureSession = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "session queue")
    
    //To track if user gave the permission for Camera or not.
    private var permissionGranted = false
    
    //Camera Position
    private let position = AVCaptureDevice.Position.back
    
    //Camera Quality keep
    private let quality = AVCaptureSession.Preset.medium
    
    private let context = CIContext()
    
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        
        checkPermission()
        sessionQueue.async { [unowned self] in
            
            self.configureSession()
            //The startRunning() method is a blocking call which can take some time, therefore you should perform session setup on a serial queue so that the main queue isn't blocked (which keeps the UI responsive)
            self.captureSession.startRunning()
        }
    }
    
    
    // MARK: AVSession configuration
    private func checkPermission() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
        
    private func requestPermission() {
        //because the call to requestAccess is asynchronous (on an arbitrary dispatch queue), we need to suspend the session queue and resume it once we get a result from the user.
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        
        guard let captureDevice = selectCaptureDevice() else { return }
        //Now that we have a valid capture device, we can try to create an AVCaptureDeviceInput. This is a class that manipulates in a concrete way the data captured by the camera.
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        //Check if the capture device input can be added to the session, and add it
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        
        
        //We now have to intercept each frame. AVCaptureVideoDataOutput is the class we’re going to use: it processes uncompressed frames from the video being captured.
        let videoOutput = AVCaptureVideoDataOutput()
        //The way AVCaptureVideoDataOutput works is by having a delegate object it can send each frame to
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        //we must get a connection from the video output and check if we can set the orientation the video. Also, if we’re using the front camera, the feed has to be mirrored.
        guard let connection = videoOutput.connection(with: .video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
        
    }
    
    //📽 Input
    //To choose the recording device we want to use, we need to setup an AVCaptureDevice.
    private func selectCaptureDevice() -> AVCaptureDevice? {
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position)
        
        return deviceDiscoverySession.devices.first
        
    }
    
}

extension FrameExtractor : AVCaptureVideoDataOutputSampleBufferDelegate{
        
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //print("Got a frame!")
        
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
        }
        
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        
        //Transform the sample buffer to a CVImageBuffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        //Create a CIImage from the image buffer
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        //Create a CIContext and create a CGImage from this context
        //let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        //Create and return the UIImage
        return UIImage(cgImage: cgImage)
    }
    
}
