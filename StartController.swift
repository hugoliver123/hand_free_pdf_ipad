import Foundation
import UIKit
import AVFoundation
import Vision
import MobileCoreServices


class StartController: UIViewController {

    @IBOutlet weak var goNext: UIButton!
    @IBOutlet weak var tipNum: UILabel!
    @IBOutlet weak var fileAdd: UILabel!
    @IBOutlet weak var choosenFileName: UILabel!
    @IBOutlet weak var tableviewController: UITableView!
    
    @IBAction func goNextAction(_ sender: UIButton) {
        forwardPage(contentsOfPath: getContentsOfPath())
    }
    
    private var fileNo = 1
    private var cameraFeedSession: AVCaptureSession?
    //Video capture session. It is the bridge between input and output. It coordinates the transfer of data from intput to output
    let captureSession = AVCaptureSession()
    //setting Video input devices
    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
    private let videoDataOutputQueue = DispatchQueue(
      label: "CameraFeedOutput",
      qos: .userInteractive
    )
    
    //call VNDetction for human hand-pose
    var fingerTips: [CGPoint] = []
    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
      let request = VNDetectHumanHandPoseRequest()
      request.maximumHandCount = 2
      return request
    }()
    
    //setting table view
    func getContentsOfPath() ->[String]? {
        let homePath = NSHomeDirectory() //get home path
        var contentsOfPath = try? FileManager.default.contentsOfDirectory(atPath: homePath + "/Documents")  //return list of file in documents
        for (idx, tmp) in contentsOfPath!.enumerated(){
            if(tmp.suffix(3) != "pdf"){     //restrict extension with ".pdf"
                contentsOfPath!.remove(at: idx)
            }
        }
        return contentsOfPath
    }

    func settingVideoLayer(){
        //Adding video input devices
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice!)
        self.captureSession.addInput(videoInput)
        
        //Use the AVCaptureVideoPreviewLayer to display the live camera footage on the ViewController.
        let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        //Setting the video signal output
        let dataOutput = AVCaptureVideoDataOutput()
        if self.captureSession.canAddOutput(dataOutput) {
          self.captureSession.addOutput(dataOutput)
          dataOutput.alwaysDiscardsLateVideoFrames = true
          dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
        }
        
        //Loading a movie stream layer
        view.layer.insertSublayer(videoLayer, at: 0)
        //start session
        self.captureSession.startRunning()
    }
    
    func forwardPage(contentsOfPath:[String]?){
        DispatchQueue.main.async {
            self.captureSession.stopRunning()
            return
        }
        if(fileNo == 0){
            print(contentsOfPath![0])
        }else{
            print(contentsOfPath![fileNo-1])
        }
        
        
        //Remove all pdf files from the library directory to prevent confusion
        let documentsUrl =  FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "pdf" {
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch  { print(error) }
        
        //Copy selected files to lib
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var selectedUrl = url.appendingPathComponent(contentsOfPath![0])
        if(fileNo != 0){
            selectedUrl = url.appendingPathComponent(contentsOfPath![fileNo-1])
        }
        let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let sandboxURL = dir.appendingPathComponent("PdfItem.pdf")
        do{
            try FileManager.default.copyItem(at: selectedUrl!, to: sandboxURL)
        }catch{
            print("copy error")
        }
        
        print("file: ", fileNo)
    }
    
    func createAlert (title: String, message: String, oneOption: Bool){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(ACTION) in alert.dismiss(animated: true, completion: nil)}))
        if(oneOption == false){
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(ACTION) in alert.dismiss(animated: true, completion: nil)}))
        }
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func openPDF(_ sender: UIButton) {
        //Select and copy the file to be opened to the document directory
        let fileController = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        fileController.delegate = self
        fileController.allowsMultipleSelection = false
        present(fileController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        tableviewController.reloadData()
        settingVideoLayer()
    }

    override func viewDidAppear(_ animated: Bool) {
        if(getContentsOfPath()?.count == 0){
            let url = Bundle.main.url(forResource: "defalt_pdf", withExtension: "pdf")
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let sandboxURL = dir.appendingPathComponent("PdfItem.pdf")
            do{
                try FileManager.default.copyItem(at: url!, to: sandboxURL)
            }catch{
                print("copy error")
            }
        }
        
        tableviewController.delegate = self
        tableviewController.dataSource = self
        let contentsOfPath = getContentsOfPath()
        print(contentsOfPath as Any)
        self.fileAdd.text = String(contentsOfPath!.count)
        self.captureSession.startRunning()
        self.fileNo = 0
        tipNum.text = "0"
        if(self.fileNo == 0){
            self.choosenFileName.text = String(contentsOfPath![0])
        }else{
            self.choosenFileName.text = String(contentsOfPath![self.fileNo-1])
        }
    }
}

