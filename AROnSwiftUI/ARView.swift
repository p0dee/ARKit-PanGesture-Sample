import ARKit
import SwiftUI

struct ARView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARContentSceneView {
        return ARContentSceneView(frame: .null)
    }
    
    func updateUIView(_ uiView: ARContentSceneView, context: Context) {
    }    
}
