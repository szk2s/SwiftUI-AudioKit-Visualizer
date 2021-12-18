//
//  AmplitudeVisualizer.swift
//  Visualizer
//
//  Created by Macbook on 7/30/20.
//  Copyright © 2020 Matt Pfeiffer. All rights reserved.
//

import SwiftUI

struct AmplitudeVisualizerMetal : View {

  var conductor: Conductor
    
  var body: some View {
      
    HStack(spacing: 0.0) {
        MetalView(conductor: conductor)
    }
    .background(Color.black)
  }
}

//struct AmplitudeVisualizer_Previews: PreviewProvider {
//  static var previews: some View {
//    AmplitudeVisualizerForEach(amplitudes: [0.2, 0.3, 0.1])
//  }
//}
