//
//  DevicePool.swift
//  
//
//  Created by Colton Schlosser on 6/19/20.
//

import Dispatch

final class DevicePool {
    private var availableDestinations: [String]
    private let internalSemaphore = DispatchSemaphore(value: 1)
    private var successful = true

    private let semaphore: DispatchSemaphore
    private let group = DispatchGroup()
    private let queue = DispatchQueue(label: "DevicePool",
                                      qos: .userInitiated,
                                      attributes: [.concurrent])

    init(destinations: [String]) {
        availableDestinations = destinations
        semaphore = DispatchSemaphore(value: destinations.count)
    }

    func useDestination(action: @escaping (String) throws -> Void) {
        semaphore.wait()
        internalSemaphore.wait()
        let destination = availableDestinations.popLast()!
        internalSemaphore.signal()
        group.enter()
        queue.async {
            let failed: Bool
            do {
                try action(destination)
                failed = false
            } catch {
                failed = true
            }
            self.internalSemaphore.wait()
            if failed {
                self.successful = false
            }
            self.availableDestinations.append(destination)
            self.internalSemaphore.signal()
            self.semaphore.signal()
            self.group.leave()
        }
    }

    func waitForFinish() -> Bool {
        group.wait()
        return successful
    }
}
