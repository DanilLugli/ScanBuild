
import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

struct SCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = SCNView
    
    var scnView = SCNView(frame: .zero)
    var handler = HandleTap()
    
    var cameraNode = SCNNode()
    var massCenter = SCNNode()
    var delegate = RenderDelegate()
    var dimension = SCNVector3()
    
    var rotoTraslation: [RotoTraslationMatrix] = []
    var origin = SCNNode()
    @State var rotoTraslationActive: Int = 0
    
    init() {
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
    }
    
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.camera = SCNCamera()
        
        // Posiziona la camera sopra il massCenter
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
        
        // Configura la camera per la vista ortografica dall'alto
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        
        // Ruota la camera per guardare verso il basso
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
        
        // Crea una luce direzionale (opzionale)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        // Imposta la camera come punto di vista
        scnView.pointOfView = cameraNode
        
        // Rimuovi il LookAtConstraint per evitare che la camera ruoti
        cameraNode.constraints = []
    }
    
    func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    func drawContent(borders: Bool) {
        print(borders)
        
        // Crea un set per tracciare gli oggetti già disegnati
        var drawnNodes = Set<String>()
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: { n, _ in
                n.name != nil && n.name! != "Room" && n.name! != "Floor0" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach {
                // Verifica se il nodo è già stato disegnato
                guard let nodeName = $0.name, !drawnNodes.contains(nodeName) else {
                    return // Se l'oggetto è già stato disegnato, passa al successivo
                }
                
                let material = SCNMaterial()
                if nodeName == "Floor0" {
                    material.diffuse.contents = UIColor.green
                } else {
                    material.diffuse.contents = UIColor.black
                    if nodeName.prefix(5) == "Floor" {
                        material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
                    }
                    if nodeName.prefix(6) == "Transi" {
                        print("Disegno: \(nodeName)")
                        print("Tipo: \($0.geometry)")
                        material.diffuse.contents = UIColor.red
                        material.fillMode = .lines
                    }
                    if nodeName.prefix(4) == "Door" || nodeName.prefix(4) == "Open" {
                        material.diffuse.contents = UIColor.green
                    }
                    material.lightingModel = .physicallyBased
                    $0.geometry?.materials = [material]
                    
                    if borders {
                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                        $0.scale.y = (nodeName.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                    }
                }
                
                // Aggiungi il nome del nodo al set dopo averlo disegnato
                drawnNodes.insert(nodeName)
            }
    }
    
    func loadRoomMaps(room: Room, borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            print("PIPPo")
            addDoorNodesBasedOnExistingDoors(room: room)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    func loadFloorPlanimetry(borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    //    func drawOrigin(_ o: SCNVector3,_ color: UIColor, _ size: CGFloat, _ addY: Bool = false) {
    //
    //        let sphere = generateSphereNode(color, size)
    //        sphere.name = "Origin"
    //
    //        print("Origin Drawn")
    //        print(sphere.worldTransform)
    //
    //        sphere.simdWorldPosition = simd_float3(o.x, o.y, o.z)
    //
    //        print(sphere.worldTransform)
    //
    //        if let r = Model.shared.actualRoto{sphere.simdWorldTransform = simd_mul(sphere.simdWorldTransform, r.traslation)}
    //        sphere.worldPosition.y -= 1
    //        if addY {sphere.worldPosition.y += 1}
    //
    //        scnView.scene?.rootNode.addChildNode(sphere)
    //
    //    }
    
    func zoomIn() {cameraNode.camera?.orthographicScale -= 0.5}
    
    func zoomOut() {cameraNode.camera?.orthographicScale += 0.5}
    
    func moveMapUp() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso l'alto
        cameraNode.simdWorldPosition.z += 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso l'alto): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapDown() {
        
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        scnView.pointOfView = cameraNode
        
        cameraNode.simdWorldPosition.z -= 1.0
        
        print("Nuova posizione della camera (verso il basso): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapRight() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso l'alto
        cameraNode.simdWorldPosition.x += 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso l'alto): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapLeft() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso il basso
        cameraNode.simdWorldPosition.x -= 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso il basso): \(cameraNode.simdWorldPosition)")
    }
    
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes{
            if (n.worldPosition.x < X[0]) {X[0] = n.worldPosition.x}
            if (n.worldPosition.x > X[1]) {X[1] = n.worldPosition.x}
            if (n.worldPosition.z < Z[0]) {Z[0] = n.worldPosition.z}
            if (n.worldPosition.z > Z[1]) {Z[1] = n.worldPosition.z}
        }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        return massCenter
    }
    
    func setupCamera(cameraNode: SCNNode){
        cameraNode.camera = SCNCamera()
        
        scnView.scene?.rootNode.addChildNode(cameraNode)
        let wall = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! == "Wall0"
            })[0]
        
        print("root/Node -> \(scnView.scene!.rootNode.worldOrientation)")
        var X: [Float] = [1000000.0, -1000000.0]
        var Z: [Float] = [1000000.0, -1000000.0]
        
        let massCenter = SCNNode()
        
        scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
            .forEach{
                
                let material = SCNMaterial()
                material.diffuse.contents = ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") ? UIColor.white : UIColor.black
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                if ($0.worldPosition.x < X[0]) {X[0] = $0.worldPosition.x}
                if ($0.worldPosition.x > X[1]) {X[1] = $0.worldPosition.x}
                if ($0.worldPosition.z < Z[0]) {Z[0] = $0.worldPosition.z}
                if ($0.worldPosition.z > Z[1]) {Z[1] = $0.worldPosition.z}
                print("\(String(describing: $0.name)), \($0.worldPosition)")
            }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        cameraNode.worldPosition = massCenter.worldPosition
        cameraNode.worldPosition.y = 10
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 20
        cameraNode.rotation.y = wall!.rotation.y
        cameraNode.rotation.w = wall!.rotation.w
        // Create directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        
        scnView.scene?.rootNode.addChildNode(massCenter)
        
        let vConstraint = SCNLookAtConstraint(target: massCenter)
        cameraNode.constraints = [vConstraint]
        directionalLight.constraints = [vConstraint]
        
    }
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        drawContent(borders: false)
        if let _node = scnView.scene?.rootNode.childNodes(passingTest: { n,_ in n.name != nil && n.name! == nodeName }).first {
            let copy = _node.copy() as! SCNNode
            copy.name = "__selected__"
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            copy.geometry?.materials = [material]
            copy.worldPosition.y += 4
            copy.scale.x = _node.scale.x < 0.2 ? _node.scale.x + 0.1 : _node.scale.x
            copy.scale.z = _node.scale.z < 0.2 ? _node.scale.z + 0.1 : _node.scale.z
            scnView.scene?.rootNode.addChildNode(copy)
        }
    }
    
    // Aggiunta della SCNBox alla scena nel punto selezionato
    func addBox(at position: SCNVector3) {
        let box = SCNBox(width: 1.0, height: 2.0, length: 1.0, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = position
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue // Colore della scatola
        print("Aggiungo SCNBox alla posizione: \(position)")
        scnView.scene?.rootNode.addChildNode(boxNode)
    }
    
    // Metodo per gestire l'interazione e posizionare la scatola
    func handleTap(at location: CGPoint) {
        print("Tap rilevato in posizione: \(location)")
        
        let hitResults = scnView.hitTest(location, options: nil)
        if let hitResult = hitResults.first {
            let position = hitResult.worldCoordinates // Ottieni le coordinate del punto toccato
            print("Punto toccato nella scena: \(position)")
            
            // Aggiungi la scatola alla posizione toccata
            addBox(at: position)
        } else {
            // Se non c'è un nodo rilevato, aggiungi la scatola in una posizione predefinita
            print("Nessun nodo trovato, aggiungo scatola alla posizione 0,0,0")
            addBox(at: SCNVector3(0, 0, 0))
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        print("Creazione di SCNView e aggiunta dei riconoscitori di gesti")
        
        handler.scnView = scnView
        
        // Aggiunta del riconoscitore di tap
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // Aggiunta del riconoscitore di pinch
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        // Configura lo sfondo della scena
        scnView.backgroundColor = UIColor.black
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Qui puoi implementare eventuali aggiornamenti necessari per la vista.
    }
    
    func makeCoordinator() -> SCNViewContainerCoordinator {
        SCNViewContainerCoordinator(self)
    }
    
    func addDoorNodesBasedOnExistingDoors(room: Room) {
        
        let doorNodes = scnView.scene?.rootNode.childNodes(passingTest: { node, _ in
            if let nodeName = node.name {
                return (nodeName.hasPrefix("Door") || nodeName.hasPrefix("Opening")) && !nodeName.hasSuffix("_grp")
            }
            return false
        }) ?? []
        
        for doorNode in doorNodes {
            
            let doorWidth = doorNode.width
            let doorHeight = doorNode.height
            var doorDepth = doorNode.length
            
            let depthExtension: CGFloat = 0.6
            doorDepth += depthExtension
            
            let newDoorGeometry = SCNBox(width: doorWidth, height: doorHeight, length: doorDepth, chamferRadius: 0.0)
            
            let newDoorNode = SCNNode(geometry: newDoorGeometry)
            
            newDoorNode.transform = doorNode.transform
            
            let doorDirection = doorNode.simdWorldFront
            let inwardTranslation = SIMD3<Float>(doorDirection * Float(doorDepth / 2))
            
            newDoorNode.simdPosition = doorNode.simdPosition - inwardTranslation
            
            let nodeName = doorNode.name != nil ? "TransitionZone_\(doorNode.name!)" : "TransitionZone_Door"
            
            newDoorNode.name = nodeName
            
            scnView.scene?.rootNode.addChildNode(newDoorNode)
            
            let updateName = newDoorNode.name!.replacingOccurrences(of: "TransitionZone_", with: "")
            
            if !room.transitionZones.contains(where: { $0.name == updateName }) {
                print("AGGIUNGO \(updateName)")
                let transitionZones = TransitionZone(name: updateName, connection: Connection(name: ""))
                room.addTransitionZone(transitionZone: transitionZones)
                
            } else {
                print("Una TransitionZone con il nome \(nodeName) esiste già.")
            }
            print("Nuova porta aggiunta alla scena con nome \(newDoorNode.name!).")
        }
    }
    
    class SCNViewContainerCoordinator: NSObject {
        var parent: SCNViewContainer
        
        init(_ parent: SCNViewContainer) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = parent.cameraNode.camera else { return }
            
            if gesture.state == .changed {
                let newScale = camera.orthographicScale / Double(gesture.scale)
                camera.orthographicScale = max(5.0, min(newScale, 50.0))
                gesture.scale = 1
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.scnView)
            parent.cameraNode.position.x -= Float(translation.x) * 0.01
            parent.cameraNode.position.z += Float(translation.y) * 0.01
            gesture.setTranslation(.zero, in: parent.scnView)
        }
        
        // Gestore del tap per identificare il punto nella mappa
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: parent.scnView)
            print("LOCATION TAP: \(location)")
            parent.handleTap(at: location)
        }
    }
}



@available(iOS 17.0, *)
struct SCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewContainer()
    }
}

extension SCNQuaternion {
    func difference(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w
        )
    }
    
    func sum(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w
        )
    }
}

extension SCNVector3 {
    func difference(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z
        )
    }
    
    func sum(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z
        )
    }
    
    func rotateAroundOrigin(_ angle: Float) -> SCNVector3 {
        var a = Complex<Float>.i
        a.real = cos(angle)
        a.imaginary = sin(angle)
        var b = Complex<Float>.i
        b.real = self.x
        b.imaginary = self.z
        var position = a*b
        return SCNVector3(
            position.real,
            self.y,
            position.imaginary
        )
    }
}

extension SCNNode {
    
    var height: CGFloat { CGFloat(self.boundingBox.max.y - self.boundingBox.min.y) }
    var width: CGFloat { CGFloat(self.boundingBox.max.x - self.boundingBox.min.x) }
    var length: CGFloat { CGFloat(self.boundingBox.max.z - self.boundingBox.min.z) }
    
    var halfCGHeight: CGFloat { height / 2.0 }
    var halfHeight: Float { Float(height / 2.0) }
    var halfScaledHeight: Float { halfHeight * self.scale.y  }
}
