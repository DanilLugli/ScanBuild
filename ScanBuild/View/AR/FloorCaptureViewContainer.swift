import SwiftUI
import RoomPlan
import ARKit

struct FloorCaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView
    var arSession = ARSession()
    
    var sessionDelegate: SessionDelegate
    
    private let configuration: RoomCaptureSession.Configuration
    
    init(namedUrl: NamedURL) {
        print("Initializing FloorCaptureViewContainer")
        sessionDelegate = SessionDelegate(namedUrl: namedUrl)
        configuration = RoomCaptureSession.Configuration()
        
        if #available(iOS 17.0, *) {
            roomCaptureView = RoomCaptureView(frame: .zero, arSession: arSession)
        } else {
            roomCaptureView = RoomCaptureView(frame: .zero)
        }
        
        roomCaptureView.captureSession.delegate = sessionDelegate
        roomCaptureView.delegate = sessionDelegate
        roomCaptureView.captureSession.arSession.delegate = sessionDelegate
        
        sessionDelegate.setCaptureView(self) // Non è necessario il cast
    }
    
    func makeUIView(context: Context) -> RoomCaptureView {
        roomCaptureView.captureSession.run(configuration: configuration)
        return roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func stopCapture() {
        roomCaptureView.captureSession.stop()
        arSession.pause()
    }
    
    func continueCapture() {
        roomCaptureView.captureSession.run(configuration: configuration)
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        var finalResults: CapturedRoom?
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        @State var namedUrl: NamedURL
        
        init(namedUrl: NamedURL) {
            self.namedUrl = namedUrl
            self.currentMapName = namedUrl.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: FloorCaptureViewContainer) {
            // Se è necessaria una configurazione aggiuntiva
        }
        
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            if let error = error {
                print("Error in captureSession(_:didEndWith:error:)")
                print(error)
                return
            }
            
            Task {
                do {
                    let name = currentMapName ?? "ScannedRoom_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                    let finalRoom = try await self.roomBuilder.capturedRoom(from: data)
                    
                    // Salvataggio in formato USDZ
                    saveUSDZMap(finalRoom, name, at: namedUrl.url)
                    print("Room saved as USDZ at \(namedUrl.url)")
                    
                } catch {
                    print("Error during room capturing or saving: \(error)")
                }
            }
        }
        
        // Le altre funzioni delegate non necessarie sono state rimosse per semplificazione
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    }
}

struct FloorCaptureViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        FloorCaptureViewContainer(namedUrl: Room(name: "Sample Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: "")))
    }
}
