import UIKit
import SceneKit
import ARKit
import PDFKit

class ModeController: UIViewController {
    
 
    @IBOutlet weak var piano: UIButton!
    @IBOutlet weak var handfreemode: UIButton!
    @IBOutlet weak var labmode: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    var analysis = ""

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
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
    
    
    // control logic of AR, based ARFaceAnchor
    func expression(anchor: ARFaceAnchor) {
        
        // request decimal value of part of face
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        let jaw = anchor.blendShapes[.jawOpen]
        let eyeLeft = anchor.blendShapes[.eyeLookInLeft]
        self.analysis = ""
        
        // Facial Analysis
        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 1.2 {
            self.analysis += "You are smiling. "
            DispatchQueue.main.async {
                self.handfreemode.sendActions(for: .touchUpInside)
                self.sceneView.session.pause()
                return
            }
            return
        }
        
        if cheekPuff?.decimalValue ?? 0.0 > 0.6 {
            self.analysis += "Your cheeks are puffed. "
            DispatchQueue.main.async {
                self.labmode.sendActions(for: .touchUpInside)
                self.sceneView.session.pause()
                return
            }
            return
        }

        if tongue?.decimalValue ?? 0.0 > 0.9 {
            self.analysis += "Your tongue out! "
            DispatchQueue.main.async {
                self.piano.sendActions(for: .touchUpInside)
                self.sceneView.session.pause()
                return
            }
            return
        }
        
        //eyeball tracking
        print("eyeLefe:", eyeLeft?.decimalValue ?? (Any).self,"eyeRight",anchor.blendShapes[.eyeLookInRight] ?? (Any).self)
        if(jaw?.decimalValue ?? 0.0 > 0.8 && eyeLeft?.decimalValue ?? 0.0 > 0.25){
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

extension ModeController: ARSCNViewDelegate{
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
            
        }
    }

}
