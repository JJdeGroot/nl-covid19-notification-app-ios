/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol AboutViewControllable: ViewControllable, AboutOverviewListener, HelpDetailListener {
    var router: AboutRouting? { get set }
    func push(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class AboutRouter: Router<AboutViewControllable>, AboutRouting {

    init(viewController: AboutViewControllable, aboutOverviewBuilder: AboutOverviewBuildable, helpDetailBuilder: HelpDetailBuildable) {
        self.helpDetailBuilder = helpDetailBuilder
        self.aboutOverviewBuilder = aboutOverviewBuilder
        super.init(viewController: viewController)
        viewController.router = self
    }

    func routeToOverview() {
        guard aboutOverviewViewController == nil else {
            return
        }

        let aboutOverviewViewController = aboutOverviewBuilder.build(withListener: viewController)
        self.aboutOverviewViewController = aboutOverviewViewController

        viewController.push(viewController: aboutOverviewViewController, animated: false)
    }

    func detachAboutOverview(shouldDismissViewController: Bool) {
        guard let aboutOverviewViewController = aboutOverviewViewController else { return }
        self.aboutOverviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: aboutOverviewViewController, animated: true)
        }
    }

    func routeToHelpQuestion(question: HelpQuestion) {
        let helpDetailViewController = helpDetailBuilder.build(withListener: viewController,
                                                               shouldShowEnableAppButton: false,
                                                               question: question)
        self.helpDetailViewController = helpDetailViewController

        viewController.push(viewController: helpDetailViewController, animated: true)
    }

    func dismissHelpQuestion(shouldDismissViewController: Bool) {
        guard let helpDetailViewController = helpDetailViewController else { return }
        self.helpDetailViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: helpDetailViewController, animated: true)
        }
    }

    // MARK: - Private

    private let helpDetailBuilder: HelpDetailBuildable
    private var helpDetailViewController: ViewControllable?

    private let aboutOverviewBuilder: AboutOverviewBuildable
    private var aboutOverviewViewController: ViewControllable?
}
