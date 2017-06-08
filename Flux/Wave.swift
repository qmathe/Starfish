/**
	Copyright (C) 2017 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

open class Wave<T>: Flux<Flux<T>> {

	private var subscribedFluxes = [Flux<T>]()
    
    open func switchLatest() -> Flux<T> {
        let stream = Flux<T>()
		
		_ = subscribe() { event in
            switch event {
            case .value(let value):
                self.redirectFlux(value, to: stream)
            case .error(let error):
                stream.append(Flux<T>.Event.error(error))
            case .completed:
                stream.append(Flux<T>.Event.completed)
            }
        }
        return stream
    }
    
    private func redirectFlux(_ inputFlux: Flux<T>, to outputFlux: Flux<T>) {
		unsubscribeFromAll()
        subscribedFluxes = [inputFlux]
        
        _ = inputFlux.subscribe() { event in
			outputFlux.append(event)
        }
    }
	
	    
    private func unsubscribeFromAll() {
        subscribedFluxes.forEach { $0.unsubscribe(self) }
    }
}
