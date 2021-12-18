//
//  AmplitudeVisualizerMetalView.swift
//  Visualizer
//
//  Created by okuyama on 2021/12/16.
//

import Foundation
import MetalKit
import SwiftUI

struct AmplitudeVisualizerMetalView: NSViewRepresentable {
    var conductor: Conductor
    var amplitudes: [Double] {
        conductor.amplitudes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<AmplitudeVisualizerMetalView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }

        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }
    
    func updateNSView(_ uiView: MTKView, context: NSViewRepresentableContext<AmplitudeVisualizerMetalView>) {
        context.coordinator.draw(in: uiView);
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: AmplitudeVisualizerMetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        private let vertexData:[Float] = [
            -1,-1,0,1,
             1,-1,0,1,
             -1,1,0,1,
             1,1,0,1
        ]
        private let textureCoodinateData: [Float] = [0,1,
                                                     1,1,
                                                     0,0,
                                                     1,0];
        
        var vertexBuffer: MTLBuffer!
        var texCoordBuffer: MTLBuffer!
        var amplitudesBuffer: MTLBuffer!;
        var renderPipeline: MTLRenderPipelineState!
        
        
        private var startDate: Date!
        
        private func setupMetal(){
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
        }
        
        private func makeBuffers(){
            let size = vertexData.count * MemoryLayout<Float>.size
            vertexBuffer = metalDevice.makeBuffer(bytes:vertexData,length:size)
            texCoordBuffer = metalDevice.makeBuffer(bytes:textureCoodinateData, length:textureCoodinateData.count * MemoryLayout<Float>.size)
            
            amplitudesBuffer = metalDevice.makeBuffer(bytes:parent.amplitudes, length:parent.amplitudes.count*MemoryLayout<Double>.size);
        }
        
        private func makePipeline(){
            let library = metalDevice.makeDefaultLibrary()!;
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm;

            renderPipeline = try! metalDevice.makeRenderPipelineState(descriptor: descriptor)
        }
        
        
        
        init(_ parent: AmplitudeVisualizerMetalView) {
            self.parent = parent
            super.init()
            
            setupMetal();
            
            makeBuffers();
            makePipeline();
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        
        func updateSampleArrayBuffer(){
           //本来ならDoubleのArrayのままShaderに送れば（確実にできる）いいのだがよくわからなかったので、一旦Floatに変換している
            var floatAmplitudesArray: [Float] = []
            for i in 0..<150 {
                floatAmplitudesArray.append(Float(parent.amplitudes[i]))
            }
            amplitudesBuffer = metalDevice.makeBuffer(bytes:floatAmplitudesArray,length:floatAmplitudesArray.count * MemoryLayout<Float>.size)
            
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else {
                return
            }
            
            updateSampleArrayBuffer();
            
            let commandBuffer = metalCommandQueue.makeCommandBuffer()!
            
            let renderPassDescriptor = view.currentRenderPassDescriptor!
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.setRenderPipelineState(renderPipeline)
            
            renderEncoder?.setVertexBuffer(vertexBuffer, offset:0,index:0)
            renderEncoder?.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
            renderEncoder?.setFragmentBuffer(amplitudesBuffer,offset:0,index:0)
            
            renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder?.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
