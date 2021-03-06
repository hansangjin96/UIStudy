//
//  HVBottomSheetVC.swift
//  HVBottomSheet
//
//  Created by 한상진 on 2021/07/09.
//

import UIKit

open class HVBottomSheetVC: UIViewController {
    // MARK: Contant
    
    private enum SheetViewState {
        case normal
        case expanded
        case dismiss
    }
    
    public enum HeightRatio {
        case topQuarter
        case half
        case bottomQuarter
    }
    
    // MARK: Property
    
    private var heightRatio: HeightRatio?
    private var cardViewHeightConstant: CGFloat?
    private var cardViewHeightConstraint: NSLayoutConstraint?
    private var currentHeight: CGFloat?
    
    private let defaultSafeHeight: CGFloat = 40
    private let hideDragView: Bool
    
    // MARK: UI Property
    
    private lazy var dragGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(
        target: self,
        action: #selector(dragIndicatorMoved(_:))
    )
    
    private lazy var dragView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = hideDragView
        view.addGestureRecognizer(self.dragGesture)
        return view
    }()
    
    private lazy var dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        view.alpha = 0
        view.isHidden = hideDragView
        return view
    }()
    
    private lazy var dimmerViewTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(self.hideCardViewAndDismiss)
    )
    
    private lazy var dimmerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.backgroundColor = .systemGray.withAlphaComponent(0.7)
        view.addGestureRecognizer(self.dimmerViewTapGesture)
        return view
    }()
        
    public let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: Init
    
    public init(
        heightRatio: HeightRatio? = nil,
        cardViewHeightConstant: CGFloat? = nil,
        hideDragView: Bool = false
    ) {
        self.heightRatio = heightRatio
        self.cardViewHeightConstant = cardViewHeightConstant
        self.hideDragView = hideDragView
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(type(of: self)): \(#function)")
    }
    
    // MARK: LifeCycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showBottomSheet()
    }
    
    // MARK: UI
    
    open func setupUI() {
        
        view.backgroundColor = .clear
        setupDimmerView()
        setupCardView()
        setupDragViews()
    }
    
    private func setupDimmerView() {
        view.addSubview(dimmerView)
        NSLayoutConstraint.activate([
            dimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmerView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
    
    private func setupCardView() {
        let defaultHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 0)
        view.addSubview(cardView)
        
        cardViewHeightConstraint = defaultHeightConstraint
        
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardViewHeightConstraint ?? defaultHeightConstraint
        ])
    }
    
    private func setupDragViews() {
        view.addSubview(dragView)
        NSLayoutConstraint.activate([
            dragView.bottomAnchor.constraint(equalTo: cardView.topAnchor),
            dragView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dragView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            dragView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        dragView.addSubview(dragIndicatorView)
        NSLayoutConstraint.activate([
            dragIndicatorView.widthAnchor.constraint(equalToConstant: 50),
            dragIndicatorView.heightAnchor.constraint(equalToConstant: dragIndicatorView.layer.cornerRadius * 2),
            dragIndicatorView.centerXAnchor.constraint(equalTo: dragView.centerXAnchor),
            dragIndicatorView.bottomAnchor.constraint(equalTo: dragView.bottomAnchor, constant: -10),
        ])
    }
    
    private func showBottomSheet() {
        /// 외부에서 높이를 지정해주지 않았을 경우 기본값은 화면의 1/3
        var safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height / 3
        
        if let heightRatio = self.heightRatio {
            switch heightRatio {
            case .topQuarter:
                safeAreaHeight = view.frame.height / 4 * 3
            case .half:
                safeAreaHeight = view.frame.height / 2
            case .bottomQuarter:
                safeAreaHeight = view.frame.height / 4
            }
        }
        
        if let cardViewHeightConstant = self.cardViewHeightConstant {
            safeAreaHeight = cardViewHeightConstant
        }

        let bottomPadding = view.safeAreaInsets.bottom
        cardViewHeightConstraint?.constant = safeAreaHeight + bottomPadding
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.dragIndicatorView.alpha = 1
            self.dimmerView.alpha = 0.7
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: Method

extension HVBottomSheetVC {
    private func changeState(at state: HVBottomSheetVC.SheetViewState = .normal) {
        switch state {
        case .normal:
            break
            
        case .expanded:
            let safeLayoutHeight = view.safeAreaLayoutGuide.layoutFrame.height
            let dragHeight = dragIndicatorView.frame.height
            let fullHeight = safeLayoutHeight - dragHeight - defaultSafeHeight
            self.cardViewHeightConstraint?.constant = fullHeight
            
        case .dismiss:
            hideCardViewAndDismiss()
        }
    }
    
    private func dimAlphaWithHeightConstraint(value: CGFloat) -> CGFloat {
        let fullDimAlpha: CGFloat = 0.7
        
        let resultAlpha = fullDimAlpha
        return resultAlpha
    }
    
    @objc private func dragIndicatorMoved(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: view)
        
        switch recognizer.state {
        /// translation의 시작 위치를 기록
        case .began:
            self.currentHeight = self.cardViewHeightConstraint?.constant
            
        /// cardView의 height constant를 translation에 맞게 변경
        case .changed:
            guard let currentHeight = self.currentHeight else { break }
            let changedHeight = currentHeight - translation.y
            let dragHeight = dragIndicatorView.frame.height
            guard changedHeight < view.frame.height - defaultSafeHeight - dragHeight else { break }
            self.cardViewHeightConstraint?.constant = changedHeight
            
        /// 화면의 상단 1/4에 위치하거나, 드래그 속도가 위쪽으로 일정 수치 이상이면 state를 .expanded로 변경
        /// 화면의 하단 1/4에 위치하거나, 드래그 속도가 아래쪽으로 일정 수치 이상이면 state를 .dismiss로 변경
        case .ended:
            if velocity.y > 1500 {
                self.changeState(at: .dismiss)
            } else if velocity.y < -1500 {
                self.changeState(at: .expanded)
            }
        default:
            break
        }
    }
    
    @objc public func hideCardViewAndDismiss() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.cardViewHeightConstraint?.constant = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: Preview

#if canImport(SwiftUI) && DEBUG
import SwiftUI
@available(iOS 13.0, *)
struct VCRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HVBottomSheetVC {
        HVBottomSheetVC()
    }
    func updateUIViewController(_ uiViewController: HVBottomSheetVC, context: Context) {
    }
}
@available(iOS 13.0, *)
struct VCPreview: PreviewProvider {
    typealias Previews = VCRepresentable
    static var previews: Previews {
        return VCRepresentable()
    }
}
#endif
