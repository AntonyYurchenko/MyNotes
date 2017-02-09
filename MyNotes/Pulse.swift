import UIKit

class Pulse : CAShapeLayer {
    
    func startPulse(radius: CGFloat, duration: Double) {
        self.opacity = 0
        self.path = UIBezierPath(arcCenter: CGPoint(x: 0, y: 0),
                                 radius: radius,
                                 startAngle: CGFloat(0.0*(M_PI/180.0)),
                                 endAngle: CGFloat(360.0*(M_PI/180.0)),
                                 clockwise: true).cgPath
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.fromValue = 0.0
        scaleAnimation.toValue = 1.0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0
        self.fillColor = UIColor(red: 0.193, green: 0.577, blue: 0.775, alpha: 1).cgColor
        
        let animationGroup = CAAnimationGroup()
        let animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = duration
        animationGroup.repeatCount = Float.infinity
        animationGroup.animations = animations
        self.add(animationGroup, forKey: "pulse")
    }
    
    func stopPulse() {
        self.removeAnimation(forKey: "pulse")
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.fromValue = self.presentation()?.transform
        scaleAnimation.toValue = 1.0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = self.presentation()?.opacity
        opacityAnimation.toValue = 0
        
        let animationGroup = CAAnimationGroup()
        let animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = 0.3
        animationGroup.animations = animations
        self.add(animationGroup, forKey: "pulse")
    }
}
