//
//  DelegateProxyTest.swift
//  RxTests
//
//  Created by Krunoslav Zaher on 7/5/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RxCocoa
#if os(iOS)
import UIKit
#endif

// MARK: Protocols

@objc protocol TestDelegateProtocol {
    @objc optional func testEventHappened(_ value: Int)
}

@objc class MockTestDelegateProtocol
    : NSObject
    , TestDelegateProtocol
{
    var numbers = [Int]()

    func testEventHappened(_ value: Int) {
        numbers.append(value)
    }
}

protocol TestDelegateControl: NSObjectProtocol {
    func doThatTest(_ value: Int)

    var test: Observable<Int> { get }

    func setMineForwardDelegate(_ testDelegate: TestDelegateProtocol) -> Disposable
}

// MARK: Tests

class DelegateProxyTest : RxTest {
    func test_OnInstallDelegateIsRetained() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        let _ = view.rx.proxy
        
        XCTAssertEqual(mock.messages, [])
        XCTAssertTrue(view.rx.proxy.forwardToDelegate() === mock)
    }
    
    func test_forwardsUnobservedMethods() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        let _ = view.rx.proxy
        
        view.delegate?.threeDView?(view, didLearnSomething: "Psssst ...")
        
        XCTAssertEqual(mock.messages, ["didLearnSomething"])
    }
    
    func test_forwardsObservedMethods() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        var observedFeedRequest = false
        
        let d = view.rx.proxy.observe(#selector(ThreeDSectionedViewProtocol.threeDView(_:didLearnSomething:)))
            .subscribe(onNext: { n in
                observedFeedRequest = true
            })
        defer {
            d.dispose()
        }

        XCTAssertTrue(!observedFeedRequest)
        view.delegate?.threeDView?(view, didLearnSomething: "Psssst ...")
        XCTAssertTrue(observedFeedRequest)
        
        XCTAssertEqual(mock.messages, ["didLearnSomething"])
    }
    
    func test_forwardsObserverDispose() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        var nMessages = 0
        
        let d = view.rx.proxy.observe(#selector(ThreeDSectionedViewProtocol.threeDView(_:didLearnSomething:)))
            .subscribe(onNext: { n in
                nMessages += 1
            })
        
        XCTAssertTrue(nMessages == 0)
        view.delegate?.threeDView?(view, didLearnSomething: "Psssst ...")
        XCTAssertTrue(nMessages == 1)

        d.dispose()

        view.delegate?.threeDView?(view, didLearnSomething: "Psssst ...")
        XCTAssertTrue(nMessages == 1)
    }
    
    func test_forwardsUnobservableMethods() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        view.delegate?.threeDView?(view, didLearnSomething: "Psssst ...")
        
        XCTAssertEqual(mock.messages, ["didLearnSomething"])
    }
    
    func test_observesUnimplementedOptionalMethods() {
        let view = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
       
        XCTAssertTrue(!mock.responds(to: NSSelectorFromString("threeDView(threeDView:didGetXXX:")))
        
        let sentArgument = IndexPath(index: 0)
        
        var receivedArgument: IndexPath? = nil
        
        let d = view.rx.proxy.observe(#selector(ThreeDSectionedViewProtocol.threeDView(_:didGetXXX:)))
            .subscribe(onNext: { n in
                let ip = n[1] as! IndexPath
                receivedArgument = ip
            })
        defer {
            d.dispose()
        }

        view.delegate?.threeDView?(view, didGetXXX: sentArgument)
        XCTAssertTrue(receivedArgument == sentArgument)
        
        XCTAssertEqual(mock.messages, [])
    }
    
    func test_delegateProxyCompletesOnDealloc() {
        var view: ThreeDSectionedView! = ThreeDSectionedView()
        let mock = MockThreeDSectionedViewProtocol()
        
        view.delegate = mock
        
        var completed = false
        
        autoreleasepool {
            XCTAssertTrue(!mock.responds(to: NSSelectorFromString("threeDView:threeDView:didGetXXX:")))
            
            let sentArgument = IndexPath(index: 0)
            
            _ = view
                .rx.proxy
                .observe(#selector(ThreeDSectionedViewProtocol.threeDView(_:didGetXXX:)))
                .subscribe(onCompleted: {
                    completed = true
                })
            
            view.delegate?.threeDView?(view, didGetXXX: sentArgument)
        }
        XCTAssertTrue(!completed)
        view = nil
        XCTAssertTrue(completed)
    }
}

#if os(iOS)
extension DelegateProxyTest {
    func test_DelegateProxyHierarchyWorks() {
        let tableView = UITableView()
        _ = tableView.rx.delegate.observe(#selector(UIScrollViewDelegate.scrollViewWillBeginDragging(_:)))
    }
}
#endif

// MARK: Testing extensions

extension DelegateProxyTest {
    func performDelegateTest<Control: TestDelegateControl>( _ createControl: @autoclosure() -> Control) {
        var control: TestDelegateControl!

        autoreleasepool {
            control = createControl()
        }

        var receivedValue: Int!
        var completed = false
        var deallocated = false

        autoreleasepool {
            _ = control.test.subscribe(onNext: { value in
                receivedValue = value
            }, onCompleted: {
                completed = true
            })

            _ = (control as! NSObject).rx.deallocated.subscribe(onNext: { _ in
                deallocated = true
            })
        }

        XCTAssertTrue(receivedValue == nil)
        autoreleasepool {
            control.doThatTest(382763)
        }
        XCTAssertEqual(receivedValue, 382763)

        autoreleasepool {
            let mine = MockTestDelegateProtocol()
            let disposable = control.setMineForwardDelegate(mine)

            XCTAssertEqual(mine.numbers, [])
            control.doThatTest(2)
            XCTAssertEqual(mine.numbers, [2])
            disposable.dispose()
            control.doThatTest(3)
            XCTAssertEqual(mine.numbers, [2])
        }

        XCTAssertFalse(deallocated)
        XCTAssertFalse(completed)
        autoreleasepool {
            control = nil
        }
        XCTAssertTrue(deallocated)
        XCTAssertTrue(completed)
    }
}

// MARK: Mocks

// test case {

class Food: NSObject {
}

@objc protocol ThreeDSectionedViewProtocol {
    func threeDView(_ threeDView: ThreeDSectionedView, listenToMeee: IndexPath)
    func threeDView(_ threeDView: ThreeDSectionedView, feedMe: IndexPath)
    func threeDView(_ threeDView: ThreeDSectionedView, howTallAmI: IndexPath) -> CGFloat
    
    @objc optional func threeDView(_ threeDView: ThreeDSectionedView, didGetXXX: IndexPath)
    @objc optional func threeDView(_ threeDView: ThreeDSectionedView, didLearnSomething: String)
    @objc optional func threeDView(_ threeDView: ThreeDSectionedView, didFallAsleep: IndexPath)
    @objc optional func threeDView(_ threeDView: ThreeDSectionedView, getMeSomeFood: IndexPath) -> Food
}

class ThreeDSectionedView: NSObject {
    var delegate: ThreeDSectionedViewProtocol?
}

// }

// integration {

class ThreeDSectionedViewDelegateProxy : DelegateProxy
                                       , ThreeDSectionedViewProtocol
                                       , DelegateProxyType {
    required init(parentObject: AnyObject) {
        super.init(parentObject: parentObject)
    }
    
    // delegate
    
    func threeDView(_ threeDView: ThreeDSectionedView, listenToMeee: IndexPath) {
        
    }
    
    func threeDView(_ threeDView: ThreeDSectionedView, feedMe: IndexPath) {
        
    }
    
    func threeDView(_ threeDView: ThreeDSectionedView, howTallAmI: IndexPath) -> CGFloat {
        return 1.1
    }
    
    // integration
    
    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let view = object as! ThreeDSectionedView
        view.delegate = delegate as? ThreeDSectionedViewProtocol
    }
    
    class func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let view = object as! ThreeDSectionedView
        return view.delegate
    }
}

