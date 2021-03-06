//
//  UITableView+RxTests.swift
//  Rx
//
//  Created by Krunoslav Zaher on 4/8/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCTest

class UITableViewTests : RxTest {
    func testTableView_DelegateEventCompletesOnDealloc() {
        let createView: () -> UITableView = { UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1)) }

        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemSelected }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemDeselected }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemAccessoryButtonTapped }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelSelected(Int.self) }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemDeleted }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemMoved }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.itemInserted }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelSelected(Int.self) }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelDeselected(Int.self) }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.willDisplayCell }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.didEndDisplayingCell }
    }

    func testTableView_itemSelected() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil

        let subscription = tableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                resultIndexPath = indexPath
            })

        let testRow = IndexPath(row: 1, section: 0)
        tableView.delegate!.tableView!(tableView, didSelectRowAt: testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        subscription.dispose()
    }

    func testTableView_itemDeselected() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil

        let subscription = tableView.rx.itemDeselected
            .subscribe(onNext: { indexPath in
                resultIndexPath = indexPath
            })

        let testRow = IndexPath(row: 1, section: 0)
        tableView.delegate!.tableView!(tableView, didDeselectRowAt: testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        subscription.dispose()
    }

    func testTableView_itemAccessoryButtonTapped() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil

        let subscription = tableView.rx.itemAccessoryButtonTapped
            .subscribe(onNext: { indexPath in
                resultIndexPath = indexPath
            })

        let testRow = IndexPath(row: 1, section: 0)
        tableView.delegate!.tableView!(tableView, accessoryButtonTappedForRowWith: testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        subscription.dispose()
    }

    func testTableView_itemDeleted() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil

        let subscription = tableView.rx.itemDeleted
            .subscribe(onNext: { indexPath in
                resultIndexPath = indexPath
            })

        let testRow = IndexPath(row: 1, section: 0)
        tableView.dataSource!.tableView!(tableView, commit: .delete, forRowAt:  testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        subscription.dispose()
    }

    func testTableView_itemInserted() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil

        let subscription = tableView.rx.itemInserted
            .subscribe(onNext: { indexPath in
                resultIndexPath = indexPath
            })

        let testRow = IndexPath(row: 1, section: 0)
        tableView.dataSource!.tableView!(tableView, commit: .insert, forRowAt:  testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        subscription.dispose()
    }

    func testTableView_willDisplayCell() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil
        var resultCell: UITableViewCell? = nil

        let subscription = tableView.rx.willDisplayCell
            .subscribe(onNext: { (cell, indexPath) in
                resultIndexPath = indexPath
                resultCell = cell
            })

        let testRow = IndexPath(row: 1, section: 0)
        let testCell = UITableViewCell()
        tableView.delegate!.tableView!(tableView, willDisplay: testCell, forRowAt: testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        XCTAssertEqual(resultCell, testCell)
        subscription.dispose()
    }

    func testTableView_didEndDisplayingCell() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil
        var resultCell: UITableViewCell? = nil

        let subscription = tableView.rx.didEndDisplayingCell
            .subscribe(onNext: { (cell, indexPath) in
                resultIndexPath = indexPath
                resultCell = cell
            })

        let testRow = IndexPath(row: 1, section: 0)
        let testCell = UITableViewCell()
        tableView.delegate!.tableView!(tableView, didEndDisplaying: testCell, forRowAt: testRow)

        XCTAssertEqual(resultIndexPath, testRow)
        XCTAssertEqual(resultCell, testCell)
        subscription.dispose()
    }

    func testTableView_itemMoved() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        var resultIndexPath: IndexPath? = nil
        var resultIndexPath2: IndexPath? = nil

        let subscription = tableView.rx.itemMoved
            .subscribe(onNext: { (indexPath, indexPath2) in
                resultIndexPath = indexPath
                resultIndexPath2 = indexPath2
            })

        let testRow = IndexPath(row: 1, section: 0)
        let testRow2 = IndexPath(row: 1, section: 0)
        tableView.dataSource!.tableView!(tableView, moveRowAt: testRow, to: testRow2)

        XCTAssertEqual(resultIndexPath, testRow)
        XCTAssertEqual(resultIndexPath2, testRow2)
        subscription.dispose()
    }

    func testTableView_DelegateEventCompletesOnDealloc1() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            let dataSourceSubscription = items.bindTo(tableView.rx.items) { (tv, index: Int, item: Int) -> UITableViewCell in
                return UITableViewCell(style: .default, reuseIdentifier: "Identity")
            }

            return (tableView, dataSourceSubscription)
        }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelSelected(Int.self) }
    }

    func testTableView_DelegateEventCompletesOnDealloc2() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "a")
            let dataSourceSubscription = items.bindTo(tableView.rx.items(cellIdentifier: "a")) { (index: Int, item: Int, cell) in

            }

            return (tableView, dataSourceSubscription)
        }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelSelected(Int.self) }
    }

    func testTableView_DelegateEventCompletesOnDealloc2_cellType() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "a")
            let dataSourceSubscription = items.bindTo(tableView.rx.items(cellIdentifier: "a", cellType: UITableViewCell.self)) { (index: Int, item: Int, cell) in

            }

            return (tableView, dataSourceSubscription)
        }
        ensureEventDeallocated(createView) { (view: UITableView) in view.rx.modelSelected(Int.self) }
    }

    func testTableView_ModelSelected_rx_itemsWithCellFactory() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])
        
        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            let dataSourceSubscription = items.bindTo(tableView.rx.items) { (tv, index: Int, item: Int) -> UITableViewCell in
                return UITableViewCell(style: .default, reuseIdentifier: "Identity")
            }
            
            return (tableView, dataSourceSubscription)
        }
        
        let (tableView, dataSourceSubscription) = createView()
        
        var selectedItem: Int? = nil
        
        let s = tableView.rx.modelSelected(Int.self)
            .subscribe(onNext: { item in
                selectedItem = item
            })
        
        tableView.delegate!.tableView!(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        
        XCTAssertEqual(selectedItem, 2)
        
        dataSourceSubscription.dispose()
        s.dispose()
    }

    func testTableView_ModelSelected_itemsWithCellIdentifier() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "a")
            let dataSourceSubscription = items.bindTo(tableView.rx.items(cellIdentifier: "a")) { (index: Int, item: Int, cell) in

            }

            return (tableView, dataSourceSubscription)
        }

        let (tableView, dataSourceSubscription) = createView()

        var selectedItem: Int? = nil

        let s = tableView.rx.modelSelected(Int.self)
            .subscribe(onNext: { item in
                selectedItem = item
            })

        tableView.delegate!.tableView!(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(selectedItem, 2)

        dataSourceSubscription.dispose()
        s.dispose()
    }

    func testTableView_ModelDeselected_rx_itemsWithCellFactory() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            let dataSourceSubscription = items.bindTo(tableView.rx.items) { (tv, index: Int, item: Int) -> UITableViewCell in
                return UITableViewCell(style: .default, reuseIdentifier: "Identity")
            }

            return (tableView, dataSourceSubscription)
        }

        let (tableView, dataSourceSubscription) = createView()

        var selectedItem: Int? = nil

        let s = tableView.rx.modelDeselected(Int.self)
            .subscribe(onNext: { item in
                selectedItem = item
            })

        tableView.delegate!.tableView!(tableView, didDeselectRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(selectedItem, 2)

        dataSourceSubscription.dispose()
        s.dispose()
    }

    func testTableView_ModelDeselected_itemsWithCellIdentifier() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "a")
            let dataSourceSubscription = items.bindTo(tableView.rx.items(cellIdentifier: "a")) { (index: Int, item: Int, cell) in

            }

            return (tableView, dataSourceSubscription)
        }

        let (tableView, dataSourceSubscription) = createView()

        var selectedItem: Int? = nil

        let s = tableView.rx.modelDeselected(Int.self)
            .subscribe(onNext: { item in
                selectedItem = item
            })

        tableView.delegate!.tableView!(tableView, didDeselectRowAt: IndexPath(row: 1, section: 0))
        
        XCTAssertEqual(selectedItem, 2)
        
        dataSourceSubscription.dispose()
        s.dispose()
    }

    func testTableView_modelAtIndexPath_normal() {
        let items: Observable<[Int]> = Observable.just([1, 2, 3])

        let createView: () -> (UITableView, Disposable) = {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(NSClassFromString("UITableViewCell"), forCellReuseIdentifier: "a")
            let dataSource = SectionedViewDataSourceMock()
            let dataSourceSubscription = items.bindTo(tableView.rx.items(dataSource: dataSource))

            return (tableView, dataSourceSubscription)
        }

        let (tableView, dataSourceSubscription) = createView()

        let model: Int = try! tableView.rx.model(IndexPath(item: 1, section: 0))

        XCTAssertEqual(model, 2)
        
        dataSourceSubscription.dispose()
    }
}

