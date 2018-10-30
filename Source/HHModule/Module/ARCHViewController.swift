//
//  ARCHViewController.swift
//  architectureTeamA
//
//  Created by basalaev on 11.07.2018.
//  Copyright © 2018 Heads and Hands. All rights reserved.
//

import UIKit

@IBDesignable open class ARCHViewController<State: ARCHState, ViewOutput: ACRHViewOutput>: UIViewController, ARCHModule, ARCHRouter, ARCHViewRenderable {
    public typealias ViewState = State

    public var output: ViewOutput?

    private var moduleIsReady: Bool = false

    open var autorenderIgnoreViews: [ARCHViewInput] {
        return []
    }

    private let debugLog: ((String) -> Void)? = {
        if let debugMode = ProcessInfo.processInfo.environment["ARCHViewControllerDebugMode"], Int(debugMode) == 1 {
            return { print("[\(Thread.isMainThread ? "Main" : "Back")][ARCHViewController] " + $0) }
        } else {
            return nil
        }
    }()

    open func render(state: ViewState) {
        debugLog?("begin render state")

        var views = autorenderViews
        debugLog?("Autorender views:")
        views.forEach({ debugLog?("\(type(of: $0))") })

        let substates = self.substates(state: state)
        debugLog?("Autorender states:")
        substates.forEach({ debugLog?("\(type(of: $0))") })

        var index: Int = 0
        while index < views.count {
            let view = views[index]
            var isVisible = false

            for substate in substates where view.update(state: substate) {
                debugLog?("Display state \(type(of: state)) view \(type(of: view))")
                isVisible = true
                break
            }

            view.set(visible: isVisible)
            index += 1
        }

        debugLog?("end render state")
    }

    private func substates(state: ViewState) -> [Any] {
        return Mirror(reflecting: state).children.map { $0.value }
    }

    private var autorenderViews: [ARCHViewInput] {
        var mirrors: [Mirror] = []
        var mirror: Mirror = Mirror(reflecting: self)

        mirrors.append(mirror)

        while let superclassMirror = mirror.superclassMirror,
            String(describing: mirror.subjectType) != String(describing: UIViewController.self) {
                mirrors.append(superclassMirror)
                mirror = superclassMirror
        }

        let children = mirrors.reduce([], { (result: [Mirror.Child], mirror: Mirror) -> [Mirror.Child] in
            var result = result
            result.append(contentsOf: mirror.children)
            return result
        })

        return children
            .compactMap({ item -> ARCHViewInput? in
                guard let value = item.value as? ARCHViewInput else {
                    return nil
                }

                if autorenderIgnoreViews.contains(where: { $0 === value }) {
                    return nil
                } else {
                    return value
                }
            })
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open func prepareRootView() {
    }

    // MARK: - ARCHModule

    public var router: ARCHRouter {
        if !moduleIsReady {
            moduleIsReady = true
            prepareRootView()
            output?.viewIsReady()
        }
        return self
    }

    public var moduleInput: ARCHModuleInput? {
        return output as? ARCHModuleInput
    }
}
