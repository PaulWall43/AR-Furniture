//
//  ViewController+Extensions.swift
//  SofaAR2
//
//  Created by Paul Wallace on 1/4/18.
//  Copyright © 2018 Paul Wallace. All rights reserved.
//

import Foundation
import UIKit

extension ViewController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer {
            return true
        }
        return false
    }
}
