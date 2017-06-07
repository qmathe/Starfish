/**
	Copyright (C) 2017 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

open class Wave<T>: Flux<Flux<T>> {
    
    open func switchLatest() -> Flux<T> {
        let stream = Flux<T>()
        
        for event in events {
            switch event {
            case .value(let value):
                changeActiveFlux(value)
            case .error(let error):
                stream.append(Flux<T>.Event.error(error))
            case .completed:
                stream.append(Flux<T>.Event.completed)
            }
        }
        return stream
    }
    
    private func changeActiveFlux(_ flux: Flux<T>) {
        unsubscribeFromAll()
        
        flux.subscribe() { event in
            // TODO: Implement switch
            //flux.append(Flux<T>.Event.value(value))
        }
    }
    
    private func unsubscribeFromAll() {
        
    }
}
