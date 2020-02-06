//
//  ViewController.swift
//  DocumentScanner
//
//  Created by Karthick Selvaraj on 01/08/19.
//  Copyright © 2019 Mallow Technologies private limited. All rights reserved.
//

import UIKit
import VisionKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var docPreviewImageView: UIImageView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var resultLabel: UILabel!
    
    var recognisedTexts: String?

    
    // MARK: - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        #warning("Assigned image for testing. Remove this line to play with live images from document camera controller")
        docPreviewImageView.image = UIImage(named: "Vision")
        
        showScannedImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if docPreviewImageView.image == nil {
            scanButton.setTitle("Scan document", for: .normal)
        } else {
            scanButton.setTitle("Analyse document", for: .normal)
        }
    }
    
    
    // MARK: - Button action methods
    @IBAction func scanDocumentButtonPressed(_ sender: Any) {
        if docPreviewImageView.image == nil {
            // Present document camera controller to scan the documents
            openCameraController()
        } else {
            process(image: docPreviewImageView.image!)
        }
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetData()
    }
    
    
    // MARK: - Custom methods
    
    func openCameraController() {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = self
        present(scannerVC, animated: true, completion: nil)
    }
    
    func process(image: UIImage) {
        guard let imageData = image.pngData() else { return }
        let requestHandler = VNImageRequestHandler(data: imageData, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            self.recognisedTexts = ""
            self.recognisedTexts?.append("Recognised texts:\n\n")
            for observation in observations {
                let candtidates = observation.topCandidates(1)
                for candidate in candtidates {
                    self.recognisedTexts?.append("\(candidate.string)(\(candidate.confidence))\n")
                    self.populateLabel()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                self.activityIndicator?.stopAnimating()
            }
        }
        
        // Showing progress of text recognition from the given image.
        request.progressHandler = { (request, completed, error) in
            DispatchQueue.main.async {
                self.hideScannedImage()
                self.recognisedTexts = ""
                self.resultLabel.text = "Recognising..\((Int(completed * 100)))%"
            }
        }
        request.recognitionLevel = .accurate // Using accurate recognition level to process static scanned images
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.1 // Minimum image height is the fraction of the image height. I want to process texts which are at least 10% of image height, remaining texts are ignored.
        
        self.activityIndicator?.isHidden = false
        self.activityIndicator?.startAnimating()
        DispatchQueue.global(qos: .userInteractive).async {
            try? requestHandler.perform([request])
        }
    }
    
    func resetData() {
        activityIndicator?.stopAnimating()
        scanButton.setTitle("Scan document", for: .normal)
        docPreviewImageView.image = nil
        resultLabel.text = nil
    }
    
    func showScannedImage() {
        docPreviewImageView.isHidden = false
        resultLabel.isHidden = true
    }
    
    func hideScannedImage() {
        docPreviewImageView.isHidden = true
        resultLabel.isHidden = false
    }
    
    func populateLabel() {
        DispatchQueue.main.async {
            self.hideScannedImage()
            self.recognisedTexts = self.recognisedTexts?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.resultLabel.text = self.recognisedTexts
        }
    }
    
}


extension ViewController: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let scannedImage = scan.imageOfPage(at: scan.pageCount - 1)
        docPreviewImageView.image = scannedImage
        showScannedImage()
        controller.dismiss(animated: true, completion: nil)
    }
    
}
