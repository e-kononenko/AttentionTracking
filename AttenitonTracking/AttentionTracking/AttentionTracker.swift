//
//  AttentionTracker.swift
//  AttenitonTracking
//
//  Created by Evgenii Kononenko on 04.07.25.
//

import Combine
import Foundation

final class AttentionTracker {
    struct OutputModel {
        let id: Int
        let viewingTime: TimeInterval // how long the id was visible
    }
    
    struct InputModel {
        let idFrames: [Int: CGRect]
        let parentFrame: CGRect
        let date: Date = .init()
    }

    private typealias Batch = (ids: Set<Int>, date: Date)   // ids visible at a specific time
    private typealias HelperDict = [Int: Date]  // id and its first time appearance

    private enum Constants {
        static let collectTime = 10.0
        static let minimumViewingTime = 1.0
        static let throttleTime = 0.3
    }

    private let queue = DispatchQueue(label: "attention tracking")  // serial queue where we will process our data
    private let inputSubject: PassthroughSubject<InputModel, Never> = .init()
    private let outputSubject: PassthroughSubject<[OutputModel], Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Private
    private func setupSubscriptions() {
        var helperDict: HelperDict = .init()
        inputSubject
            .throttle(  // take only one InputModel per throttleTime to not process too many of them
                for: .seconds(Constants.throttleTime),
                scheduler: queue,
                latest: true
            )
            .compactMap { input -> [OutputModel]? in
                Self.convertInputToOutputModels(input, helperDict: &helperDict)
            }
            .collect(.byTime(queue, .seconds(Constants.collectTime))) // collecting outputs to send them in batches
            .map { outputs in
                // since we receive array of arrays after collecting, we flatten it
                outputs.flatMap { $0 }
            }
            .receive(on: DispatchQueue.main)
            .subscribe(outputSubject)   // send the result into outputSubject
            .store(in: &cancellables)
    }
    
    private static func convertInputToOutputModels(_ input: InputModel, helperDict: inout HelperDict) -> [OutputModel]? {
        guard let batch = makeBatchOfVisibleIds(fromInput: input) else {
            return nil
        }
        var outputModels: [OutputModel] = .init()
        processBatch(
            batch,
            outputs: &outputModels,
            helperDict: &helperDict
        )
        
        return outputModels.isEmpty ? nil : outputModels
    }
    
    private static func makeBatchOfVisibleIds(fromInput input: InputModel) -> Batch? {
        // check only ids that are visible within their parent's bounds
        let visibleIds = input.idFrames
            .compactMap { (id, frame) in
                let isVisible = VisibilityHelper.isItemFrameVisible(
                    frame,
                    inParentFrame: input.parentFrame
                )
                
                return isVisible ? id : nil
            }
        return visibleIds.isEmpty ? nil : (Set(visibleIds), input.date)
    }
    
    private static func processBatch(
        _ batch: Batch,
        outputs: inout [OutputModel],
        helperDict: inout HelperDict
    ) {
        // check ids that disappeared from the helper dict
        let disappearedIds = helperDict.keys.filter {
            !batch.ids.contains($0)
        }
        
        // if we found something that disappeared - create an Output and remove from helperDict
        for disappearedId in disappearedIds {
            guard let dateOfAppearance = helperDict[disappearedId] else {
                continue
            }
            
            //calculate viewingTime as the difference between first and last dates
            let viewingTime = batch.date.timeIntervalSince(dateOfAppearance)
            
            if viewingTime >= Constants.minimumViewingTime {
                let outputItem: OutputModel = .init(
                    id: disappearedId,
                    viewingTime: viewingTime
                )
                outputs.append(outputItem)
                helperDict.removeValue(forKey: disappearedId)
            }
        }
        
        // processing batch ids and see what has just appeared
        for id in batch.ids {
            //if we haven't met this id before, we add it to helperDict
            if helperDict[id] == nil {
                helperDict[id] = batch.date
            }
        }
    }
    
    func track(input: InputModel) {
        inputSubject.send(input)
    }
    
    var outputPublisher: AnyPublisher<[OutputModel], Never> {
        outputSubject
            .eraseToAnyPublisher()
    }
    
    var outputSequence: any AsyncSequence<[OutputModel], Never> {
        outputSubject.values
    }
}
