/**
	Copyright (C) 2017 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

open class Wave<T>: Flux<Flux<T>> {

	private var subscribedFluxes = [Flux<T>]()

	// MARK: - Combining Fluxes
	
	open func merge() -> Flux<T> {
        let stream = Flux<T>()
		
		_ = subscribe() { event in
            switch event {
            case .value(let value):
                self.subscribe(to: value, redirectingEventsTo: stream)
            case .error(let error):
                stream.append(Flux<T>.Event.error(error))
            case .completed:
                stream.append(Flux<T>.Event.completed)
            }
        }
        return stream
    }
    
    open func switchLatest() -> Flux<T> {
        let stream = Flux<T>()
		
		_ = subscribe() { event in
            switch event {
            case .value(let value):
				self.unsubscribeFromAll()
				self.subscribe(to: value, redirectingEventsTo: stream)
            case .error(let error):
                stream.append(Flux<T>.Event.error(error))
            case .completed:
                stream.append(Flux<T>.Event.completed)
            }
        }
        return stream
    }
	
	// MARK: - Redirecting Fluxes
	    
    private func unsubscribeFromAll() {
        subscribedFluxes.forEach { $0.unsubscribe(self) }
		subscribedFluxes.removeAll()
    }
	
	private func subscribe(to inputFlux: Flux<T>, redirectingEventsTo outputFlux: Flux<T>) {
		subscribedFluxes += [inputFlux]
        _ = inputFlux.subscribe(self) { event in
			outputFlux.append(event)
        }
	}
}
