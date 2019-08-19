//
//  ViewController.swift
//  VectorEraser
//
//  Created by Don Mag on 8/19/19.
//

import UIKit

enum LineType: Int {
	case DRAW
	case ERASE
}

class LineDef: NSObject {
	var lineType: LineType = .DRAW
	var color: UIColor = UIColor.black
	var opacity: Float = 1.0
	var lineWidth: CGFloat = 8.0
	var points: [CGPoint] = [CGPoint]()
}

class DrawingView: UIView {
	
	// the background image
	var bkgImage: UIImage = UIImage() {
		didSet {
			updateBkgImage()
		}
	}
	
	func updateBkgImage() -> Void {
		// if no layers have been added yet, add the background image layer
		if layer.sublayers == nil {
			let l = CALayer()
			layer.addSublayer(l)
		}
		guard let layers = layer.sublayers else { return }
		for l in layers {
			if let _ = l as? CAShapeLayer {
				// in case we're changing the backgound image after lines have been drawn
				// ignore shape layers
			} else {
				// this layer is NOT a CAShapeLayer, so it's either the first (background image) layer
				// or it's an eraser layer, so update the contents
				l.contents = bkgImage.cgImage
			}
		}
		setNeedsDisplay()
	}
	
	func undo() -> Void {
		// only remove a layer if it's not the first (background image) layer
		guard let n = layer.sublayers?.count, n > 1 else { return }
		_ = layer.sublayers?.popLast()
	}
	
	func addLineDef(_ def: LineDef) -> Void {
		
		if def.lineType == LineType.DRAW {
			
			// create new shape layer
			let newLayer = CAShapeLayer()
			
			// set "draw" properties
			newLayer.lineCap = .round
			newLayer.lineWidth = def.lineWidth
			newLayer.opacity = def.opacity
			newLayer.strokeColor = def.color.cgColor
			newLayer.fillColor = UIColor.clear.cgColor
			
			// create bezier path from LineDef points
			let drawPts = def.points
			let bez = UIBezierPath()
			for pt in drawPts {
				if pt == drawPts.first {
					bez.move(to: pt)
				} else {
					bez.addLine(to: pt)
				}
			}
			// set path
			newLayer.path = bez.cgPath
			
			// add layer
			layer.addSublayer(newLayer)
			
		} else {
			
			// create new layer
			let newLayer = CALayer()
			// set its contents to the background image
			newLayer.contents = bkgImage.cgImage
			newLayer.opacity = def.opacity
			
			// create a shape layer to use as a mask
			let maskLayer = CAShapeLayer()
			
			// set "draw" properties
			// strokeColor will always be black, because it just uses alpha for the mask
			maskLayer.lineCap = .round
			maskLayer.lineWidth = def.lineWidth
			maskLayer.strokeColor = UIColor.black.cgColor
			maskLayer.fillColor = UIColor.clear.cgColor
			
			// add mask
			newLayer.mask = maskLayer
			
			// create bezier path from LineDef points
			let drawPts = def.points
			let bez = UIBezierPath()
			for pt in drawPts {
				if pt == drawPts.first {
					bez.move(to: pt)
				} else {
					bez.addLine(to: pt)
				}
			}
			// set maskLayer's path
			maskLayer.path = bez.cgPath
			
			// add layer
			layer.addSublayer(newLayer)
			
		}
		
		setNeedsDisplay()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		// update layer frames
		if let layers = layer.sublayers {
			for l in layers {
				l.frame = bounds
			}
		}
	}
	
}


class DrawViewController: UIViewController {
	
	let theDrawingView: DrawingView = {
		let v = DrawingView()
		v.translatesAutoresizingMaskIntoConstraints = false
		return v
	}()
	
	let demoButton: UIButton = {
		let v = UIButton()
		v.translatesAutoresizingMaskIntoConstraints = false
		v.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
		v.setTitleColor(.blue, for: .normal)
		v.setTitleColor(.lightGray, for: .highlighted)
		v.setTitle("Draw Red", for: .normal)
		return v
	}()
	
	let redLine: LineDef = {
		let d = LineDef()
		d.lineType = .DRAW
		d.color = .red
		d.lineWidth = 8.0
		d.points = [
			CGPoint(x: 20, y: 20),
			CGPoint(x: 40, y: 140),
			CGPoint(x: 280, y: 200),
		]
		return d
	}()
	
	let greenLine: LineDef = {
		let d = LineDef()
		d.lineType = .DRAW
		d.color = .green
		d.lineWidth = 16.0
		d.points = [
			CGPoint(x: 20, y: 100),
			CGPoint(x: 80, y: 80),
			CGPoint(x: 240, y: 140),
			CGPoint(x: 100, y: 200),
		]
		return d
	}()
	
	let blueLine: LineDef = {
		let d = LineDef()
		d.lineType = .DRAW
		d.color = .blue
		d.opacity = 0.5
		d.lineWidth = 24.0
		d.points = [
			CGPoint(x: 250, y: 20),
			CGPoint(x: 150, y: 240),
			CGPoint(x: 100, y: 60),
		]
		return d
	}()
	
	let yellowLine: LineDef = {
		let d = LineDef()
		d.lineType = .DRAW
		d.color = .yellow
		d.lineWidth = 32.0
		d.points = [
			CGPoint(x: 30, y: 200),
			CGPoint(x: 250, y: 80),
			CGPoint(x: 250, y: 180),
		]
		return d
	}()
	
	let eraserLine: LineDef = {
		let d = LineDef()
		d.lineType = .ERASE
		d.lineWidth = 32.0
		d.points = [
			CGPoint(x: 30, y: 200),
			CGPoint(x: 250, y: 80),
			CGPoint(x: 250, y: 180),
		]
		return d
	}()
	
	var testErase = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// add the drawing view
		view.addSubview(theDrawingView)
		
		// constrain it 300 x 300 centered X and Y
		NSLayoutConstraint.activate([
			theDrawingView.widthAnchor.constraint(equalToConstant: 300),
			theDrawingView.heightAnchor.constraint(equalToConstant: 300),
			theDrawingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			theDrawingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			])
		
		let imgName = "TheCat"
		if let img = UIImage(named: imgName) {
			theDrawingView.bkgImage = img
		}
		
		// add a demo button
		view.addSubview(demoButton)
		
		// constrain it 20-pts from the top, centered X
		NSLayoutConstraint.activate([
			demoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0),
			demoButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
			demoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			])
		
		// add the touchUpInside target
		demoButton.addTarget(self, action: #selector(doTest), for: .touchUpInside)
	}
	
	@objc func doTest(_ sender: Any?) -> Void {
		
		if let b = sender as? UIButton {
			
			let t = b.currentTitle
			
			switch t {
			case "Draw Red":
				theDrawingView.addLineDef(redLine)
				b.setTitle("Draw Green", for: .normal)
			case "Draw Green":
				theDrawingView.addLineDef(greenLine)
				b.setTitle("Draw Blue", for: .normal)
			case "Draw Blue":
				theDrawingView.addLineDef(blueLine)
				b.setTitle("Draw Yellow", for: .normal)
			case "Draw Yellow":
				theDrawingView.addLineDef(yellowLine)
				b.setTitle("Toggle Yellow / Erase", for: .normal)
			default:
				toggle()
			}
			
		}
	}
	
	func toggle() -> Void {
		
		// undo the last action
		theDrawingView.undo()
		
		// toggle bool var
		testErase = !testErase
		
		// add either yellowLine or eraserLine
		theDrawingView.addLineDef(testErase ? eraserLine : yellowLine)
		
	}
	
}
