import ARKit

class AnchorPlane: SCNNode {
    
    let anchor: ARPlaneAnchor
    let extentNode: SCNNode
    
    init(anchor: ARPlaneAnchor, in sceneView: ARSCNView) {
        self.anchor = anchor
        let extentPlane: SCNPlane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        extentNode = SCNNode(geometry: extentPlane)
        extentNode.simdPosition = anchor.center
        extentNode.eulerAngles.x = -.pi / 2
        
        super.init()
        
        addChildNode(extentNode)
        
        setupExtentVisualStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupExtentVisualStyle() {
        extentNode.opacity = 0.6

        guard let material = extentNode.geometry?.firstMaterial
            else { fatalError("SCNPlane always has one material") }
        
        material.diffuse.contents = UIColor.systemYellow
    }
    
}
