//
//  GoogleStorage.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 1/30/17.
//  Copyright © 2017 antonybrro. All rights reserved.
//

import Foundation

class GoogleStorage : Storage {
    
    func load() -> [Note] {
        return [Note]()
    }
    
    func add(_ note: Note) {
        
    }
    
    func update(index : Int, note : Note) {
        print("Google update")
    }
    
    func delete(index : Int) {
        print("Google delete")
    }
}
