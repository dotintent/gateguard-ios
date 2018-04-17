//
//  GradientView.swift
//  gateguard
//
//  Created by Sławek Peszke on 10/04/2018.
//  Copyright © 2018 inFullMobile. All rights reserved.
//

import UIKit

final class GradientView: UIView {
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setGradient()
    }
    
    // MARK: Setup
    
    private func setGradient() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        gradientLayer.colors = [UIColor.backgroundTop.cgColor, UIColor.backgroundBottom.cgColor]
    }
    
    override public class var layerClass: AnyClass {
        get {
            return CAGradientLayer.self
        }
    }
}
