//
//  HeaderviewGradient.swift
//  Grapevine-130
//
//  Created by Kelsey Lieberman on 9/18/20.
//  Copyright © 2020 Anthony Humay. All rights reserved.
//

import SwiftUI

class HeaderView: UIView {
    var body: some View {
        AnimatedBackground().edgesIgnoringSafeArea(.all)
            .blur(radius: 50)
    }
}

struct AnimatedBackground: View {
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [Color.blue, Color.red, Color.purple, Color.pink, Color.yellow, Color.green, Color.orange]
    
    var body: some View {
        
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .animation(Animation.easeInOut(duration: 6).repeatForever())
            .onReceive(timer, perform: { _ in
                
                self.start = UnitPoint(x: 4, y: 0)
                self.end = UnitPoint(x: 0, y: 2)
                self.start = UnitPoint(x: -4, y: 20)
                self.start = UnitPoint(x: 4, y: 0)
            })
    }
}
