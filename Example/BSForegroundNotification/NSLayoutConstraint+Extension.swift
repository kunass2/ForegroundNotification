//
//  NSLayoutConstraint+Extension.swift
//  MySoberRoomMate
//
//  Created by Bartłomiej Semańczyk on 09/06/16.
//  Copyright © 2016 Railwaymen Sp. z.o.o. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    override public var description: String {
        return "id: \(identifier ?? ""), constant: \(constant)"
    }
}
