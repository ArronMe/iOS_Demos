//
//  CarouselView.swift
//  CycleScrollView
//
//  Created by wuweixin on 2019/6/11.
//  Copyright © 2019 cn.wessonwu. All rights reserved.
//

import UIKit

public protocol CarouselDataSource: AnyObject {
    func numberOfItems(in carouselView: CarouselView) -> Int
    func carouselView(_ carouselView: CarouselView, cellForItemAt index: Int) -> UICollectionViewCell
}

public class CarouselView: UIView {
    public let collectionView: UICollectionView
    private var autoScrollTimer: Timer?
    
    /// 自动滚动时间间隔
    public var timeIntervalForAutoScroll: TimeInterval = 3
    
    public weak var dataSource: CarouselDataSource? {
        didSet {
            collectionView.reloadData()
            scrollToItem(at: 0, animated: false)
        }
    }
    
    public override init(frame: CGRect) {
        collectionView = UICollectionView(frame: frame, collectionViewLayout: CarouselFlowLayout())
        super.init(frame: frame)
        collectionView.backgroundColor = nil
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setupAutoLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupAutoLayout() {
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(collectionView)
    }
    
    public final func reloadData() {
        self.collectionView.reloadData()
    }
    
    public final func scrollToItem(at index: Int, animated: Bool) {
        let listView = self.collectionView
        guard listView.numberOfSections > 0
            && index < listView.numberOfItems(inSection: 0) else {
            return
        }
        let indexPath = IndexPath(item: index, section: listView.numberOfSections / 2)
        listView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
}

/// 重用支持
extension CarouselView {
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier reuseIdentifier: String) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: reuseIdentifier)
    }
    public func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, for index: Int) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: IndexPath(item: index, section: 0))
    }
}

/// 自动滚动支持
extension CarouselView {
    /// 开启自动滚动
    public final func startAutoScroller() {
        guard self.autoScrollTimer == nil else {
            return
        }
        let timeInterval = self.timeIntervalForAutoScroll
        let timer = Timer(timeInterval: timeInterval,
                          target: self,
                          selector: #selector(autoScrollTick),
                          userInfo: nil,
                          repeats: true)
        self.autoScrollTimer = timer
        timer.fireDate = Date(timeIntervalSinceNow: timeInterval)
        RunLoop.main.add(timer, forMode: .common)
    }
    
    /// 停止自动滚动 (必须调用，否则内存泄漏)
    public final func stopAutoScroller() {
        self.autoScrollTimer?.invalidate()
        self.autoScrollTimer = nil
    }
    
    private func pauseAutoScroller() {
        self.autoScrollTimer?.fireDate = .distantFuture
    }
    
    private func resumeAutoScroller() {
        guard let timer = self.autoScrollTimer else {
            return
        }
        timer.fireDate = Date(timeIntervalSinceNow: timer.timeInterval)
    }
    
    @objc
    private func autoScrollTick() {
        let listView = self.collectionView
        let bounds = listView.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        guard let indexPath = listView.indexPathForItem(at: center) else {
            return
        }
        
        let numberOfSections = listView.numberOfSections
        let numberOfItems = listView.numberOfItems(inSection: indexPath.section)
        let section = (indexPath.section + (indexPath.item + 1) / numberOfItems) % numberOfSections
        let item = (indexPath.item + 1) % numberOfItems
        
        listView.scrollToItem(at: IndexPath(item: item, section: section),
                              at: .centeredHorizontally,
                              animated: true)
    }
}


extension CarouselView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 20
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfItems(in: self) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let ds = self.dataSource else {
            fatalError("CarouselView's dataSource can't be nil!")
        }
        return ds.carouselView(self, cellForItemAt: indexPath.item)
    }
}

extension CarouselView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return .zero
        }
        if section > 0 {
            return UIEdgeInsets(top: 0, left: flowLayout.minimumLineSpacing, bottom: 0, right: 0)
        }
        return .zero
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let bounds = scrollView.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        guard let indexPath = collectionView.indexPathForItem(at: center) else {
            return
        }
        scrollToItem(at: indexPath.item, animated: false)
        resumeAutoScroller()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
    }
    
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseAutoScroller()
    }
}
