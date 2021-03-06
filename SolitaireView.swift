//
//  SolitaireView.swift
//  Solitaire
//
//  Created by Daniil Sergeyevich Martyn on 4/30/16.
//  Copyright © 2016 Daniil Sergeyevich Martyn. All rights reserved.
//

import UIKit

var FAN_OFFSET : CGFloat = 0.2

class SolitaireView: UIView {

    var stockLayer : CALayer!
    var wasteLayer : CALayer!
    var foundationLayers : [CALayer]!   // four foundation layers
    var tableauLayers : [CALayer]!      // seven tableau layers
    
    var topZPosition : CGFloat = 0      // "highest" z-value of all card layers
    var cardToLayerDictionary : [Card : CardLayer]! // map card to it's layer
    
    var draggingCardLayer : CardLayer? = nil    // card layer dragged (nil => no drag)
    var draggingFan : [Card]? = nil             // fan of cards dragged
    var touchStartPoint: CGPoint = CGPointZero
    var touchStartLayerPosition : CGPoint = CGPointZero
    
    var isWin : Bool = false
    
    lazy var solitaire : Solitaire! = { // reference to model in app delegate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.solitaire
    }()
    
    
    override func awakeFromNib() {
        self.layer.name = "background"
        
        stockLayer = CALayer()
        stockLayer.name = "stock"
        stockLayer.backgroundColor =
            UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.1, alpha: 0.3).CGColor
        self.layer.addSublayer(stockLayer)
        
        
        wasteLayer = CALayer()
        wasteLayer.name = "waste"
        wasteLayer.backgroundColor =
            UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.1, alpha: 0.3).CGColor
        self.layer.addSublayer(wasteLayer)
        
        foundationLayers = []
        for _ in 0 ..< 4 {
            let foundationLayer = CALayer()
            foundationLayer.name = "foundation"
            foundationLayer.backgroundColor =
                UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.1, alpha: 0.3).CGColor
            self.layer.addSublayer(foundationLayer)
            foundationLayers.append(foundationLayer)
        }
        
        tableauLayers = []
        for _ in 0 ..< 7 {
            let tableauLayer = CALayer()
            tableauLayer.name = "tableau"
            tableauLayer.backgroundColor =
                UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.1, alpha: 0.3).CGColor
            self.layer.addSublayer(tableauLayer)
            tableauLayers.append(tableauLayer)
        }
        
        let deck = Card.deck()  // deck of poker cards
        cardToLayerDictionary = [:]
        for card in deck {
            let cardLayer = CardLayer(card: card)
            cardLayer.name = "card"
            self.layer.addSublayer(cardLayer)
            cardToLayerDictionary[card] = cardLayer
        }
    }
    
    override func layoutSublayersOfLayer(layer: CALayer) {
        draggingCardLayer = nil     // deactivate any dragging
        layoutTableAndCards()
    }
    
    func layoutTableAndCards() {
        
        if isWin {
            party()
            return
        }
        
        let width = bounds.size.width
        let height = bounds.size.height
        let portrait = width < height
        var m : CGFloat       // left/right between edges of screen and cards
        var t : CGFloat         // top/bottom border
        var d : CGFloat     // horizontal gap between cards
        var s : CGFloat     // gap between tableau and foundation/stock/waste
        
        var w : CGFloat
        var h : CGFloat
        
        let ratio : CGFloat = 215/150   // will be used to calculate height/width of card
        
        if portrait {
            FAN_OFFSET = 0.2
            m = 8.0
            t = 8.0
            d = 4.0
            s = 16.0
            w = (width - 2*m - 6*d)/7
            h = w*ratio
            
            
        } else {
            FAN_OFFSET = 0.15
            m = 64.0
            t = 8.0
            s = 12.0
            h = (height - 2*t - s)/4.7 //  2 full height + 2.7 worth of fanned cards
            w = h / ratio
            d = (width - 2*m - 7*w)/6
        }
        
        stockLayer.bounds = CGRectMake(0, 0, w, h)
        stockLayer.position = CGPointMake(m + w/2, t + h/2)
        
        wasteLayer.bounds = CGRectMake(0, 0, w, h)
        wasteLayer.position = CGPointMake(m + d + w + w/2, t + h/2)
        
        for i in 0 ..< 4 {
            foundationLayers[i].bounds = CGRectMake(0,0,w,h)
            foundationLayers[i].position = CGPointMake(
                3*w + m + 3*d + w * CGFloat(i) + d * CGFloat(i) + w/2,
                t + h/2)
        }
        
        for i in 0 ..< 7 {
            tableauLayers[i].bounds = CGRectMake(0,0,w,h)
            tableauLayers[i].position = CGPointMake(
                CGFloat(i)*w + m + d*CGFloat(i) + w/2,
                t + s + h + h/2)
        }
        
        layoutCards()
    }
    
    func layoutCards() {
        var z : CGFloat = 1.0
        
        let stock = solitaire.stock
        for card in stock {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = stockLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z++
        }
        
        //  layout the cards in waste and foundation stacks...
        
        let waste = solitaire.waste
        for card in waste {
            let cardLayer = cardToLayerDictionary[card]!
            cardLayer.frame = wasteLayer.frame
            cardLayer.faceUp = solitaire.isCardFaceUp(card)
            cardLayer.zPosition = z++
        }
        
        let foundation = solitaire.foundation
        for i in 0 ..< 4 {
            for card in foundation[i] {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame = foundationLayers[i].frame
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z++
            }
        }
        
        let cardSize = stockLayer.bounds.size
        let fanOffset = FAN_OFFSET * cardSize.height
        for i in 0 ..< 7 {
            let tableau = solitaire.tableau[i]
            let tableauOrigin = tableauLayers[i].frame.origin
            var j : CGFloat = 0
            for card in tableau {
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.frame =
                    CGRectMake(tableauOrigin.x, tableauOrigin.y + j*fanOffset,
                        cardSize.width, cardSize.height)
                cardLayer.faceUp = solitaire.isCardFaceUp(card)
                cardLayer.zPosition = z++
                j++
            }
        }
        
        topZPosition = z    // remember "highest position"
    }
    
    func flipCard(card : Card, faceUp : Bool) {
        // implement this!!!! TODO
        
        // wait... i get it... maybe
    }
    
    func dealCardsFromStockToWaste() {
        if solitaire.canDealCard() {
            let card = solitaire.stock.last
            solitaire.didDealCard()
            
            let cardLayer = cardToLayerDictionary[card!]
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cardLayer!.zPosition = topZPosition + 1
            CATransaction.commit()
            cardLayer!.position = wasteLayer.position
            
            layoutSublayersOfLayer(self.layer)      // XXXXXX Again... change this later perhaps
        }
    }
    
    func collectWasteCardsIntoStock() {
        solitaire.collectWasteCardsIntoStock()
        layoutSublayersOfLayer(self.layer)
    }
    
    func dragCardsToPosition(position : CGPoint, animate : Bool) {
        if !animate {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        draggingCardLayer!.position = position
        if let draggingFan = draggingFan {
            let off = FAN_OFFSET*draggingCardLayer!.bounds.size.height
            let n = draggingFan.count
            for i in 1 ..< n {
                let card = draggingFan[i]
                let cardLayer = cardToLayerDictionary[card]!
                cardLayer.position = CGPointMake(position.x, position.y + CGFloat(i)*off)
            }
        }
        if !animate {
            CATransaction.commit()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let touchPoint = touch.locationInView(self)
        let hitTestPoint = self.layer.convertPoint(touchPoint, toLayer: self.layer.superlayer)
        let layer = self.layer.hitTest(hitTestPoint)
        
        if let layer = layer {
            if layer.name == "card" {
                let cardLayer = layer as! CardLayer
                let card = cardLayer.card
                
                if solitaire.isCardFaceUp(card) {
                    if touch.tapCount > 1 {
                        for i in 0 ..< 4 {
                            if solitaire.canDropCard(card, onFoundation: i){
                                solitaire.didDropCard(card, onFoundation: i)
                                draggingCardLayer = cardLayer
                                dragCardsToPosition(foundationLayers[i].position, animate: true)
                                draggingCardLayer = nil

                                if solitaire.gameWon() {
                                    party()
                                }
                                layoutSublayersOfLayer(self.layer)
                                // maybe use flipCard() to animate card flipping...
                                break
                            }
                        }
                    } else {
                    /// else initiate drag of card or stack of cards by setting draggingCardLayer,
                    /// and (possibly) draggingFan...
                        
                        if solitaire.waste.last == card {
                            cardLayer.zPosition = topZPosition + 1
                            touchStartPoint = touchPoint
                            touchStartLayerPosition = layer.position
                            draggingCardLayer = cardLayer
                        }
                        
                        for i in 0 ..< 7 {
                            if solitaire.tableau[i].last == card {
                                cardLayer.zPosition = topZPosition + 1
                                touchStartPoint = touchPoint
                                touchStartLayerPosition = layer.position
                                draggingCardLayer = cardLayer
                            } else {
                                if solitaire.tableau[i].contains(card) {
                                    if let dragFan = solitaire.fanBeginningWithCard(card) {
                                        
                                        for ii in 0 ..< dragFan.count {
                                            let fanCardLayer = cardToLayerDictionary[dragFan[ii]]
                                            fanCardLayer?.zPosition = topZPosition++
                                        }
                                        self.draggingFan = dragFan
                                        touchStartPoint = touchPoint
                                        touchStartLayerPosition = layer.position
                                        draggingCardLayer = cardLayer
                                    }
                                }
                            }
                        }
                        
                        for i in 0 ..< 4 {
                            if solitaire.foundation[i].last == card {
                                cardLayer.zPosition = topZPosition + 1
                                touchStartPoint = touchPoint
                                touchStartLayerPosition = layer.position
                                draggingCardLayer = cardLayer
                            }
                        }
                    
                    }
                } else if solitaire.canFlipCard(card) {
                    flipCard(card, faceUp: true)  // update model and view
                } else if solitaire.stock.last == card {
                    dealCardsFromStockToWaste()
                }
            } else if (layer.name == "stock") {
                collectWasteCardsIntoStock()
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let _ = draggingCardLayer {
            let touch = touches.first
            let touchPoint = touch?.locationInView(self)
            let delta = CGPointMake(touchPoint!.x - touchStartPoint.x, touchPoint!.y - touchStartPoint.y)
            let pos = CGPointMake(touchStartLayerPosition.x + delta.x, touchStartLayerPosition.y + delta.y)
            dragCardsToPosition(pos, animate: false)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let _ = draggingCardLayer {
             if draggingFan == nil {
                
                for i in 0 ..< 4 {
                    if CGRectIntersectsRect(draggingCardLayer!.frame, foundationLayers[i].frame) {
                        if solitaire.canDropCard(draggingCardLayer!.card, onFoundation: i){
                            solitaire.didDropCard(draggingCardLayer!.card, onFoundation: i)
                            
                            if solitaire.gameWon() {
                                party()
                            }
                            // maybe use flipCard() to animate card flipping...
                            break
                        }
                    }
                }
                
                for i in 0 ..< 7 {
                    
                    if solitaire.tableau[i].isEmpty {
                        if CGRectIntersectsRect(draggingCardLayer!.frame, tableauLayers[i].frame) {
                            if solitaire.canDropCard(draggingCardLayer!.card, onTableau: i) {
                                solitaire.didDropCard(draggingCardLayer!.card, onTableau: i)
                            }
                        }
                    }else {
                        if let whereToDrop = cardToLayerDictionary[solitaire.tableau[i].last!]{
                            if CGRectIntersectsRect(draggingCardLayer!.frame, whereToDrop.frame) {
                                if solitaire.canDropCard(draggingCardLayer!.card, onTableau: i) {
                                    solitaire.didDropCard(draggingCardLayer!.card, onTableau: i)
                                }
                            }
                        }
                    }
                }
                
                layoutSublayersOfLayer(self.layer)
             } else { // fan of cards (can only drop on tableau stack)
                
                for i in 0 ..< 7 {
                    
                    if solitaire.tableau[i].isEmpty {
                        if let firstCardFanLayer = cardToLayerDictionary[draggingFan!.first!]{
                            if CGRectIntersectsRect(firstCardFanLayer.frame, tableauLayers[i].frame) {
                                if solitaire.canDropFan(draggingFan!, onTableau: i) {
                                    solitaire.didDropFan(draggingFan!, onTableau: i)
                                }
                            }
                        }
                    }else {
                        if let whereToDrop = cardToLayerDictionary[solitaire.tableau[i].last!]{
                            if let firstCardFanLayer = cardToLayerDictionary[draggingFan!.first!]{
                                if CGRectIntersectsRect(firstCardFanLayer.frame, whereToDrop.frame) {
                                    if solitaire.canDropFan(draggingFan!, onTableau: i) {
                                        solitaire.didDropFan(draggingFan!, onTableau: i)
                                    }
                                }
                            }
                        }
                    }
                }
                
                layoutSublayersOfLayer(self.layer)
            }
            draggingCardLayer = nil
            draggingFan = nil
        }
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
       // <#code#>
    }


    func fanCards() {
        let radius = 0.35*max(bounds.width/2, bounds.height/2)
        let theta0 : CGFloat = CGFloat(M_PI)
        let theta1 : CGFloat = 0.0
        let dtheta = (theta1 - theta0)/51
        
        let deck = Card.deck()
        
        for i in 0 ..< 50 {
            let clayer = cardToLayerDictionary[deck[i]]
            let theta = theta0 + CGFloat(i)*dtheta
            let x : CGFloat = center.x - radius*cos(theta)
            let y : CGFloat = center.y + radius*sin(theta)
            clayer!.position = CGPointMake(x, y)
            clayer!.zPosition = topZPosition++
            clayer!.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(M_PI_2) - theta, 0, 0, 1)
        }
    }
    
    func resetLayers() {
        let deck = Card.deck()
        
        for i in 0 ..< 52 {
            let clayer = cardToLayerDictionary[deck[i]]
            clayer!.zPosition = topZPosition++
            clayer!.transform = CATransform3DIdentity
        }
    }
    
    func playAgain() {
        //  accessing alertController from UIView method by Zev Eisenberg
        // http://stackoverflow.com/questions/26554894/how-to-present-uialertcontroller-when-not-in-a-view-controller
        
        let alert = UIAlertController(title: "YOU WON!", message: "Congrats!", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Play Again?", style: UIAlertActionStyle.Default, handler:
            {(UIAlertAction) -> Void in
                self.solitaire.freshGame()
                self.isWin = false
                self.resetLayers()
                self.layoutSublayersOfLayer(self.layer)}))
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    func party() {
        
        isWin = true
        
        let width = bounds.size.width
        let height = bounds.size.height
        
        let deck = Card.deck()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let clayer = cardToLayerDictionary[deck[50]]
        let x : CGFloat = width/5 * 2
        let y : CGFloat = height/3
        clayer!.position = CGPointMake(x, y)
        clayer!.zPosition = topZPosition++

        let clayer2 = cardToLayerDictionary[deck[51]]
        let x2 : CGFloat = width/5 * 3
        let y2 : CGFloat = height/3
        clayer2!.position = CGPointMake(x2, y2)
        clayer2!.zPosition = topZPosition++
        CATransaction.commit()
        
        
        fanCards()
        
        playAgain()
        
    }

}