extension UITableViewTests {
    func testDataSourceIsBeingRetainedUntilDispose() {

        var dataSourceDeallocated = false

        var outerTableView: UITableView? = nil
        var dataSourceSubscription: Disposable!
        autoreleasepool {
            let items: Observable<[Int]> = Observable.just([1, 2, 3])
            let dataSource = SectionedViewDataSourceMock()
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            outerTableView = tableView
            dataSourceSubscription = items.bindTo(tableView.rx.items(dataSource: dataSource))

            _ = dataSource.rx.deallocated.subscribe(onNext: { _ in
                dataSourceDeallocated = true
            })
        }

        XCTAssert(dataSourceDeallocated == false)
        autoreleasepool { dataSourceSubscription.dispose() }
        XCTAssert(dataSourceDeallocated == true)
    }

    func testDataSourceIsBeingRetainedUntilTableViewDealloc() {

        var dataSourceDeallocated = false

        autoreleasepool {
            let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "a")

            let items: Observable<[Int]> = Observable.just([1, 2, 3])
            let dataSource = SectionedViewDataSourceMock()
            _ = items.bindTo(tableView.rx.items(dataSource: dataSource))

            _ = dataSource.rx.deallocated.subscribe(onNext: { _ in
                dataSourceDeallocated = true
            })

            XCTAssert(dataSourceDeallocated == false)
        }
        XCTAssert(dataSourceDeallocated == true)
    }

    func testSetDataSourceUsesWeakReference() {

        var dataSourceDeallocated = false

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "a")

        autoreleasepool {
            let dataSource = SectionedViewDataSourceMock()
            _ = tableView.rx.setDataSource(dataSource)

            _ = dataSource.rx.deallocated.subscribe(onNext: { _ in
                dataSourceDeallocated = true
            })

            XCTAssert(dataSourceDeallocated == false)
        }
        XCTAssert(dataSourceDeallocated == true)
    }
}
