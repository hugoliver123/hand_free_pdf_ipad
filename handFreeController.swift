import UIKit
import ARKit
import PDFKit

class handFreeController: UIViewController {

    private var pdfdocument: PDFDocument?
    private var pdfview: PDFView!
    private var isPdfExsist: Bool = true
    private var isTestEnable: Bool = true
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var faceLabel: UILabel!
    @IBOutlet weak var labelView: UIView!
    var analysis = ""

    
    @IBOutlet weak var modeKeyText: UIButton!
    @IBAction func modeKey(_ sender: UIButton) {
        if(isTestEnable == true){
            isTestEnable = false
            print("test close")
            modeKeyText.setTitle("Test mode: DISABLED", for: .normal)
            
            if(isPdfExsist == false){
                
                if Thread.current.isMainThread {
                    self.view.addSubview(self.pdfview)
                    } else {
                        DispatchQueue.main.async {
                            self.view.addSubview(self.pdfview)
                            return
                        }
                    }
                
            }
            isPdfExsist = true
            
        }else{
            isTestEnable = true
            print("test open")
            modeKeyText.setTitle("Test mode:  ENABLED", for: .normal)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelView.layer.cornerRadius = 10
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func openPDF(sandboxURL:URL){
        //load pdf view
        pdfview = PDFView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        pdfdocument = PDFDocument(url: sandboxURL)
        pdfview.document = pdfdocument
        pdfview.displayMode = .singlePage
        pdfview.autoScales = true
        pdfview.usePageViewController(true, withViewOptions: nil)
        view.addSubview(pdfview)
    }
    
    
    // The following three method is switch to main theath and setting pdf view
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
    
    // control logic of AR, based ARFaceAnchor
    func expression(anchor: ARFaceAnchor) {
        self.analysis = ""
        
        // request decimal value of part of face
        let jaw = anchor.blendShapes[.jawOpen]
        let eyeLeft = anchor.blendShapes[.eyeLookInLeft]
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        
        // Facial Analysis
        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.98 {
            self.analysis += "You are smiling. "
            if(isPdfExsist == true){
                if(pdfview.canGoToNextPage){
                    safeToNextPage()
                    print("next avl, go next")
                }else{
                    safeToFirstPage()
                    print("next unavl, go first")
                }
                sleep(2)
            }
        }
        
        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Your cheeks are puffed. "
            if(isPdfExsist == true && isTestEnable == true){
                isPdfExsist = false
                print("puff, enter test mode")
                if Thread.current.isMainThread {
                    self.pdfview.removeFromSuperview()
                    } else {
                        DispatchQueue.main.async {
                            self.pdfview.removeFromSuperview()
                            return
                        }
                    }
            }else{
                isPdfExsist = true
                self.analysis += "Your cheeks are puffed. "
                print("puff, exit test mode")
                if Thread.current.isMainThread {
                    self.view.addSubview(self.pdfview)
                    } else {
                        DispatchQueue.main.async {
                            self.view.addSubview(self.pdfview)
                            return
                        }
                    }
            }
            sleep(1)
        }
        
        if tongue?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Your tongue out! "
            if(isPdfExsist == true){
                safeToPreviousPage()
                print("tongue out, previous")
                sleep(2)
            }
        }
        
        //eyeball tracking for exit purpose.
        if(jaw?.decimalValue ?? 0.0 > 0.8 && eyeLeft?.decimalValue ?? 0.0 > 0.1){
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

}

extension handFreeController: ARSCNViewDelegate{
    // ARSCNViewDelegate, this is an general stype of delegate, no need to change.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.fillMode = .lines
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)

            DispatchQueue.main.async {
                self.faceLabel.text = self.analysis
            }
        }
    }
}

