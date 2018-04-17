//
//  Result.swift
//  gateguard
//
//  Created by Sławek Peszke on 05/12/2017.
//  Copyright © 2017 inFullMobile. All rights reserved.
//

import Foundation


enum Result<SuccessType> {
    case success(SuccessType)
    case error(Error)
}
