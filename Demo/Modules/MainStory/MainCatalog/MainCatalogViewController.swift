//
//  MainCatalogViewController.swift
//  architecture
//
//  Created by Eugene Sorokin on 25/10/2018.
//  Copyright © 2018 HandH. All rights reserved.
//

import HHModule

final class MainCatalogViewController: ARCHViewController<MainCatalogState, MainCatalogEventHandler> {

    // MARK: - View life cycle

    override func prepareRootView() {
        super.prepareRootView()

        view.backgroundColor = .white

        let label = UILabel(frame: view.bounds)
        label.text = "MainStory catalog page"
        label.textAlignment = .center

        view.addSubview(label)
        label.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    // MARK: - Render

    override func render(state: ViewState) {
        super.render(state: state)
    }
}
