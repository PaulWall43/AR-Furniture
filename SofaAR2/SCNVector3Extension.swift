//
//  SCNVector3Extension.swift
//  SofaAR2
//
//  Created by Paul Wallace on 1/4/18.
//  Copyright © 2018 Paul Wallace. All rights reserved.
//

import Foundation
import SceneKit
extension SCNVector3 {
    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }
    
    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
}
