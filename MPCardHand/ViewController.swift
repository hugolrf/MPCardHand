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

    case left
    case right
}

enum CardStackStatus {

    case stacked
    case expand_LEFT
    case expand_RIGHT
}

extension Double {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}

// Swift 2 Array Extension
extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
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
    var startPoint:CGPoint = CGPoint.zero
    let kNumCardsText = "Num of Cards"
    
    //status
    var curCardStatus:CardStackStatus = .stacked
    
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
                
                let cardName = "\(name) of \(type.capitalized) "
                
                let imageName = String(format: "\(type)_%02d", i)
                let image = UIImage(named: imageName)!
                
                let card = Card(id: id, name: cardName, image: image)
                self.cardDataArray.append(card)
                
                id += 1
            }
        }
        
        //Tap gesture on self.view
        let singleTapGestureOnView = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapOnView(_:)))
        singleTapGestureOnView.numberOfTapsRequired = 1
        singleTapGestureOnView.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(singleTapGestureOnView)
        
        //Swipe gesture on self.view (left)
        let swipeLeftGestureOnView = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.swipeGestureOnView(_:)))
        swipeLeftGestureOnView.numberOfTouchesRequired = 1
        swipeLeftGestureOnView.direction = .left
        self.view.addGestureRecognizer(swipeLeftGestureOnView)
        
        //Swipe gesture on self.view (right)
        let swipeRightGestureOnView = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.swipeGestureOnView(_:)))
        swipeRightGestureOnView.numberOfTouchesRequired = 1
        swipeRightGestureOnView.direction = .right
        self.view.addGestureRecognizer(swipeRightGestureOnView)
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - IBAction
    
    @IBAction func startBrowsing(_ sender: AnyObject) {
        
        self.present(self.browser, animated: true, completion: nil)
    }
    
    //MARK: - MCNearbyServiceBrowserDelegate
    
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        
        print("peerID: \(peerID)")
        
        return true
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        print("browser finished")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
     
        print("browser cancelled")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
            case .connecting:
                print("Connecting..")
                break
                
            case .connected:
                print("Connected..")
                self.statusLbl.text = "Connected"
                break
                
            case .notConnected:
                print("Not Connected..")
                self.statusLbl.text = "Not Connected"
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //animate all Cards flying out
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        
                        for cardImgView in self.cardDisplayArray {
                            cardImgView.center = CGPoint(x: cardImgView.center.x, y: -100.0)
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
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveData")
        
        let cardDict:NSDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSDictionary
        print("cardDict:\(cardDict)")
        let cardID = cardDict["id"] as! Int
        let isFront = cardDict["isFront"] as! Bool

        //card data
        let card = self.cardDataArray[cardID]

        DispatchQueue.main.async { () -> Void in
            
            //create card display
            let cardImgView = CardImageView(image: card.image)
            cardImgView.center = CGPoint(x: self.view.center.x, y: -50)
            //cardImgView.transform = CGAffineTransformScale(cardImgView.transform, 1.3, 1.3)//scale down
            cardImgView.isUserInteractionEnabled = true//enable this for gesture !
            cardImgView.card = card     //assign card data
            cardImgView.tag = card.id   //tag the card as the card ID
            cardImgView.image = isFront ? card.image : self.cardBackImage
            cardImgView.isFront = isFront
            
            //tap gesture (single tap)
            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleSingleTap(_:)))
            singleTapGesture.numberOfTapsRequired = 1
            singleTapGesture.numberOfTouchesRequired = 1
            cardImgView.addGestureRecognizer(singleTapGesture)
            
            //tap gesture (double tap)
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleDoubleTap(_:)))
            doubleTapGesture.numberOfTapsRequired = 2
            doubleTapGesture.numberOfTouchesRequired = 1
            cardImgView.addGestureRecognizer(doubleTapGesture)
            
            //pan gesture
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan(_:)))
            panGesture.minimumNumberOfTouches = 1
            panGesture.maximumNumberOfTouches = 1
            cardImgView.addGestureRecognizer(panGesture)//add to view
            
            self.cardDisplayArray.append(cardImgView)//add to display array
            self.view.addSubview(cardImgView)//add to view
            
            //display number of cards
            self.numCardsLbl.text = "\(self.kNumCardsText): \(self.cardDisplayArray.count)"
            
            //animate to position
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                
                cardImgView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 50)
            }) 
        }
    
        print("cardName: \(card.name), cardID:\(card.id), isFront:\(isFront)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("hand didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
        print("hand didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveStream")
    }
    
    //MARK: - Helpers
    
    func showCardName(_ cardID: Int) {
        
        let card = self.cardDataArray[cardID] //retrieve Card
        self.cardNameLbl.text = card.name
    }
    
    //MARK: - UIGestureRecognizers
    
    func handleSingleTap(_ recognizer:UITapGestureRecognizer) {
        
        //single tap
        
        if recognizer.view! is UIImageView {
            
            let imgView = recognizer.view! as! UIImageView
            self.showCardName(imgView.tag)//display card name
        }
    }
    
    func handleDoubleTap(_ recognizer:UITapGestureRecognizer) {
        
        //double tap
        
        if recognizer.view! is CardImageView {

            let cardImgView = recognizer.view! as! CardImageView
            
            //retrieve Card
            let card = self.cardDataArray[cardImgView.tag]
            
            //animate flip
            var animationOptions:UIViewAnimationOptions = .transitionFlipFromLeft
            
            if cardImgView.isFront {
                cardImgView.image = self.cardBackImage //shows card back
            } else {
                animationOptions = .transitionFlipFromRight
                cardImgView.image = card.image
            }
            
            UIView.transition(with: recognizer.view!, duration: 0.5, options: animationOptions, animations: { () -> Void in
                
            },
            completion: nil)
            
            cardImgView.isFront = !cardImgView.isFront //toggle front/back
        }
    }
    
    func handlePan(_ recognizer:UIPanGestureRecognizer) {
        
        /*
        var dictionaryExample : [String:AnyObject] = ["user":"UserName", "pass":"password", "token":"0123456789", "image":0] // image should be either NSData or empty
        let dataExample : NSData = NSKeyedArchiver.archivedDataWithRootObject(dictionaryExample)
        let dictionary:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(dataExample)! as NSDictionary
        */
        
        let cardImgView = recognizer.view as! CardImageView
        
        if recognizer.state == .cancelled {
            
            print("cancelled\n")
        }
        else if recognizer.state == .began {
            
            self.startPoint = cardImgView.center
            self.showCardName(cardImgView.tag)
        }
        else if recognizer.state == .changed {
            
            let translation = recognizer.translation(in: self.view)
            recognizer.view!.center = CGPoint(x: recognizer.view!.center.x + translation.x, y: recognizer.view!.center.y + translation.y)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
            
            if self.session.connectedPeers.count == 1 {
            
                let cardCenter = CGPoint(x: cardImgView.center.x, y: cardImgView.frame.origin.y + cardImgView.frame.size.height * 0.5)
                
                if self.transferView.frame.contains(cardCenter) {
                
                    self.transferView.alpha = 0.1
                }
                else {
                
                    self.transferView.alpha = 0.3
                }
            }
        }
        else if recognizer.state == .ended {
            
            self.transferView.alpha = 0.3
            
            let cardCenter = CGPoint(x: cardImgView.center.x, y: cardImgView.frame.origin.y + cardImgView.frame.size.height * 0.5)
            
            if self.transferView.frame.contains(cardCenter) {
        
                let cardDict = ["id":cardImgView.tag, "isFront":cardImgView.isFront] as [String : Any]
                let cardArchivedData = NSKeyedArchiver.archivedData(withRootObject: cardDict)
                
                if self.session.connectedPeers.count == 1 {
                
                    //Should be only 1 connected peer !
                    let peerID = self.session.connectedPeers[0]
                
                    do {
                        
                        try self.session.send(cardArchivedData, toPeers: [peerID], with: .reliable)
                    
                        //animate card flying out
                        UIView.animate(withDuration: 0.5, animations: { () -> Void in
                            
                            cardImgView.center = CGPoint(x: cardImgView.center.x, y: -100.0)
                            
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
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    
                    recognizer.view!.center = self.startPoint
                    
                }, completion: { (success) -> Void in
                        
                })
            }
        }
    }
    
    func handleTapOnView(_ recognizer:UITapGestureRecognizer) {
        
        self.cardNameLbl.text = "No Card Selected"
    }
    
    func swipeGestureOnView(_ recognizer:UISwipeGestureRecognizer) {
        
        if recognizer.state == .ended {
            
            if recognizer.direction == .left {
            
                print("swiped left")
                
                if self.curCardStatus == .stacked {
                
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        
                        self.swipeOpenCardsWithDirection(.left)
                    })
                }
                else if self.curCardStatus == .expand_RIGHT {
                
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        
                        self.swipeCloseCards()
                    })
                }
            }
            else if recognizer.direction == .right {
            
                print("swiped right")
                
                if self.curCardStatus == .stacked {
                    
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        
                        self.swipeOpenCardsWithDirection(.right)
                    })
                }
                else if self.curCardStatus == .expand_LEFT {
                    
                    UIView.animate(withDuration: 0.5, animations: { () -> Void in
                        
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
    
    func rotateCardWithView(_ v:UIView, rotationPoint:CGPoint, degrees:Double) {
    
        //reset anchor and position
        let minX   = v.frame.minX;
        let minY   = v.frame.minY;
        let width  = v.frame.width;
        let height = v.frame.height;
        let anchorPoint =  CGPoint(x: (rotationPoint.x-minX)/width,
            y: (rotationPoint.y-minY)/height);
        v.layer.anchorPoint = anchorPoint;
        v.layer.position = rotationPoint;
        //v.transform = CGAffineTransformIdentity
        
        //perform transformation animation
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
        
            v.transform = CGAffineTransform(rotationAngle: degrees.degreesToRadians)
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    //MARK: - Gesture Helpers
    
    func swipeOpenCardsWithDirection(_ direction:SwipeDirection) {
    
        let cardCount = self.cardDisplayArray.count
        let cardCountHalf = floor(Double(cardCount) * 0.5)
        let angleOffset = 10.0
        var rotationDegrees = -(cardCountHalf * angleOffset)
      
        print("cardCountHalf:\(cardCountHalf), startAngle:\(rotationDegrees)")
        
        //anchorPoint of rotation
        let rotationPoint = CGPoint(x: self.view.center.x, y: self.view.center.y + 100)
        
        if direction == .right {
        
            for v in self.cardDisplayArray {
                
                self.rotateCardWithView(v, rotationPoint: rotationPoint, degrees: rotationDegrees)
                rotationDegrees += angleOffset
            }
        }
        else if direction == .left {
            
            //start from last
            for i in ((0 + 1)...(cardCount-1)).reversed() {
                
                let v = self.cardDisplayArray[i]
                self.rotateCardWithView(v, rotationPoint: rotationPoint, degrees: rotationDegrees)
                rotationDegrees += angleOffset
            }
        }
    
        if direction == .right {
            self.curCardStatus = .expand_RIGHT
        }
        else if direction == .left {
            self.curCardStatus = .expand_LEFT
        }
    }
    
    func swipeCloseCards() {
    
        if self.cardDisplayArray.count > 1 {
        
            for cardImgView in self.cardDisplayArray {
            
                cardImgView.transform = CGAffineTransform(rotationAngle: 0.0.degreesToRadians)
            }
            
            self.curCardStatus = .stacked
        }
    }
    
    //
    func setAnchorPoint(_ anchorPoint: CGPoint, forView view: UIView) {
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
}

