//
//  ViewController.swift
//  MPCardHand
//
//  Created by Jacky Tjoa on 17/11/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import MultipeerConnectivity

enum SwipeDirection {

    case Left
    case Right
}

enum CardStackStatus {

    case STACKED
    case EXPAND_LEFT
    case EXPAND_RIGHT
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

// Swift 2 Array Extension
extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    @IBOutlet weak var transferView: UIView!
    @IBOutlet weak var numCardsLbl: UILabel!
    @IBOutlet weak var cardNameLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!

    //UI
    var cardBackImage:UIImage! = nil
    var cardDataArray:[Card] = [] // card database
    var cardDisplayArray:[CardImageView] = []
    var startPoint:CGPoint = CGPointZero
    let kNumCardsText = "Num of Cards"
    
    //status
    var curCardStatus:CardStackStatus = .STACKED
    
    //Multipeer Connectivity
    let kServiceType = "multi-peer-chat"
    var myPeerID:MCPeerID!
    var session:MCSession!
    var browser:MCBrowserViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Card back image
        self.cardBackImage = UIImage(named: "card_back")
        
        //Load cards
        let cardTypes = ["spade", "club", "diamond", "heart"]
        
        var id:Int = 0
        for type in cardTypes {
            
            for i in 2...14 {
                
                var name = "\(i)"
                
                if i == 11 {
                    name = "Jack"
                }
                else if i == 12 {
                    name = "Queen"
                }
                else if i == 13 {
                    name = "King"
                }
                else if i == 14 {
                    name = "Ace"
                }
                
                let cardName = "\(name) of \(type.capitalizedString) "
                
                let imageName = String(format: "\(type)_%02d", i)
                let image = UIImage(named: imageName)!
                
                let card = Card(id: id, name: cardName, image: image)
                self.cardDataArray.append(card)
                
                id++
            }
        }
        
        //Tap gesture on self.view
        let singleTapGestureOnView = UITapGestureRecognizer(target: self, action: "handleTapOnView:")
        singleTapGestureOnView.numberOfTapsRequired = 1
        singleTapGestureOnView.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(singleTapGestureOnView)
        
        //Swipe gesture on self.view (left)
        let swipeLeftGestureOnView = UISwipeGestureRecognizer(target: self, action: "swipeGestureOnView:")
        swipeLeftGestureOnView.numberOfTouchesRequired = 1
        swipeLeftGestureOnView.direction = .Left
        self.view.addGestureRecognizer(swipeLeftGestureOnView)
        