extension Reactive where Base: ThreeDSectionedView {
    var proxy: DelegateProxy {
        return ThreeDSectionedViewDelegateProxy.proxyForObject(base)
    }
}

// }

class MockThreeDSectionedViewProtocol : NSObject, ThreeDSectionedViewProtocol {
    
    var messages: [String] = []
    
    func threeDView(_ threeDView: ThreeDSectionedView, listenToMeee: IndexPath) {
        messages.append("listenToMeee")
    }
    
    func threeDView(_ threeDView: ThreeDSectionedView, feedMe: IndexPath) {
        messages.append("feedMe")
    }
    
    func threeDView(_ threeDView: ThreeDSectionedView, howTallAmI: IndexPath) -> CGFloat {
        messages.append("howTallAmI")
        return 3
    }
    
    /*func threeDView(threeDView: ThreeDSectionedView, didGetXXX: IndexPath) {
        messages.append("didGetXXX")
    }*/
    
    func threeDView(_ threeDView: ThreeDSectionedView, didLearnSomething: String) {
        messages.append("didLearnSomething")
    }
    
    //optional func threeDView(threeDView: ThreeDSectionedView, didFallAsleep: IndexPath)
    func threeDView(_ threeDView: ThreeDSectionedView, getMeSomeFood: IndexPath) -> Food {
        messages.append("getMeSomeFood")
        return Food()
    }
}

#if os(OSX)
extension MockTestDelegateProtocol
    : NSTextFieldDelegate {

    }
#endif

#if os(iOS) || os(tvOS)
extension MockTestDelegateProtocol
    : UICollectionViewDataSource
    , UIScrollViewDelegate
    , UITableViewDataSource
    , UITableViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatalError()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError()
    }
}
#endif
