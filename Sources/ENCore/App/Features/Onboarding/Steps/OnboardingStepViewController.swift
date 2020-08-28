/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import UIKit

protocol OnboardingStepViewControllable: ViewControllable {}

final class OnboardingStepViewController: ViewController, OnboardingStepViewControllable {

    // MARK: - Lifecycle

    init(onboardingManager: OnboardingManaging,
         onboardingStepBuilder: OnboardingStepBuildable,
         listener: OnboardingStepListener,
         theme: Theme,
         index: Int) {

        self.onboardingManager = onboardingManager
        self.onboardingStepBuilder = onboardingStepBuilder
        self.listener = listener
        self.index = index

        guard let step = self.onboardingManager.getStep(index) else { fatalError("OnboardingStep index out of range") }

        self.onboardingStep = step

        super.init(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.internalView.onboardingStep = self.onboardingStep

        setThemeNavigationBar()

        internalView.button.title = self.onboardingStep.buttonTitle
        internalView.button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.internalView.playAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.internalView.stopAnimation()
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    // MARK: - Private

    private weak var listener: OnboardingStepListener?
    private lazy var internalView: OnboardingStepView = OnboardingStepView(theme: self.theme)
    private var index: Int
    private var onboardingStep: OnboardingStep
    private let onboardingManager: OnboardingManaging
    private let onboardingStepBuilder: OnboardingStepBuildable

    // MARK: - Setups

    private func setupViews() {
        setThemeNavigationBar()
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let nextIndex = self.index + 1
        if onboardingManager.onboardingSteps.count > nextIndex {
            listener?.nextStepAtIndex(nextIndex)
        } else {
            // build consent
            listener?.onboardingStepsDidComplete()
        }
    }
}

final class OnboardingStepView: View {

    private lazy var scrollView = UIScrollView()

    fileprivate lazy var button: Button = {
        return Button(theme: self.theme)
    }()

    private lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        return animationView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewsInDisplayOrder = [imageView, animationView, titleLabel, contentLabel]

    var onboardingStep: OnboardingStep? {
        didSet {
            updateView()
        }
    }

    override func build() {
        super.build()

        addSubview(scrollView)
        addSubview(button)
        viewsInDisplayOrder.forEach { scrollView.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalTo(button.snp.top).offset(-16)
        }

        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        titleLabel.snp.makeConstraints { maker in
            // no need for offset as the images include whitespace
            maker.top.greaterThanOrEqualTo(imageView.snp.bottom)
            maker.top.greaterThanOrEqualTo(animationView.snp.bottom)
            maker.leading.trailing.equalTo(self).inset(16)
        }

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(self).inset(16)
            maker.bottom.lessThanOrEqualTo(scrollView)
        }

        self.contentLabel.sizeToFit()
    }

    func updateView() {
        guard let step = self.onboardingStep else {
            return
        }

        self.titleLabel.attributedText = step.attributedTitle
        self.contentLabel.attributedText = step.attributedContent

        switch step.illustration {
        case let .image(named: name):
            imageView.image = Image.named(name)
            animationView.isHidden = true
            imageView.isHidden = false
        case let .animation(named: name, _):
            animationView.animation = LottieAnimation.named(name)
            animationView.isHidden = false
            imageView.isHidden = true
            playAnimation()
        }

        imageView.sizeToFit()

        if let width = imageView.image?.size.width,
            let height = imageView.image?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            imageView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalToSuperview()
                maker.width.equalTo(scrollView)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        animationView.sizeToFit()

        if let width = animationView.animation?.size.width,
            let height = animationView.animation?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            animationView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.centerX.equalToSuperview()
                maker.width.equalTo(scrollView)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }
    }

    func playAnimation() {
        guard animationsEnabled() else { return }

        if case let .animation(_, repeatFromFrame) = self.onboardingStep?.illustration {
            if let repeatFromFrame = repeatFromFrame {
                animationView.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce) { [weak self] completed in
                    if completed {
                        self?.loopAnimation(fromFrame: repeatFromFrame)
                    }
                }
            } else {
                animationView.loopMode = .loop
                animationView.play()
            }
        }
    }

    func stopAnimation() {
        animationView.stop()
    }

    // MARK: - Private

    private func loopAnimation(fromFrame frameNumber: Int) {
        let endFrame = animationView.animation?.endFrame ?? 0
        animationView.play(fromFrame: CGFloat(frameNumber), toFrame: endFrame, loopMode: nil) { [weak self] completed in
            if completed {
                self?.loopAnimation(fromFrame: frameNumber)
            }
        }
    }
}
