import UIKit
import AVFoundation
import WebKit
import Vision
import PDFKit
import MobileCoreServices
 
class LabController: UIViewController {
    private var pdfdocument: PDFDocument?
    private var pdfview: PDFView!
    private var cameraFeedSession: AVCaptureSession?
    private var shouldUpdatePDFScrollPosition = true
    private let pdfDrawer = PDFDrawer()
    private let videoDataOutputQueue = DispatchQueue(
      label: "CameraFeedOutput",
      qos: .userInteractive
    )
    
    var fingerTips: [CGPoint] = []
    
    @IBOutlet weak var cView: UIView!
    @IBOutlet weak var KeyNum: UILabel!
    

    let captureSession = AVCaptureSession()
    //setting video input device.
    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
     
    override func viewDidLoad() {
        super.viewDidLoad()
        //add pdf viewer and import pdf file.
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
        
        //add apple pencil drawing setting.
        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        pdfview.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = pdfview
    }
    
    
    // hand pose caller
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
      let request = VNDetectHumanHandPoseRequest()
      request.maximumHandCount = 1
      return request
    }()
    
    func openPDF(sandboxURL:URL){
        //load pdf view by PDFKit
        pdfview = PDFView(frame: CGRect(x: 0, y: 50, width: view.frame.width, height: view.frame.height))
        pdfdocument = PDFDocument(url: sandboxURL)
        pdfview.document = pdfdocument
        pdfview.displayMode = .singlePage
        pdfview.autoScales = true
        pdfview.usePageViewController(true, withViewOptions: nil)
        view.addSubview(pdfview)
    }
    
    //container of setting pdf layer
    func settingVideoLayer(){
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice!)
        self.captureSession.addInput(videoInput)
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.cView.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        let dataOutput = AVCaptureVideoDataOutput()
        if self.captureSession.canAddOutput(dataOutput) {
          self.captureSession.addOutput(dataOutput)
          dataOutput.alwaysDiscardsLateVideoFrames = true
          dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
        }
        view.layer.addSublayer(videoLayer)
        self.captureSession.startRunning()
    }
    
    // switch to main thread and change pdf view
    func safeToNextPage(){
        if Thread.current.isMainThread {
            self.pdfview.goToNextPage(self)
            } else {
                DispatchQueue.main.async {
                    self.pdfview.goToNextPage(self)
                    return
                }
            }
    }
    
    func safeToPreviousPage(){
        if Thread.current.isMainThread {
            self.pdfview.goToPreviousPage(self)
            } else {
                DispatchQueue.main.async {
                    self.pdfview.goToPreviousPage(self)
                    return
                }
            }
    }
    
    func safeToFirstPage(){
        if Thread.current.isMainThread {
            self.pdfview.goToFirstPage(self)
            } else {
                DispatchQueue.main.async {
                    self.pdfview.goToFirstPage(self)
                    return
                }
            }
    }
    
}

extension
LabController: AVCaptureVideoDataOutputSampleBufferDelegate {
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

              // Thumb
              if let thumbTipPoint = fingers[.thumbTip] {
                recognizedPoints.append(thumbTipPoint)
              }
              if let thumbMpPoint = fingers[.thumbMP]{
                recognizedPoints.append(thumbMpPoint)
              }
              if let thumbIpPoint = fingers[.thumbIP]{
                recognizedPoints.append(thumbIpPoint)
              }
              if let thumbCmcPoint = fingers[.thumbCMC]{
                recognizedPoints.append(thumbCmcPoint)
              }
              
              
              // index finger
              if let indexTipPoint = fingers[.indexTip] {
                recognizedPoints.append(indexTipPoint)
              }
              if let indexDipPoint = fingers[.indexDIP]{
                recognizedPoints.append(indexDipPoint)
              }
              if let indexPipPoint = fingers[.indexPIP]{
                recognizedPoints.append(indexPipPoint)
              }
              if let indexMcpPoint = fingers[.indexMCP]{
                recognizedPoints.append(indexMcpPoint)
              }
              
              
              
              // middle fingers
              if let middleTipPoint = fingers[.middleTip] {
                recognizedPoints.append(middleTipPoint)
              }
              if let middleDipPoint = fingers[.middleDIP]{
                recognizedPoints.append(middleDipPoint)
              }
              if let middlePipPoint = fingers[.middlePIP]{
                recognizedPoints.append(middlePipPoint)
              }
              if let middleMcpPoint = fingers[.middleMCP]{
                recognizedPoints.append(middleMcpPoint)
              }
              
              
              // ring fingers
              if let ringTipPoint = fingers[.ringTip] {
                recognizedPoints.append(ringTipPoint)
              }
              if let ringDipPoint = fingers[.ringDIP]{
                recognizedPoints.append(ringDipPoint)
              }
              if let ringPipPoint = fingers[.ringPIP]{
                recognizedPoints.append(ringPipPoint)
              }
              if let ringMcpPoint = fingers[.ringMCP]{
                recognizedPoints.append(ringMcpPoint)
              }
              
              // little fingers
              if let littleTipPoint = fingers[.littleTip] {
                recognizedPoints.append(littleTipPoint)
              }
              if let littleDipPoint = fingers[.littleDIP]{
                recognizedPoints.append(littleDipPoint)
              }
              if let littlePipPoint = fingers[.littlePIP]{
                recognizedPoints.append(littlePipPoint)
              }
              if let littleMcpPoint = fingers[.littleMCP]{
                recognizedPoints.append(littleMcpPoint)
              }
              
              // wrist
              if let wrist = fingers[.wrist]{
                recognizedPoints.append(wrist)
              }
              
          }

          fingerTips = recognizedPoints.filter {
            // Ignore low confidence points.
            $0.confidence > 0.85
          }
          .map {
            CGPoint(x: $0.location.x, y: 1 - $0.location.y)
          }
          
          let keyN:String = String(fingerTips.count)
          print(keyN)
          
          
          if Thread.current.isMainThread {
              
              } else {
                  DispatchQueue.main.async {
                      self.KeyNum.text = keyN
                      return
                  }
              }
          
          
          if(fingerTips.count >= 21 && pdfview.canGoToNextPage){
              if(recognizedPoints.last!.x > recognizedPoints.first!.x ){
                  print("wrist down, previous page")
                  safeToPreviousPage()
              }else{
                  print("wrist up, next page")
                  safeToNextPage()
              }
              sleep(2)
          } else if(fingerTips.count >= 21 && !pdfview.canGoToNextPage){
              if(recognizedPoints.last!.x > recognizedPoints.first!.x ){
                  print("wrist up, previous page")
                  safeToPreviousPage()
              }else{
                  print("back first page")
                  safeToFirstPage()
              }
              safeToFirstPage()
              sleep(2)
          }
          
      } catch {
        // stop session, if error.
        cameraFeedSession?.stopRunning()
      }
    }
}
