//
//  anchor = cpenyinye
//  this contentview is for iphone xr and iphone 11 that display in 11'
//

import SwiftUI
import RealityKit
import ARKit
import UIKit
import FocusEntity


struct ContentView : View {
    @State private var isPlacementEnable = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    @State var presentingAlert = false

    var body:
        some View{
        ZStack(alignment:.bottom){
            ARViewContainer(modelConfirmForPlacement: self.$modelConfirmedForPlacement)
            if self.isPlacementEnable
            {   Text("⚠️请问是否放置模型⚠️").foregroundColor(.white).frame(height:280)
                PlacementButtonView(isPlacementEnable: self.$isPlacementEnable, selectedModel: self.$selectedModel, modelConfirmForPlacement: self.$modelConfirmedForPlacement)   }
            else { VStack
                {
                Button("使用须知"){
                    self.presentingAlert.toggle()
                }
                
                .frame(height:45)
                .foregroundColor(.blue)
                Spacer()
                
                    
                } .alert(isPresented: $presentingAlert)
                            {
                                () -> Alert in Alert(title:Text("本App为广州工商学院\ncPen工作室参赛作品Demo\n\n由于使用了ARKit\n请使用带神经网络芯片(NPU)的设备运行"))
                             }
                Text("📲请进行空间扫描后 选择AR模型").foregroundColor(.white).frame(height:280)
            
            ModelPickerView(isPlacementEnable: self.$isPlacementEnable, selectedModel: self.$selectedModel, models: self.models)
            }
        }
    }
    
    
    
    var models : [Model] = {
        let fileManager = FileManager.default
        
        guard let path = Bundle.main.resourcePath,let files = try? fileManager.contentsOfDirectory(atPath: path)else{
            return []
        }
        
        var availableModels : [Model] = []
        for filename in files where
            filename.hasSuffix("usdz"){
            let modelname = filename.replacingOccurrences(of: ".usdz", with: "")
            
            let model = Model(modelName: modelname)
            availableModels.append(model)
        }
        return availableModels
        
    }()
     
    
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
//        let arView = ARView(frame: .zero)
//       使用了focusentity套件所以不用默认arview
//       默认arview没有预览视图
        let arView = CustomARView(frame: .zero)
        //重制arkit为focusentity插件
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        return arView

        
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {

        

        if let model = self.modelConfirmForPlacement
        {
        
            if let modelEntity  = model.modelEntity
           
            {
                print("debug:成功放置了模型 \(model.modelName)")
                
                let anchorEntity = AnchorEntity(plane:.any)
                
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                uiView.scene.addAnchor(anchorEntity)
            

            }
            //成功读取modelname并克隆于锚点上方
            
            else
            {
                print("debug:失败放置了模型 \(model.modelName)")
            }

            DispatchQueue.main.async {
                self.modelConfirmForPlacement = nil
            }
        }
    }
    
}




class CustomARView: ARView{
    let focusSquare = FESquare()
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        focusSquare.viewDelegate = self
        focusSquare.delegate = self
        focusSquare.setAutoUpdate(to: true)
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupARView(){
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal,.vertical]
        config.environmentTexturing = .automatic
        if #available(iOS 15.0, *) {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
                config.sceneReconstruction = .mesh
            }
        } else {
            // Fallback on earlier versions
        }
        self.session.run(config)
    }
}





extension CustomARView: FEDelegate{
    func toTrackingState() {
        print("tracking")
    }
    
    func toInitializingState() {
        print("iniitializing")
    }
}

struct ModelPickerView: View {
    @Binding var isPlacementEnable: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    var body: some View{
        
        ScrollView (.horizontal){
            HStack(spacing:22){

                ForEach(0 ..< self.models.count){
                    index in
                    Button(action: {
                        
                        self.selectedModel = self.models[index]
                        self.isPlacementEnable = true
                    }){
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height: 71)
                            .frame(width: 71)
                            .aspectRatio(1/1,contentMode: .fill)
                            .background(Color.white)
                            .cornerRadius(19)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
        }
        .padding(20)
        .background(Color.black.opacity(0.68))
        .cornerRadius(34)
        .frame(width: 390)
        .offset(x:0, y: -8)
        
        
        //没有做横竖屏适配，只是略过了长度
    }
}

struct PlacementButtonView: View {
    @Binding var isPlacementEnable: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmForPlacement: Model?
    var body: some View{
        HStack{
            // cancel Button
            Button(action: {
                
                self.resetPlacementParameters()
                //按下x重新进入函数
            }){
                Image(systemName: "xmark")
                    
                    .foregroundColor(.red)
                    .frame(width: 75, height: 75)
                    .font(.largeTitle)
                    .background(Color.black.opacity(0.72))
                    .cornerRadius(19)
                    .padding(10)
                    .offset(x: 0, y: -12)
            }
            
            //Confirm Button
            Button(action: {
                self.modelConfirmForPlacement = self.selectedModel   //这是他妈的🪝，已封装
                self.resetPlacementParameters()        //reset本体使用系统图片
            }){
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .frame(width:75, height: 75)
                    .font(.largeTitle)
                    .background(Color.black.opacity(0.72))
                    .cornerRadius(19)
                    .padding(10)
                    .offset(x: 0, y: -12)
            }
        }
    }
    
    //判断是否放置，有延迟
    func resetPlacementParameters() {
        self.isPlacementEnable = false
        self.selectedModel = nil
    }
}




extension UIAlertController {
    //在指定视图控制器上弹出普通消息提示框
    static func showAlert(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        viewController.present(alert, animated: true)
    }
}




#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
       
        ContentView()
    }
}
#endif
