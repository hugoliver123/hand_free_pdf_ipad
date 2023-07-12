
import UIKit
import AVFoundation
import WebKit
import Vision
import PDFKit
import MobileCoreServices
 
class ViewController: UIViewController {
    private var pdfdocument: PDFDocument?
    private var pdfview: PDFView!
    private var cameraFeedSession: AVCaptureSession?
     
    @IBOutlet weak var cView: UIView!
    @IBOutlet weak var KeyNum: UILabel!
    
    private let videoDataOutputQueue = DispatchQueue(
      label: "CameraFeedOutput",
      qos: .userInteractive
    )
    
    var fingerTips: [CGPoint] = []
    
    
    //Video capture session. It is the bridge between input and output. It coordinates the transfer of data from intput to output
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
     
    override func viewDidLoad() {
        super.viewDidLoad()
        // add pdf viewer and load its file.
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            if let pathComponent = url.appendingPathComponent("PdfItem.pdf") {
                let filePath = pathComponent.path
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath) {
                    print("FILE AVAILABLE")
                    let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
                    let sandboxURL = dir.appendingPathComponent("PdfItem.pdf")
                    openPDF(sandboxURL: sandboxURL)
                } else {
                    print("FILE NOT AVAILABLE")
                    let url = Bundle.main.url(forResource: "defalt_pdf", withExtension: "pdf")
                    openPDF(sandboxURL: url!)
                }
            } else {
                print("FILE PATH NOT AVAILABLE")
                let url = Bundle.main.url(forResource: "defalt_pdf", withExtension: "pdf")
                openPDF(sandboxURL: url!)
            }
        settingVideoLayer()
    }
    
    
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
      
      let request = VNDetectHumanHandPoseRequest()
      request.maximumHandCount = 2
      return request
    }()
    
    func openPDF(sandboxURL:URL){
        //load pdf view by using pdfkit
        pdfview = PDFView(frame: CGRect(x: 0, y: 50, width: view.frame.width, height: view.frame.height))
        pdfdocument = PDFDocument(url: sandboxURL)
        pdfview.document = pdfdocument
        pdfview.displayMode = .singlePage
        pdfview.autoScales = true
        pdfview.usePageViewController(true, withViewOptions: nil)
        view.addSubview(pdfview)
    }
    
    func settingVideoLayer(){
        //add camera device
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice!)
        self.captureSession.addInput(videoInput)
        //Use the AVCaptureVideoPreviewLayer to display the live camera footage on the ViewController.
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.cView.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // video output (to handpose AI)
        let dataOutput = AVCaptureVideoDataOutput()
        if self.captureSession.canAddOutput(dataOutput) {
          self.captureSession.addOutput(dataOutput)
          dataOutput.alwaysDiscardsLateVideoFrames = true
          dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
        }
        //load video layer
        view.layer.addSublayer(videoLayer)
        //start
        self.captureSession.startRunning()
    }
}

extension
ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
      _ output: AVCaptureOutput,
      didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection
    ) {
      let handler = VNImageRequestHandler(
        cmSampleBuffer: sampleBuffer,
        orientation: .up,
        options: [:]
      )

      do {
        try handler.perform([handPoseRequest])

        guard
          let results = handPoseRequest.results?.prefix(2),
          !results.isEmpty
        else {
          return
        }

          var recognizedPoints: [VNRecognizedPoint] = []

          try results.forEach { observation in
            let fingers = try observation.recognizedPoints(.all)

            if let thumbTipPoint = fingers[.thumbTip] {
              recognizedPoints.append(thumbTipPoint)
            }
            if let indexTipPoint = fingers[.indexTip] {
              recognizedPoints.append(indexTipPoint)
            }
            if let middleTipPoint = fingers[.middleTip] {
              recognizedPoints.append(middleTipPoint)
            }
            if let ringTipPoint = fingers[.ringTip] {
              recognizedPoints.append(ringTipPoint)
            }
            if let littleTipPoint = fingers[.littleTip] {
              recognizedPoints.append(littleTipPoint)
            }
          }

          fingerTips = recognizedPoints.filter {
            // Ignore low confidence points.
            $0.confidence > 0.9
          }
          .map {
            CGPoint(x: $0.location.x, y: 1 - $0.location.y)
          }
          
          let keyN:String = String(fingerTips.count)
          print(keyN)
          
          
          if Thread.current.isMainThread {// switch to main thread, not in main thread, keep blank.
              } else {
                  DispatchQueue.main.async {
                      self.KeyNum.text = keyN
                      return
                  }
              }
          
          // if 9 or more key points found, exit
          if(fingerTips.count > 9){
              DispatchQueue.main.async {
                  self.navigationController?.popToRootViewController(animated: true)
              }
          }
          
          // flash hands, to next
          if(fingerTips.count > 2 && pdfview.canGoToNextPage){
              print("next page")
              if Thread.current.isMainThread { // switch to main thread
                  } else {
                      DispatchQueue.main.async {
                          self.pdfview.goToNextPage(self)
                          return
                      }
                  }
              
              sleep(2)
          } else if(fingerTips.count > 2 && !pdfview.canGoToNextPage){ // if at last page
              print("back first")
              if Thread.current.isMainThread {
                  } else {
                      DispatchQueue.main.async {
                          self.pdfview.goToFirstPage(NSObject.self)
                          return
                      }
                  }
              sleep(2)
          }
          
      } catch {
        // stop video session
        cameraFeedSession?.stopRunning()
      }
    }
}


// CGPoint distance calculator
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2) + pow((point.y - y), 2))
    }
}