extension StartController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("you touch index:", indexPath[1])
        let indicator = indexPath[1]+1
        fileNo = indicator
        tipNum.text = String(indicator)
        choosenFileName.text = getContentsOfPath()![indicator-1]
    }
}

extension StartController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getContentsOfPath()!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = getContentsOfPath()![indexPath.row]
        return cell
    }
}

extension StartController: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first else{
            return
        }

        //Show files in the document directory
        let contentsOfPath = getContentsOfPath()
        print(contentsOfPath as Any)
        print(contentsOfPath?.count as Any)
        
        
        if(contentsOfPath!.count >= 8){ //There are already 8 documents in the file Update document
            //Delete all pdf files in the document directory to prevent confusion
            
            let alert = UIAlertController(title: "Container Full", message: "Import new file will refreash the container, continue?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(ACTION) in alert.dismiss(animated: true, completion: {
                let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
                do {
                    let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                               includingPropertiesForKeys: nil,
                                                                               options: .skipsHiddenFiles)
                    for fileURL in fileURLs {
                        if fileURL.pathExtension == "pdf" {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    }
                } catch  { print(error) }
                
                let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let sandboxURL = dir.appendingPathComponent(selectedUrl.lastPathComponent)
                do{
                    try FileManager.default.copyItem(at: selectedUrl, to: sandboxURL)
                }catch{
                    print("copy error")
                    self.createAlert(title: "Import failed", message: "This file already exists", oneOption: true)
                }
                let newContentsOfPath = self.getContentsOfPath()
                self.fileAdd.text = String(newContentsOfPath!.count)
                self.tableviewController.reloadData()
                self.fileNo = 0
                self.tipNum.text = String(self.fileNo)
                self.choosenFileName.text = self.getContentsOfPath()![0]
                
            })}))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(ACTION) in alert.dismiss(animated: true, completion: nil)}))
            
            self.present(alert, animated: true, completion: nil)
            
            return
        }
       

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sandboxURL = dir.appendingPathComponent(selectedUrl.lastPathComponent)
        do{
            try FileManager.default.copyItem(at: selectedUrl, to: sandboxURL)
        }catch{
            print("copy error")
            createAlert(title: "Import failed", message: "This file already exists", oneOption: true)
        }
        let newContentsOfPath = getContentsOfPath()
        fileAdd.text = String(newContentsOfPath!.count)
        self.tableviewController.reloadData()
        fileNo = 0
        tipNum.text = String(fileNo)
        choosenFileName.text = getContentsOfPath()![0]

    }
}

extension
StartController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
      _ output: AVCaptureOutput,
      didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection
    ) {
        //Read file information
        let contentsOfPath = getContentsOfPath()
        
        // handler of hand detection
        let handler = VNImageRequestHandler(
        cmSampleBuffer: sampleBuffer,
        orientation: .up,
        options: [:]
      )

      do { // if not found hands
        try handler.perform([handPoseRequest])

        guard
          let results = handPoseRequest.results?.prefix(2),
          !results.isEmpty
        else {
          return
        }
          
          // analyse CGPoint result
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

          DispatchQueue.main.async {
              self.tipNum.text = String(self.fileNo)
              if(self.fileNo == 0){
                  self.choosenFileName.text = String(contentsOfPath![0])
              }else{
                  self.choosenFileName.text = String(contentsOfPath![self.fileNo-1])
              }
              return
          }


          print(keyN)

          if(fingerTips.count > 5){
              DispatchQueue.main.async {
                  self.goNext.sendActions(for: .touchUpInside)
                  return
              }
              forwardPage(contentsOfPath: contentsOfPath)
              sleep(1)
          }
          if(fingerTips.count >= 4){
              if(fileNo>=contentsOfPath!.count){
                  fileNo = 0
              }
              fileNo += 1
              sleep(1)
          }
      } catch {
        cameraFeedSession?.stopRunning()
      }
    }
}