        //Swipe gesture on self.view (right)
        let swipeRightGestureOnView = UISwipeGestureRecognizer(target: self, action: "swipeGestureOnView:")
        swipeRightGestureOnView.numberOfTouchesRequired = 1
        swipeRightGestureOnView.direction = .Right
        self.view.addGestureRecognizer(swipeRightGestureOnView)
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .Required)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - IBAction
    
    @IBAction func startBrowsing(sender: AnyObject) {
        
        self.presentViewController(self.browser, animated: true, completion: nil)
    }
    
    //MARK: - MCNearbyServiceBrowserDelegate
    
    func browserViewController(browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        
        print("peerID: \(peerID)")
        
        return true
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        
        print("browser finished")
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
     
        print("browser cancelled")
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
            case .Connecting:
                print("Connecting..")
                break
                
            case .Connected:
                print("Connected..")
                self.statusLbl.text = "Connected"
                break
                
            case .NotConnected:
                print("Not Connected..")
                self.statusLbl.text = "Not Connected"
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //animate all Cards flying out
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        
                        for cardImgView in self.cardDisplayArray {
                            cardImgView.center = CGPointMake(cardImgView.center.x, -100.0)
                        }
                        
                        }, completion: { (success) -> Void in
                            
                            self.cardNameLbl.text = "No Card Selected"
                            
                            for cardImgView in self.cardDisplayArray {
                                self.cardDisplayArray.removeObject(cardImgView)//remove object in the display array
                            }
                            
                            //display number of cards
                            self.numCardsLbl.text = "\(self.kNumCardsText): \(self.cardDisplayArray.count)"
                    })
                })

                break
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveData")
        
        let cardDict:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSDictionary
        print("cardDict:\(cardDict)")
        let cardID = cardDict["id"] as! Int
        let isFront = cardDict["isFront"] as! Bool

        //card data
        let card = self.cardDataArray[cardID]

        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            //create card display
            let cardImgView = CardImageView(image: card.image)
            cardImgView.center = CGPointMake(self.view.center.x, -50)
            //cardImgView.transform = CGAffineTransformScale(cardImgView.transform, 1.3, 1.3)//scale down
            cardImgView.userInteractionEnabled = true//enable this for gesture !
            cardImgView.card = card     //assign card data
            cardImgView.tag = card.id   //tag the card as the card ID
            cardImgView.image = isFront ? card.image : self.cardBackImage
            cardImgView.isFront = isFront
            
            //tap gesture (single tap)
            let singleTapGesture = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
            singleTapGesture.numberOfTapsRequired = 1
            singleTapGesture.numberOfTouchesRequired = 1
            cardImgView.addGestureRecognizer(singleTapGesture)
            
            //tap gesture (double tap)
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
            doubleTapGesture.numberOfTapsRequired = 2
            doubleTapGesture.numberOfTouchesRequired = 1
            cardImgView.addGestureRecognizer(doubleTapGesture)
            
            //pan gesture
            let panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
            panGesture.minimumNumberOfTouches = 1
            panGesture.maximumNumberOfTouches = 1
            cardImgView.addGestureRecognizer(panGesture)//add to view
            
            self.cardDisplayArray.append(cardImgView)//add to display array
            self.view.addSubview(cardImgView)//add to view
            
            //display number of cards
            self.numCardsLbl.text = "\(self.kNumCardsText): \(self.cardDisplayArray.count)"
            
            //animate to position
            UIView.animateWithDuration(0.5) { () -> Void in
                
                cardImgView.center = CGPointMake(self.view.center.x, self.view.center.y - 50)
            }
        }
    
        print("cardName: \(card.name), cardID:\(card.id), isFront:\(isFront)")
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("hand didStartReceivingResourceWithName")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        print("hand didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveStream")
    }
    
    //MARK: - Helpers
    
    func showCardName(cardID: Int) {
        
        let card = self.cardDataArray[cardID] //retrieve Card
        self.cardNameLbl.text = card.name
    }
    
    //MARK: - UIGestureRecognizers
    
    func handleSingleTap(recognizer:UITapGestureRecognizer) {
        
        //single tap
        
        if recognizer.view! is UIImageView {
            
            let imgView = recognizer.view! as! UIImageView
            self.showCardName(imgView.tag)//display card name
        }
    }
    
    func handleDoubleTap(recognizer:UITapGestureRecognizer) {
        
        //double tap
        
        if recognizer.view! is CardImageView {

            let cardImgView = recognizer.view! as! CardImageView
            
            //retrieve Card
            let card = self.cardDataArray[cardImgView.tag]
            
            //animate flip
            var animationOptions:UIViewAnimationOptions = .TransitionFlipFromLeft
            
            if cardImgView.isFront {
                cardImgView.image = self.cardBackImage //shows card back
            } else {
                animationOptions = .TransitionFlipFromRight
                cardImgView.image = card.image
            }
            
            UIView.transitionWithView(recognizer.view!, duration: 0.5, options: animationOptions, animations: { () -> Void in
                
            },
            completion: nil)
            
            cardImgView.isFront = !cardImgView.isFront //toggle front/back
        }
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        /*
        var dictionaryExample : [String:AnyObject] = ["user":"UserName", "pass":"password", "token":"0123456789", "image":0] // image should be either NSData or empty
        let dataExample : NSData = NSKeyedArchiver.archivedDataWithRootObject(dictionaryExample)
        let dictionary:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(dataExample)! as NSDictionary
        */
        
        let cardImgView = recognizer.view as! CardImageView
        
        if recognizer.state == .Cancelled {
            
            print("cancelled\n")
        }
        else if recognizer.state == .Began {
            
            self.startPoint = cardImgView.center
            self.showCardName(cardImgView.tag)
        }
        else if recognizer.state == .Changed {
            
            let translation = recognizer.translationInView(self.view)
            recognizer.view!.center = CGPoint(x: recognizer.view!.center.x + translation.x, y: recognizer.view!.center.y + translation.y)
            recognizer.setTranslation(CGPointZero, inView: self.view)
            
            if self.session.connectedPeers.count == 1 {
            
                let cardCenter = CGPointMake(cardImgView.center.x, cardImgView.frame.origin.y + cardImgView.frame.size.height * 0.5)
                
                if CGRectContainsPoint(self.transferView.frame, cardCenter) {
                
                    self.transferView.alpha = 0.1
                }
                else {
                
                    self.transferView.alpha = 0.3
                }
            }
        }
        else if recognizer.state == .Ended {
            
            self.transferView.alpha = 0.3
            
            let cardCenter = CGPointMake(cardImgView.center.x, cardImgView.frame.origin.y + cardImgView.frame.size.height * 0.5)
            
            if CGRectContainsPoint(self.transferView.frame, cardCenter) {
        
                let cardDict = ["id":cardImgView.tag, "isFront":cardImgView.isFront]
                let cardArchivedData = NSKeyedArchiver.archivedDataWithRootObject(cardDict)
                
                if self.session.connectedPeers.count == 1 {
                
                    //Should be only 1 connected peer !
                    let peerID = self.session.connectedPeers[0]
                
                    do {
                        
                        try self.session.sendData(cardArchivedData, toPeers: [peerID], withMode: .Reliable)
                    
                        //animate card flying out
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            
                            cardImgView.center = CGPointMake(cardImgView.center.x, -100.0)
                            
                        }, completion: { (success) -> Void in
                                
                            self.cardNameLbl.text = "No Card Selected"
                            self.cardDisplayArray.removeObject(cardImgView)//remove object in the display array
                            
                            //display number of cards
                            self.numCardsLbl.text = "\(self.kNumCardsText): \(self.cardDisplayArray.count)"
                        })
                        
                    } catch {
                    
                        print("error sending data: \(error)")
                    }
                }
                
            } else {
            
                //if not sending data, return card
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    
                    recognizer.view!.center = self.startPoint
                    
                }, completion: { (success) -> Void in
                        
                })
            }
        }
    }
    
    func handleTapOnView(recognizer:UITapGestureRecognizer) {
        
        self.cardNameLbl.text = "No Card Selected"
    }
    
    func swipeGestureOnView(recognizer:UISwipeGestureRecognizer) {
        
        if recognizer.state == .Ended {
            
            if recognizer.direction == .Left {
            
                print("swiped left")
                
                if self.curCardStatus == .STACKED {
                
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        
                        self.swipeOpenCardsWithDirection(.Left)
                    })
                }
                else if self.curCardStatus == .EXPAND_RIGHT {
                
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        
                        self.swipeCloseCards()
                    })
                }
            }
            else if recognizer.direction == .Right {
            
                print("swiped right")
                
                if self.curCardStatus == .STACKED {
                    
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        
                        self.swipeOpenCardsWithDirection(.Right)
                    })
                }
                else if self.curCardStatus == .EXPAND_LEFT {
                    
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        
                        self.swipeCloseCards()
                    })
                }
            }
            else {
            
                print("other direction detected")
            }
        }
    }
    
    //MARK: - Animation Helpers
    
    func rotateCardWithView(v:UIView, rotationPoint:CGPoint, degrees:Double) {
    
        //reset anchor and position
        let minX   = CGRectGetMinX(v.frame);
        let minY   = CGRectGetMinY(v.frame);
        let width  = CGRectGetWidth(v.frame);
        let height = CGRectGetHeight(v.frame);
        let anchorPoint =  CGPointMake((rotationPoint.x-minX)/width,
            (rotationPoint.y-minY)/height);
        v.layer.anchorPoint = anchorPoint;
        v.layer.position = rotationPoint;
        //v.transform = CGAffineTransformIdentity
        
        //perform transformation animation
        UIView.animateWithDuration(0.5, animations: { () -> Void in
        
            v.transform = CGAffineTransformMakeRotation(degrees.degreesToRadians)
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    //MARK: - Gesture Helpers
    
    func swipeOpenCardsWithDirection(direction:SwipeDirection) {
    
        let cardCount = self.cardDisplayArray.count
        let cardCountHalf = floor(Double(cardCount) * 0.5)
        let angleOffset = 10.0
        var rotationDegrees = -(cardCountHalf * angleOffset)
      
        print("cardCountHalf:\(cardCountHalf), startAngle:\(rotationDegrees)")
        
        //anchorPoint of rotation
        let rotationPoint = CGPointMake(self.view.center.x, self.view.center.y + 100)
        
        if direction == .Right {
        
            for v in self.cardDisplayArray {
                
                self.rotateCardWithView(v, rotationPoint: rotationPoint, degrees: rotationDegrees)
                rotationDegrees += angleOffset
            }
        }
        else if direction == .Left {
            
            //start from last
            for (var i = (cardCount-1); i > 0; i--) {
                
                let v = self.cardDisplayArray[i]
                self.rotateCardWithView(v, rotationPoint: rotationPoint, degrees: rotationDegrees)
                rotationDegrees += angleOffset
            }
        }
    
        if direction == .Right {
            self.curCardStatus = .EXPAND_RIGHT
        }
        else if direction == .Left {
            self.curCardStatus = .EXPAND_LEFT
        }
    }
    
    func swipeCloseCards() {
    
        if self.cardDisplayArray.count > 1 {
        
            for cardImgView in self.cardDisplayArray {
            
                cardImgView.transform = CGAffineTransformMakeRotation(0.0.degreesToRadians)
            }
            
            self.curCardStatus = .STACKED
        }
    }
    
    //
    func setAnchorPoint(anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = CGPointApplyAffineTransform(newPoint, view.transform)
        oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
}

