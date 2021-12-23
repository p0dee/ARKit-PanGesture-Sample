import ARKit

class ARContentSceneView: ARSCNView, ARSCNViewDelegate {
    
    private var anchorPlane: AnchorPlane?
    
    private var contentNode: SCNNode?
    
    private var lastLocationOfPan: CGPoint?
    
    private var gestureMarker: UIImageView = {
        let config = UIImage.SymbolConfiguration(font: .boldSystemFont(ofSize: 60))
        let ret = UIImageView(image: .init(systemName: "hand.point.up.left.fill", withConfiguration: config))
        ret.isHidden = true
        ret.tintColor = .blue
        return ret
    }()
    
    override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        autoenablesDefaultLighting = true
        delegate = self
        setUpSession()
        setUpGestures()
        addCoordinateAxisNodes()
        addGestureMarker()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravity
        session.run(configuration)
    }
    
    private func setUpGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(sender:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }
    
    private func addContentNode() {
        guard let anchorPlane = anchorPlane else { return }
        let size: CGFloat = 0.05
        do {
            let geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size / 5)
            let node = SCNNode(geometry: geometry)
            var pos = anchorPlane.convertPosition(anchorPlane.position, to: scene.rootNode)
            pos.y += (Float(size) / 2)
            node.position = pos
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            scene.rootNode.addChildNode(node)
            self.contentNode = node
        }
    }
    
    private func translateContentNode(diffX x: Float, y: Float) {
        guard let node = contentNode else { return }
        guard let cameraAngle = session.currentFrame?.camera.eulerAngles else { return }
        let scale = node.scale.x
        let distance = sqrt(x * x + y * y)
        let xcoef: Float = x > 0 ? 1 : -1
        guard distance > 0 else { return }
        let localRadCos: Float = y / distance
        let localRad = xcoef * acos(localRadCos)
        let pitchRad: Float = cameraAngle.y
        let current = node.position
        node.position = .init(current.x + distance * sin(localRad + pitchRad) * scale, current.y, current.z + distance * cos(localRad + pitchRad) * scale)
    }
    
    
    // MARK: Gesture handling
    
    @objc private func didTap(sender: UITapGestureRecognizer) {
        if contentNode != nil { return }
        addContentNode()
    }
    
    
    @objc private func didPan(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self)
        switch sender.state {
        case .began:
            lastLocationOfPan = location
        case .changed:
        if let lastLocation = lastLocationOfPan {
            translateContentNode(diffX: Float(location.x - lastLocation.x) / 1000, y: Float(location.y - lastLocation.y) / 1000)
            lastLocationOfPan = location
        }
        case .ended, .cancelled:
            lastLocationOfPan = nil
        default:
            break
        }
        updateGestureMarker()
    }
    
    // MARK: -
    
    private func addCoordinateAxisNodes() {
        let lineRad: CGFloat = 0.001
        let lineHeight: CGFloat = 0.05
        let coneHeight: CGFloat = 0.005
        //y
        let yAxisGeo = SCNCylinder(radius: lineRad, height: lineHeight)
        let yAxisNode = SCNNode(geometry: yAxisGeo)
        yAxisNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        yAxisNode.position = .init(0, lineHeight / 2, 0)
        scene.rootNode.addChildNode(yAxisNode)
        
        let yConeGeo = SCNCone(topRadius: 0, bottomRadius: lineRad * 2, height: coneHeight)
        let yConeNode = SCNNode(geometry: yConeGeo)
        yConeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        yConeNode.position = .init(0, lineHeight, 0)
        scene.rootNode.addChildNode(yConeNode)
        
        //z
        let zAxisGeo = SCNCylinder(radius: lineRad, height: lineHeight)
        let zAxisNode = SCNNode(geometry: zAxisGeo)
        zAxisNode.position = .init(0, 0, lineHeight / 2)
        zAxisNode.rotation = .init(1, 0, 0, Float.pi / 2)
        zAxisNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        scene.rootNode.addChildNode(zAxisNode)
        
        let zConeGeo = SCNCone(topRadius: 0, bottomRadius: lineRad * 2, height: coneHeight)
        let zConeNode = SCNNode(geometry: zConeGeo)
        zConeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        zConeNode.position = .init(0, 0, lineHeight)
        zConeNode.rotation = .init(1, 0, 0, Float.pi / 2)
        scene.rootNode.addChildNode(zConeNode)
        
        //x
        let xAxisGeo = SCNCylinder(radius: lineRad, height: lineHeight)
        let xAxisNode = SCNNode(geometry: xAxisGeo)
        xAxisNode.position = .init(lineHeight / 2, 0, 0)
        xAxisNode.rotation = .init(0, 0, 1, Float.pi / 2)
        xAxisNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        scene.rootNode.addChildNode(xAxisNode)
        
        let xConeGeo = SCNCone(topRadius: 0, bottomRadius: lineRad * 2, height: coneHeight)
        let xConeNode = SCNNode(geometry: xConeGeo)
        xConeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        xConeNode.position = .init(lineHeight, 0, 0)
        xConeNode.rotation = .init(0, 0, 1, -Float.pi / 2)
        scene.rootNode.addChildNode(xConeNode)
    }
    
    private func addGestureMarker() {
        addSubview(gestureMarker)
    }
    
    private func updateGestureMarker() {
        if let loc = lastLocationOfPan {
            gestureMarker.isHidden = false
            gestureMarker.frame.origin = loc
        } else {
            gestureMarker.isHidden = true
        }
    }
    
    // MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // すでに描画済みの検出平面があれば無視する
        if anchorPlane != nil { return }
        // 検出平面を描画する
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = AnchorPlane(anchor: planeAnchor, in: self)
        node.addChildNode(plane)
        anchorPlane = plane
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard let plane = node.childNodes.first as? AnchorPlane else { return }
        guard let extentGeometry = plane.extentNode.geometry as? SCNPlane else { return }
        
        extentGeometry.width = CGFloat(planeAnchor.extent.x)
        extentGeometry.height = CGFloat(planeAnchor.extent.z)
        plane.extentNode.simdPosition = planeAnchor.center
    }
}
